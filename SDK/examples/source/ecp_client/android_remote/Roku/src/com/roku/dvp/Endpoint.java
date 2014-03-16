package com.roku.dvp;

import android.os.SystemClock;
import android.util.Log;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class Endpoint {

  private static final int FLAGS =
    Pattern.CASE_INSENSITIVE;
  private static final Pattern address_pattern =
    Pattern.compile("http://(\\d+.\\d+.\\d+.\\d+)(?::(\\d+))?/", FLAGS);

  private static final String LOG_PREFIX = "Endpoint: ";

  public static Endpoint Create(String location, long valid_time) {
    if (location!=null) {
      Matcher m = address_pattern.matcher(location);
      if (m.find()) {
        try {
          InetAddress address = InetAddress.getByName(m.group(1));
          if (address!=null) {
            String portString = m.group(2);
            if (portString!=null) {
              int port = Integer.decode(portString);
              return new Endpoint(location,address,port,valid_time);
            } else Log.w(LOG_PREFIX,"couldn't parse port from "+location);
          } else Log.w(LOG_PREFIX,"couldn't parse address from "+location);
        } catch (UnknownHostException e) {
          Log.w(LOG_PREFIX,"unknown host "+location);
        }
      } else Log.w(LOG_PREFIX,"couldn't parse location "+location);
    } else Log.i(LOG_PREFIX,"no location");
    return null;
  }

  private Endpoint() {}

  private Endpoint(String location, InetAddress address, int port, long valid_time) {
    long lastUpdate = SystemClock.uptimeMillis();
    init(location, address, port, lastUpdate, valid_time * 1000 + lastUpdate);
  }

  private void init(String location, InetAddress address, int port, long lastUpdate, long expiration) {
    this.location = location;
    this.address = address;
    this.port = port;
    this.lastUpdate = lastUpdate;
    this.expiration = expiration;
  }

  public Endpoint clone() {
    Endpoint ep = new Endpoint();
    ep.init(location, address, port, lastUpdate, expiration);
    return ep;
  }

  public boolean isExpired() {
    return expiration < SystemClock.uptimeMillis();
  }

  public String getLocation() {
    return location;
  }

  public InetAddress getAddress() {
    return address;
  }

  public int getPort() {
    return port;
  }

  public boolean okToUpdate() {
    long timeSinceLastUpdate = SystemClock.uptimeMillis() - lastUpdate;
    return timeSinceLastUpdate > 2 * 1000; // min 2 secs between updates
  }

  private long lastUpdate;
  private long expiration;
  private String location;
  private InetAddress address;
  private int port = 0;
}
