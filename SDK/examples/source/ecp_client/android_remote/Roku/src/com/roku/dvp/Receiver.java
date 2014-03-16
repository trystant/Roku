package com.roku.dvp;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import android.util.Log;

public class Receiver {

  private final static String LOG_PREFIX = "Receiver";

  public Receiver() {
    mAddress = new String();
    mClient = new DefaultHttpClient();
  }

  public final String getTarget() {
    synchronized (mAddress) {
      return mAddress;
    }
  }

  public final void setTarget(String address) {
    if (address != null) {
      synchronized (mAddress) {
        if (!address.equals(mAddress)) {
          mAddress = address;
        }
      }
    }
  }

  public byte[] getHttp(Transmission t) {
    byte[] result = null;
    final String target = getTarget();
    if (target.length() == 0) return result;
    URI uri;
    try {
      uri = new URI(target + t.packet);
      Log.d(LOG_PREFIX, "URI: " + uri.toString());
      HttpGet request =  new HttpGet(uri);
      if (request==null) return result;
      request.removeHeaders("User-Agent"); // these are not necessary
      HttpResponse response;
      synchronized (mClient) { response = mClient.execute(request); }
      final int code = response.getStatusLine().getStatusCode() / 100;
      Log.d(LOG_PREFIX, "response code: " + code);
      if (code == 2) {
        result = new byte[0];
        HttpEntity entity = response.getEntity();
        if (entity != null) {
          final int length = (int)entity.getContentLength();
          result = readStream(entity.getContent(),length);
        }
        Log.i(LOG_PREFIX, "reception: "+request+ " lag " + Long.toString(System.currentTimeMillis()-t.timestamp));
      }
    } catch (Exception e) {
      result = null;
      Log.w(LOG_PREFIX,e.toString());
    }
    return result;
  }

  private static byte[] readStream(InputStream is, int length) throws IOException {
    byte[] result = null;
    if (length>0) {
      result = new byte[length];
      int total = 0, read = 0;
      do {
        read = is.read(result, total, length-total);
        total += read;
      } while (read>0 && total<length);
    }
    return result;
  }

  private String mAddress;
  private HttpClient mClient;

}
