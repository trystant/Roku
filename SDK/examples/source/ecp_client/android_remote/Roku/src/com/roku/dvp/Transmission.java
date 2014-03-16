package com.roku.dvp;

public class Transmission {
  Transmission() {timestamp = System.currentTimeMillis();}
  Transmission(String packet) {this.packet = packet; timestamp = System.currentTimeMillis();}
  public long timestamp;
  public String packet;
}
