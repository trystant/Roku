package com.roku.dvp;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.concurrent.BlockingQueue;

import android.util.Log;

public final class Transmitter implements Runnable {
  private static final String LOG_PREFIX = "Transmitter";
  private static final String QUIT_MARK = "__quit__";

  public Transmitter(BlockingQueue<Transmission> queue, StatusListener listener) {
    mQueue = queue;
    mListener = listener;
    mAddress = null;
    mPort = 0;
    mSocket = new Socket();
    mThread = new Thread(this);
    int priority = mThread.getPriority()+1;
    mThread.setPriority(priority);
    setStatus(StatusListener.DISCONNECTED);
  }

  private void go() {
    if (checkConnect()) mThread.start();
  }

  public void stop() {
    checkClose();
    if (mThread != null && mThread.isAlive()) {
      try {
        mQueue.put(new Transmission(QUIT_MARK));
        mThread.join();
      } catch (InterruptedException e) {
        // throw on destruction
      }
    }
  }

  public void destroy() {
    stop();
    mThread = null;
  }

  private boolean checkConnect() {
    boolean connected = false;
    synchronized (mSocket) {
      connected = mSocket.isConnected() && !mSocket.isOutputShutdown();
      if (!connected && isTargeted()) {
        setStatus(StatusListener.PENDING);
        Log.i(LOG_PREFIX,"connecting to "+mAddress.toString()+":"+Integer.toString(mPort));
        try {
          mSocket.connect(new InetSocketAddress(mAddress,mPort));
          connected = mSocket.isConnected();
          Log.i(LOG_PREFIX,(connected?"connected":"not connected")+" to "+mAddress.toString()+":"+mPort);
          mSocket.setTcpNoDelay(true);
          mRequestStream = mSocket.getOutputStream();
          mResponseStream = mSocket.getInputStream();
        } catch (IOException e) {
          Log.i(LOG_PREFIX,"connect error, "+e.toString());
        }
        setStatus(connected ? StatusListener.SUCCESS : StatusListener.FAILED);
      }
    }
    return connected;
  }

  private void checkClose() {
    try {
      synchronized (mSocket) {
        if (mRequestStream!=null) { mRequestStream.close(); mRequestStream = null; }
        if (mResponseStream!=null) { mResponseStream.close(); mResponseStream = null; }
        if (mSocket.isConnected()) {
          mSocket.close();
          setStatus(StatusListener.DISCONNECTED);
        }
      }
    } catch (IOException e) {
      Log.i(LOG_PREFIX,"close error, "+e.toString());
    }
    setStatus(StatusListener.DISCONNECTED);
  }

  public final void setTarget(InetAddress address, int port) {
    synchronized (mSocket) {
      if (update(address, port)) {
        stop();
        go();
      }
    }
  }

  private boolean isTargeted() {
    return mAddress!=null && mPort>0;
  }

  private boolean update(InetAddress address, int port) {
    boolean changed = mAddress==null || !mAddress.equals(address) || mPort!=port;
    if (changed) { mAddress = address; mPort = port; }
    return changed;
  }

  protected void finalize() throws Throwable {
    destroy();
    super.finalize();
  }

  public void run() {
    mQueue.clear(); // skip old events (might be for diff target)
    while (true) {
      Transmission t = null;
      try {
        t = mQueue.take();
      } catch (InterruptedException e) {
        // nothing to do here
      }
      if (t == null) continue;
      if (t.packet.equals(QUIT_MARK)) return;
      postHttp(t);
    }
  }

  public void setListener(StatusListener listener) {
    mListener = listener;
    sendStatus();
  }

  private byte[] postHttp(final Transmission t) {
    byte[] result = null;
    StringBuffer request = new StringBuffer();
    request.append("POST /"+t.packet+" HTTP/1.1\n\n");
    try {
      synchronized (mSocket) {
        if (checkConnect()) {
          mRequestStream.write(request.toString().getBytes());
          mRequestStream.flush();
          Log.i(LOG_PREFIX, "transmission: "+request+ " lag " + Long.toString(System.currentTimeMillis()-t.timestamp));
          consumeResponse();
        } else Log.i(LOG_PREFIX,"not connected");
      }
    } catch (IOException e) {
      result = null;
      Log.i(LOG_PREFIX,"transmit error, "+e.toString());
    }
    return result;
  }

  private void consumeResponse() {
    // This might read nothing, a partial response, a whole response, or parts of more than one response
    try {
      synchronized (mSocket) {
        int length = mResponseStream.available();
        if (length>0) {
          byte[] result = new byte[length];
          int total = 0, read = 0;
          do {
            read = mResponseStream.read(result, total, length-total);
            total += read;
          } while (read>0 && total<length);
        }
      }
    } catch (IOException e) {
      Log.i(LOG_PREFIX,"response error, "+e.toString());
    }
  }

  private void setStatus(int status) {
    mStatus = status;
    sendStatus();
  }

  private void sendStatus() {
    mListener.statusChanged(mStatus);
  }

  private int mStatus;
  private StatusListener mListener;
  private Thread mThread;
  private final BlockingQueue<Transmission> mQueue;
  private Socket mSocket;
  private InetAddress mAddress;
  private int mPort;
  private OutputStream mRequestStream;
  private InputStream mResponseStream;
}
