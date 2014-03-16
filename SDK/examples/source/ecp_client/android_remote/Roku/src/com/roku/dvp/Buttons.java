package com.roku.dvp;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.concurrent.BlockingQueue;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.graphics.Rect;
import android.os.Vibrator;
import android.util.AttributeSet;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;

public final class Buttons extends View implements StatusListener {

  private static final String LOG_PREFIX = "Buttons";

  private static final int BUTTON_HOME   = 0xffff0000;
  private static final int BUTTON_REV    = 0xffff7f00;
  private static final int BUTTON_PLAY   = 0xff7f7f7f;
  private static final int BUTTON_FWD    = 0xffffffff;
  private static final int BUTTON_SELECT = 0xff0000ff;
  private static final int BUTTON_LEFT   = 0xffffff00;
  private static final int BUTTON_DOWN   = 0xff00ffff;
  private static final int BUTTON_RIGHT  = 0xffff00ff;
  private static final int BUTTON_UP     = 0xff00ff00;

  public Buttons(Context context, AttributeSet attrs) {
    super(context, attrs);
    mStatus = StatusListener.DISCONNECTED;
    selectStatusBitmap();

    mVibrator = (Vibrator)context.getSystemService(Context.VIBRATOR_SERVICE);

    mPressMap = BitmapFactory.decodeResource(context.getResources(),
        R.drawable.remote_press_map);
    mPadImage = BitmapFactory.decodeResource(context.getResources(),
        R.drawable.remote_button_pads);
    mIconImage = BitmapFactory.decodeResource(context.getResources(),
        R.drawable.remote_button_icons);
    setBackgroundResource(R.drawable.back);
  }

  public void initialize(BlockingQueue<Transmission> queue) {
    mQueue = queue;
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

  protected void onLayout(boolean changed, int top, int left, int bottom,
      int right) {
    super.onLayout(changed, top, left, bottom, right);

    if (changed) {
      // I can't for the life of me figure out why there isn't already a
      // function to get this rectangle...
      mBounds = new Rect(top + getPaddingTop(), left + getPaddingLeft(),
          bottom - getPaddingBottom(), right - getPaddingRight());
      mPressMapScaled = scaleKeepAspectRatio(mPressMap, mBounds);
      mPadImageScaled = scaleKeepAspectRatio(mPadImage, mBounds);
      mIconImageScaled = scaleKeepAspectRatio(mIconImage, mBounds);
      final int x = (getWidth() - mPressMapScaled.getWidth()) / 2;
      final int y = (getHeight() - mPressMapScaled.getHeight()) / 2;
      // Redefine the bounds to be the rectangle containing the button press
      // map.  This will be useful later.
      mBounds = new Rect(x, y,
          x + mPressMapScaled.getWidth(),
          y + mPressMapScaled.getHeight());
    }
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

  private Bitmap scaleKeepAspectRatio(final Bitmap bitmap, final Rect rect) {
    int width = rect.width();
    int height = width * bitmap.getHeight() / bitmap.getWidth();
    if (height > rect.height()) {
      height = rect.height();
      width = height * bitmap.getWidth() / bitmap.getHeight();
    }
    return Bitmap.createScaledBitmap(bitmap, width, height, true);
  }

  protected void onDraw(Canvas canvas) {
    final PorterDuff.Mode mode = PorterDuff.Mode.SRC_IN;
    //canvas.drawColor(0xff000040);
    final Paint paint = new Paint();
    canvas.drawBitmap(mStatusBitmap, getPaddingLeft(),
        getPaddingTop(), paint);
    paint.setColorFilter(new PorterDuffColorFilter(0x60ffffff, mode));
    canvas.drawBitmap(mPadImageScaled, null, mBounds, paint);
    paint.setColorFilter(new PorterDuffColorFilter(0xff000000, mode));
    canvas.drawBitmap(mIconImageScaled, null, mBounds, paint);
  }

  private boolean onKeyEvent(String action, KeyEvent event) {
    switch (event.getKeyCode()) {
    case KeyEvent.KEYCODE_DEL:         action += "Backspace";  break;
    case KeyEvent.KEYCODE_SEARCH:      action += "Search";     break;
    case KeyEvent.KEYCODE_ENTER:       action += "Enter";      break;
    case KeyEvent.KEYCODE_DPAD_UP:     action += "Up";         break;
    case KeyEvent.KEYCODE_DPAD_DOWN:   action += "Down";       break;
    case KeyEvent.KEYCODE_DPAD_LEFT:   action += "Left";       break;
    case KeyEvent.KEYCODE_DPAD_RIGHT:  action += "Right";      break;
    case KeyEvent.KEYCODE_DPAD_CENTER: action += "Select";     break;
    default:
      {
        final char ch = (char)event.getUnicodeChar();
        if (ch == 0) return false; // no modifiers or other strange keys

        action += "Lit_"; // literal character
        try {
          action += URLEncoder.encode(Character.toString(ch), "UTF-8");
        } catch (UnsupportedEncodingException e) {
          return false;
        }
      }
    }
    Log.i(LOG_PREFIX, "key: " + action);
    mQueue.offer(new Transmission(action));
    return true;
  }

  public boolean onKeyDown(int key, KeyEvent event) {
    return onKeyEvent("keydown/", event);
  }

  public boolean onKeyUp(int key, KeyEvent event) {
    return onKeyEvent("keyup/", event);
  }

  public boolean onTouchEvent(MotionEvent event) {
    Transmission transmission = new Transmission();
    String action = new String();

    if (event.getAction() == MotionEvent.ACTION_DOWN) {
      action += "keydown/";

      final int x = (int)event.getX() - mBounds.left;
      final int y = (int)event.getY() - mBounds.top;

      if (x < 0 || x >= mBounds.width()) return false;
      if (y < 0 || y >= mBounds.height()) return false;

      switch (mPressMapScaled.getPixel(x, y)) {
      case BUTTON_HOME:   mCurrentKey = "Home";   break;
      case BUTTON_REV:    mCurrentKey = "Rev";    break;
      case BUTTON_PLAY:   mCurrentKey = "Play";   break;
      case BUTTON_FWD:    mCurrentKey = "Fwd";    break;
      case BUTTON_SELECT: mCurrentKey = "Select"; break;
      case BUTTON_LEFT:   mCurrentKey = "Left";   break;
      case BUTTON_DOWN:   mCurrentKey = "Down";   break;
      case BUTTON_RIGHT:  mCurrentKey = "Right";  break;
      case BUTTON_UP:     mCurrentKey = "Up";     break;
      default: return false;
      }
      action += mCurrentKey;
      Log.i(LOG_PREFIX, "touch at (" + x + "," + y + ") " + action);
    } else if (event.getAction() == MotionEvent.ACTION_UP) {
      if (mCurrentKey != null) {
        action += "keyup/";
        action += mCurrentKey;
        Log.i(LOG_PREFIX, "touch release:" + action);
        mCurrentKey = null;
      }
    } else {
      return false; // nothing to do
    }

    mVibrator.vibrate(20);
    transmission.packet = action;
    mQueue.offer(transmission);
    return true;
  }

  private volatile int mStatus;
  private BlockingQueue<Transmission> mQueue;
  private Rect mBounds;
  private Bitmap mStatusBitmap;
  private final Bitmap mPressMap;
  private Bitmap mPressMapScaled;
  private final Bitmap mPadImage;
  private Bitmap mPadImageScaled;
  private final Bitmap mIconImage;
  private Bitmap mIconImageScaled;
  private final Vibrator mVibrator;
  private String mCurrentKey;
}
