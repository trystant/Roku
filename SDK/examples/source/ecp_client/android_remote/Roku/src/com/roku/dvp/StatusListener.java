package com.roku.dvp;

import java.util.EventListener;

public interface StatusListener extends EventListener {
  public static final int FAILED = -1;
  public static final int PENDING = 0;
  public static final int SUCCESS = 1;
  public static final int DISCONNECTED = 2;

  public abstract void statusChanged(int status);
}
