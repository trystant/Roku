package com.roku.dvp;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.MulticastSocket;
import java.net.SocketException;
import java.util.AbstractMap;
import java.util.Collection;
import java.util.Iterator;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import android.util.Log;

public final class AvailabilityListener implements Runnable {
  private static final int FLAGS =
    Pattern.CASE_INSENSITIVE | Pattern.MULTILINE;
  private static final Pattern status_pattern =
    Pattern.compile("^NOTIFY +\\* +HTTP/1\\.1$", FLAGS);
  private static final Pattern ok_pattern =
    Pattern.compile("^HTTP/1\\.1 +200 +OK$", FLAGS);
  private static final Pattern location_pattern =
    Pattern.compile("^Location: *(.+)$", FLAGS);
  private static final Pattern nt_pattern =
    Pattern.compile("^NT: *roku:(?:rsp:)?ecp$", FLAGS);
  private static final Pattern st_pattern =
    Pattern.compile("^ST: *roku:(?:rsp:)?ecp$", FLAGS);
  private static final Pattern nts_pattern =
    Pattern.compile("^NTS: *ssdp:alive$", FLAGS);
  private static final Pattern usn_pattern =
    Pattern.compile("^USN: *uuid:roku:(?:rsp:)?ecp:(.+)$", FLAGS);
  private static final Pattern cache_pattern =
    Pattern.compile("^Cache-Control:.*max-age *= *(\\d+).*$", FLAGS);

  private static final byte [] MULTICAST_GROUP_IP =
  { (byte)239, (byte)255, (byte)255, (byte)250 };
  private static final int PORT = 1900;

  private static final String LOG_PREFIX = "AvailabilityListener";

  private void trim() { // remove expired entries
    synchronized (mEndpoints) {
      Collection<String> coll = mEndpoints.keySet();
      Iterator<String> iter = coll.iterator();
      while (iter.hasNext()) {
        String key = iter.next();
        Endpoint e = mEndpoints.get(key);
        if (e.isExpired()) {
          mEndpoints.remove(key);
          Log.i(LOG_PREFIX,key+" expires");
        }
      }
    }
  }

  public AvailabilityListener() {
    mEndpoints = new TreeMap<String, Endpoint>();
    mThread = new Thread(this);
    mThread.start();
  }

  public void destroy() {
    if (mSocket != null) {
      try {
        mSocket.leaveGroup(InetAddress.getByAddress(MULTICAST_GROUP_IP));
        mSocket.close(); // asynchronous close
        mSocket = null;
        mThread.join();
        mThread = null;
      } catch (IOException e) {
        // empty
      } catch (InterruptedException e) {
        // empty
      }
    }
  }

  private static final String SEARCH =
    "M-SEARCH * HTTP/1.1\r\n" +
    "Host: 239.255.255.250:1900\r\n" +
    "Man: ssdp:discover\r\n" +
    "ST: roku:rsp:ecp\r\n" +
    "MX: 3\r\n" ;

  protected void search() {
    try {
      DatagramPacket packet =
        new DatagramPacket(SEARCH.getBytes(), SEARCH.length(),InetAddress.getByAddress(MULTICAST_GROUP_IP),PORT);
      mSocket.setLoopbackMode(true);
      Log.i(LOG_PREFIX,"loopback "+(mSocket.getLoopbackMode()?"disabled":"enabled"));
      mSocket.send(packet);
      Log.i(LOG_PREFIX, "searching for Roku service points");
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  protected void listen() throws IOException {
    Log.i(LOG_PREFIX, "listening for Roku service announcements");
    while (true) {
      DatagramPacket packet = new DatagramPacket(new byte [4096], 4096);
      mSocket.receive(packet);
      String data = new String(packet.getData(), 0, packet.getLength());
      parse(data);
    }
  }

  public void run() {
    try {
      mSocket = new MulticastSocket(PORT);
      mSocket.setReuseAddress(true);
      mSocket.setTimeToLive(255);
      mSocket.joinGroup(InetAddress.getByAddress(MULTICAST_GROUP_IP));
      search();
      listen();
    } catch (SocketException e) {
      // normal exit
    } catch (IOException e) {
      e.printStackTrace();
    }
    Log.i(LOG_PREFIX, "Exiting listener thread");
  }

  protected boolean parse(String data) {
    String pa = parseAnnounce(data), pr = null;
    if (pa!=null) pr = parseResponse(data);
    boolean gotOne = (pa==null) || (pr==null);
    //if (!gotOne) Log.i(LOG_PREFIX,pa+","+pr+":\n"+data);
    return gotOne;
  }

  protected String parseAnnounce(String data) {
    String error = null;
    Matcher m;
    m = status_pattern.matcher(data);
    if (m.find()) { // must contain a NOTIFY status line
      m = nt_pattern.matcher(data);
      if (m.find()) { // must contain the correct NT protocol
        m = nts_pattern.matcher(data);
        if (m.find()) { // must be a ssdp.alive broadcast
          m = location_pattern.matcher(data);
          if (m.find()) { // must contain a location
            final String location = m.group(1);
            m = usn_pattern.matcher(data);
            if (m.find()) { // must contain our USN/ESN
              final String esn = m.group(1);
              m = cache_pattern.matcher(data);
              long valid_time = 5 * 60; // default 5 minutes
              if (m.find()) valid_time = Long.parseLong(m.group(1));
              updateEndpoint(esn, location, valid_time);
            } else error = "no USN";
          } else error = "no location";
        } else error = "not alive";
      } else error = "unrecognized service type";
    } else error = "not a notification";
    return error;
  }

  protected String parseResponse(String data) {
    String error = null;
    Matcher m;
    m = ok_pattern.matcher(data);
    if (m.find()) {
      m = st_pattern.matcher(data);
      if (m.find()) { // must contain the correct ST protocol
        m = location_pattern.matcher(data);
        if (m.find()) { // must contain a location
          final String location = m.group(1);
          m = usn_pattern.matcher(data);
          if (m.find()) { // must contain our USN/ESN
            final String esn = m.group(1);
            m = cache_pattern.matcher(data);
            long valid_time = 5 * 60; // default 5 minutes
            if (m.find()) valid_time = Long.parseLong(m.group(1));
            updateEndpoint(esn, location, valid_time);
          } else error = "no USN";
        } else error = "no location";
      } else error = "unrecognized service type";
    } else error = "not an OK response";
    return error;
  }

  public Endpoint updateEndpoint(String esn, String location, long valid_time) {
    synchronized (mEndpoints) {
      Endpoint ep = mEndpoints.get(esn);
      if ((ep==null || ep.okToUpdate()) && location!=null) {
        Log.i(LOG_PREFIX,  "Updating " + esn + " at " + location + " for " + valid_time + " seconds");
        Endpoint newEndpoint = Endpoint.Create(location, valid_time);
        if (newEndpoint!=null) mEndpoints.put(esn, newEndpoint);
        else Log.w(LOG_PREFIX,"Couldn't create endpoint");
      }
    }
    return getEndpoint(esn);
  }

  public String[] getAll() {
    synchronized (mEndpoints) {
      trim();
      String[] keys = new String[mEndpoints.size()];
      Log.i(LOG_PREFIX,"displaying "+keys.length+" endpoints");
      return mEndpoints.keySet().toArray(keys);
    }
  }

  public Endpoint getEndpoint(String esn) {
    synchronized (mEndpoints) {
      Endpoint ep = mEndpoints.get(esn);
      if (ep!=null) ep = ep.clone();
      return ep;
    }
  }

  private Thread mThread;
  private MulticastSocket mSocket;
  private AbstractMap<String, Endpoint> mEndpoints;
}
