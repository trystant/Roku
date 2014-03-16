package com.roku.dvp;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpException;
import org.apache.http.HttpRequest;
import org.apache.http.HttpStatus;
import org.apache.http.HttpVersion;
import org.apache.http.RequestLine;
import org.apache.http.entity.InputStreamEntity;
import org.apache.http.impl.DefaultHttpServerConnection;
import org.apache.http.impl.EnglishReasonPhraseCatalog;
import org.apache.http.message.BasicHeader;
import org.apache.http.message.BasicHttpResponse;
import org.apache.http.message.BasicStatusLine;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.CoreConnectionPNames;
import org.apache.http.params.HttpParams;

import android.content.ContentResolver;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.net.Uri;
import android.util.Log;

// see for sample code:
// https://svn.apache.org/repos/asf/httpcomponents/httpcore/tags/4.0/module-main/src/examples/org/apache/http/examples/ElementalReverseProxy.java

public final class HttpServer implements Runnable {
  private static final String LOG_PREFIX = "HttpServer";
  private static final int PORTSET[] = {
    0xcbda, 0x823d, 0xfcc5, 0x60a1, 0xd957,
  };

  private static final int FLAGS =
    Pattern.CASE_INSENSITIVE | Pattern.MULTILINE;
  private static final Pattern range_request_header_pattern =
    Pattern.compile("^bytes=(\\d*)-(\\d*)$", FLAGS);

  HttpServer(Context context) {
    mContentResolver = context.getContentResolver();

    // try several different ports before giving up
    for (int i = 0; i < PORTSET.length; ++i) {
      try {
        mPort = PORTSET[i];
        mServerSocket = new ServerSocket(mPort);
        mServerSocket.setReuseAddress(true);
        break;
      } catch (IOException e) {
        // try again with another port
        e.printStackTrace();
      }
    }
    Log.i(LOG_PREFIX, "Listening for connections on port "
        + mServerSocket.getLocalPort());

    mHttpParams = new BasicHttpParams();
    mHttpParams
        .setIntParameter(CoreConnectionPNames.SO_TIMEOUT, 5000)
        .setIntParameter(CoreConnectionPNames.SOCKET_BUFFER_SIZE, 64 * 1024)
        ;
/*
    BasicHttpProcessor processor = new BasicHttpProcessor();
    processor.addInterceptor(new ResponseContent());
    processor.addInterceptor(new ResponseConnControl());
    processor.addInterceptor(new RequestContent());
    processor.addInterceptor(new RequestTargetHost());
    processor.addInterceptor(new RequestConnControl());

    // Set up incoming request handler
    //HttpRequestHandlerRegistry registry = new HttpRequestHandlerRegistry();
    //registry.register("*", new ProxyHandler())

    mHttpService = new HttpService(processor,
        new DefaultConnectionReuseStrategy(),
        new DefaultHttpResponseFactory());
    mHttpService.setParams(mHttpParams);
*/
    mThread = new Thread(this);
    mThread.start();
  }

  public void destroy() {
    if (mServerSocket != null) {
      try {
        mServerSocket.close();
        mServerSocket = null;
        mThread.join();
        mThread = null;
      } catch (IOException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      } catch (InterruptedException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    }
  }

  public int getPort() {
    return mPort;
  }

  public void run() {
    try {
      while (true) {
        Socket insocket = null;
        DefaultHttpServerConnection conn = null;
        int status = 0;
        HttpEntity entity = null;
        Header[] headers = null;
        try {
          insocket = mServerSocket.accept();
          conn = new DefaultHttpServerConnection();
          conn.bind(insocket, mHttpParams);

          String uriString = null;
          HttpRequest request = conn.receiveRequestHeader();
          if (request != null) {
            RequestLine line = request.getRequestLine();
            if (line != null && line.getMethod().equals("GET")) {
              uriString = Uri.decode(line.getUri());
              Log.i(LOG_PREFIX, uriString);
            }
          }

          if (uriString != null) {
            Uri uri = Uri.parse(uriString.substring(1));
            AssetFileDescriptor fd =
                mContentResolver.openAssetFileDescriptor(uri, "r");

            long range_begin = 0;
            long range_end = fd.getLength();
            Header rangeHeader = request.getFirstHeader("Range");
            if (rangeHeader == null) {
              // populate a Content-Length header:
              headers = new Header[]{
                  new BasicHeader("Content-Length", Long.toString(range_end))
              };
              status = HttpStatus.SC_OK;
            } else {
              String bytes = rangeHeader.getValue();
              Matcher m = range_request_header_pattern.matcher(bytes);
              if (m.find()) {
                if (m.group(1).length() > 0)
                  range_begin = Math.max(Long.parseLong(m.group(1)), range_begin);
                if (m.group(2).length() > 0)
                  range_end = Math.min(Long.parseLong(m.group(2)), range_end - 1);
              }
              // populate Content-Range and Content-Length headers:
              headers = new Header[]{
                  new BasicHeader("Content-Range",
                      range_begin + "-" + range_end + "/" + fd.getLength()),
                  new BasicHeader("Content-Length",
                      Long.toString(range_end - range_begin + 1))
              };
              status = HttpStatus.SC_PARTIAL_CONTENT;
            }
            FileInputStream fis = fd.createInputStream();
            fis.skip(range_begin);
            entity = new InputStreamEntity(fis, range_end - range_begin + 1);
          }
        } catch (FileNotFoundException e) {
          status = HttpStatus.SC_NOT_FOUND;
        } catch (IllegalStateException e) {
          status = HttpStatus.SC_NOT_FOUND;
        } catch (SocketTimeoutException e) {
          // request timed out
        } catch (HttpException e) {
          status = HttpStatus.SC_BAD_REQUEST;
        }

        if (status != 0) { // send a response
          BasicStatusLine line = new BasicStatusLine(
              HttpVersion.HTTP_1_1,
              status,
              EnglishReasonPhraseCatalog.INSTANCE.getReason(status, null));
          BasicHttpResponse response = new BasicHttpResponse(line);
          if (headers != null) response.setHeaders(headers);
          response.setEntity(entity);
          try {
            conn.sendResponseHeader(response);
            conn.sendResponseEntity(response);
          } catch (HttpException e) {
            // can't really do much here
          }
        }

        if (conn != null) conn.close(); // this will close insocket
      }
    } catch (SocketException e) {
      // This is a normal exit condition: the socket was canceled, quit
    } catch (IOException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
  }

  private ContentResolver mContentResolver;
  private Thread mThread;
  private ServerSocket mServerSocket;
  private HttpParams mHttpParams;
  private int mPort;
//  private HttpService mHttpService;
}
