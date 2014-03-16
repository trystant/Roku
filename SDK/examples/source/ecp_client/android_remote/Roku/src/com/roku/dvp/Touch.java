package com.roku.dvp;

import java.util.concurrent.BlockingQueue;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.os.Vibrator;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;

public final class Touch extends View implements StatusListener, OnTouchListener {

  private static final String LOG_PREFIX = "Touch";
  
  private static long MIN_INTERVAL_FOR_SEND = 50;
  private static long MAX_QUEUE_FOR_SEND = 0;

  public Touch(Context context, AttributeSet attrs) {
    super(context, attrs);
    mStatus = StatusListener.DISCONNECTED;
    selectStatusBitmap();
    mVibrator = (Vibrator)context.getSystemService(Context.VIBRATOR_SERVICE);
    setBackgroundResource(R.drawable.back);
  }

  public void initialize(BlockingQueue<Transmission> queue) {
    mQueue = queue;
    setOnTouchListener(this);
  }

  public void statusChanged(final int status) {
    // Don't switch from success to pending.  Assume everything is fine until
    // something actually fails:
    if (mStatus == StatusListener.SUCCESS && status == StatusListener.PENDING)
      return;

    if (status != mStatus) {
      Log.d(LOG_PREFIX, "Status changing: " + mStatus + " -> " + status);
      mStatus = status;
      synchronized (mStatusBitmap) {
        selectStatusBitmap();
      }
      postInvalidate();
    }
  }

  protected void onLayout(boolean changed, int top, int left, int bottom, int right) {
    super.onLayout(changed, top, left, bottom, right);
    setFocusableInTouchMode(true); // to get key presses/releases
  }

  private void selectStatusBitmap() {
    int resource;
    switch (mStatus) {
    case StatusListener.DISCONNECTED:
      resource = R.drawable.status_disconnected;
      break;
    case StatusListener.PENDING:
      resource = R.drawable.status_pending;
      break;
    case StatusListener.SUCCESS:
      resource = R.drawable.status_success;
      break;
    default:
      resource = R.drawable.status_failed;
    }
    mStatusBitmap =
        BitmapFactory.decodeResource(getContext().getResources(), resource);
  }

  protected void onDraw(Canvas canvas) {
    final Paint paint = new Paint();
    canvas.drawBitmap(mStatusBitmap, getPaddingLeft(), getPaddingTop(), paint);
  }

  public boolean onTouch(View v, MotionEvent event) {
    Transmission transmission = new Transmission();
    //dumpEvent(event);
    String op;
    switch (event.getAction() & MotionEvent.ACTION_MASK) {
        case MotionEvent.ACTION_DOWN:
        case MotionEvent.ACTION_POINTER_DOWN:
        	op = "down";
          break;
        case MotionEvent.ACTION_UP:
        case MotionEvent.ACTION_POINTER_UP:
        	op = "up";
          break;
        case MotionEvent.ACTION_MOVE:
        	op = "move";
        	if (!okToSend()) return true;
          break;
        case MotionEvent.ACTION_CANCEL:
        	op = "cancel";
          break;
        default:
        	op = "unknown";
    }
    final int pointerCount = event.getPointerCount();
 	  String prefix = "touch.";
    /*
    final int historySize = event.getHistorySize();
    for (int h = 0; h < historySize; h++) {
    	String action = "input?";
    	for (int p = 0; p < pointerCount; p++) {
            int pid = event.getPointerId(p);
            String pointer = prefix + pid;
            if (p!=0) action += "&";
            action +=       pointer + ".x="  + event.getHistoricalX(p, h);
            action += "&" + pointer + ".y="  + event.getHistoricalY(p, h);
            action += "&" + pointer + ".op=" + op;
    	}
    	  transmission.packet = action;
        mQueue.offer(transmission);
        //Log.d(LOG_PREFIX,action);
    }
    */
	  String action = "input?";
    for (int p = 0; p < pointerCount; p++) {
        int pid = event.getPointerId(p);
        String pointer = prefix + pid;
        if (p!=0) action += "&";
        action +=       pointer + ".x="  + event.getX(p);
        action += "&" + pointer + ".y="  + event.getY(p);
        action += "&" + pointer + ".op=" + op;
    }	
    transmission.packet = action;
    mQueue.offer(transmission);
    mVibrator.vibrate(20);
    //Log.d(LOG_PREFIX,action);
    return true;
  }

  private boolean okToSend() {
    boolean ok = false;
    long now = System.currentTimeMillis();
    long timeSinceLast = now - mLastSendTime;
    if (timeSinceLast>=MIN_INTERVAL_FOR_SEND && mQueue.size()<=MAX_QUEUE_FOR_SEND) {
      mLastSendTime = now;
      ok = true;
    }
    return ok;
  }

  private volatile int mStatus;
  private BlockingQueue<Transmission> mQueue;
  private Bitmap mStatusBitmap;
  private final Vibrator mVibrator;
  private long mLastSendTime;
}
