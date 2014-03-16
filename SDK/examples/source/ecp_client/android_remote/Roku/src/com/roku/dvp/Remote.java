package com.roku.dvp;

import java.io.ByteArrayInputStream;

import java.util.AbstractMap;
import java.util.TreeMap;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiManager.MulticastLock;
import android.os.Bundle;
import android.text.format.Formatter;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

public final class Remote extends Activity {
  private static final int MENU_UNIT_SELECTOR = Menu.FIRST + 1;
  private static final int MENU_CHANNEL_SELECTOR = MENU_UNIT_SELECTOR + 1;
  private static final int MENU_TOGGLE_TOUCH = MENU_CHANNEL_SELECTOR + 1;
  private static final int MENU_SETTINGS = MENU_TOGGLE_TOUCH + 1;

  private static final int DIALOG_UNIT_SELECTOR = 1;
  private static final int DIALOG_CHANNEL_SELECTOR = 2;

  private static final String LOG_PREFIX = "RokuRemote";
  private static final String PREFS_NAME = "RokuRemotePrefs";
  private static final String PREFS_ATTR_UNIT_SELECTED = "#selected-esn";

  /** Called when the activity is first created. */
  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    WifiManager wifi = (WifiManager)getApplicationContext()
    .getSystemService(Context.WIFI_SERVICE);
    mMulticastLock = wifi.createMulticastLock("Roku");
    mMulticastLock.acquire();

    // There's no reason landscape mode wouldn't work, but it doesn't make much
    // sense to support it, especially since it's possible it could switch
    // while the user isn't even looking at the display.
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);

    setContentView(R.layout.main);
    mButtons = (Buttons)findViewById(R.id.remote_buttons);
    mTouch = (Touch)findViewById(R.id.touch);
    mQueue = new ArrayBlockingQueue<Transmission>(16);
    mButtons.initialize(mQueue);
    mTouch.initialize(mQueue);
    mTransmitter = new Transmitter(mQueue, mButtons);
    mReceiver = new Receiver();
    mAvailabilityListener = new AvailabilityListener();
    mHttpServer = new HttpServer(this);
    mSensors = new Sensors(getBaseContext(),mQueue);
    mChannels = new TreeMap<String, Channel>();

    mESN = null;
    mApp = null;

    mCurrentScreen = mTouch;
    mAltScreen = mButtons;
    toggleScreen();

    loadPreferences();

    // Handle the SEND intent here.
    if (getIntent().getExtras() != null)
      Log.i(LOG_PREFIX, getIntent().getExtras().keySet().toString());
    String action = null;
    { // artificial scope
      // Text: a URL has been presented via text.
      String url = getIntent().getStringExtra(Intent.EXTRA_TEXT);
      if (url != null) {
        Log.i(LOG_PREFIX, url);
        url = Uri.encode(url);
        action = "launch/dev?url=" + url;
        mQueue.offer(new Transmission(action));
      }
      // Content URI. This needs to be converted to an external URL.
      Uri uri = (Uri)getIntent().getParcelableExtra(Intent.EXTRA_STREAM);
      if (uri != null) {
        final WifiInfo info = wifi.getConnectionInfo();
        if (info != null) {
          final String ip = Formatter.formatIpAddress(info.getIpAddress());
          final String addr = "http://" + ip + ':' + mHttpServer.getPort()
          + '/' + uri.toString();
          action = "launch/dev?url=" + Uri.encode(addr);
          Log.i(LOG_PREFIX, action);
        }
      }
    }
    if (action != null) mQueue.offer(new Transmission(action));
  }

  /** Called when user requests menu. */
  @Override
  public boolean onCreateOptionsMenu(Menu menu) {
    menu.add(0, MENU_UNIT_SELECTOR, 0, R.string.menu_unit_selector)
    .setIcon(android.R.drawable.ic_menu_set_as)
    .setAlphabeticShortcut('I');
    menu.add(0, MENU_TOGGLE_TOUCH, 0, R.string.menu_toggle_touch)
    .setIcon(android.R.drawable.ic_menu_rotate)
    .setAlphabeticShortcut('T');
    menu.add(0, MENU_CHANNEL_SELECTOR, 0, R.string.menu_channel_selector)
    .setIcon(android.R.drawable.ic_menu_view)
    .setAlphabeticShortcut('C');
    //    menu.add(0, MENU_SETTINGS, 0, R.string.menu_settings)
    //        .setIcon(android.R.drawable.ic_menu_preferences)
    //        .setAlphabeticShortcut('S');
    return true;
  }

  protected Dialog onCreateDialog(final int id) {
    LayoutInflater factory = LayoutInflater.from(this);
    switch (id) {
    case DIALOG_UNIT_SELECTOR:
      final View unitListView =
        factory.inflate(R.layout.dialog_unit_selector, null);
      final String[] items = mAvailabilityListener.getAll();
      return new AlertDialog.Builder(Remote.this)
      .setIcon(android.R.drawable.ic_menu_set_as)
      .setTitle(R.string.dialog_connect)
      .setView(unitListView)
      .setItems(items,
          new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, final int which) {
          final String s = items[which];
          Log.i(LOG_PREFIX, "Now connecting to " + s);
          Remote.this.setTarget(s, null);
        }
      })
      .create();
    case DIALOG_CHANNEL_SELECTOR:
      final View channelListView =
        factory.inflate(R.layout.dialog_channel_selector, null);
      final String[] channels = getChannels();
      return new AlertDialog.Builder(Remote.this)
      .setIcon(android.R.drawable.ic_menu_set_as)
      .setTitle(R.string.dialog_launch)
      .setView(channelListView)
      .setItems(getChannels(),
          new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, final int which) {
          final String s = channels[which];
          Log.i(LOG_PREFIX, "Now launching " + s);
          Remote.this.launchChannel(s);
        }
      })
      .create();
    }
    return null;
  }

  /** Called when user selects menu item. */
  @Override
  public boolean onOptionsItemSelected(MenuItem item) {
    switch (item.getItemId()) {
    case MENU_UNIT_SELECTOR:
      removeDialog(DIALOG_UNIT_SELECTOR); // clear state
      showDialog(DIALOG_UNIT_SELECTOR);
      return true;
    case MENU_CHANNEL_SELECTOR:
      removeDialog(DIALOG_CHANNEL_SELECTOR); // clear state
      showDialog(DIALOG_CHANNEL_SELECTOR);
      return true;
    case MENU_SETTINGS:
      return true;
    case MENU_TOGGLE_TOUCH:
      toggleScreen();
      return true;
    }
    return false;
  }

  protected void onResume() {
    super.onResume();
    mSensors.onResume();
  }

  protected void onPause() {
    super.onPause();
    mSensors.onPause();
  }

  protected void onDestroy() {
    mHttpServer.destroy();
    mTransmitter.destroy();
    mAvailabilityListener.destroy();
    mMulticastLock.release();
    super.onStop();
  }

  private void loadPreferences() {
    SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);
    mESN = settings.getString(PREFS_ATTR_UNIT_SELECTED, null);
    if (mESN != null) {
      String location = settings.getString(mESN, null);
      setTarget(mESN, location);
      return;
    }
    setTarget(null, null);
  }

  private void setTarget(String esn, String location) {
    mESN = esn;
    mApp = null;
    updateTitle();
    if (esn != null) {
      Endpoint e = mAvailabilityListener.getEndpoint(esn);
      if (e==null && location!=null) {
        Log.i(LOG_PREFIX,"restore endpoint for "+esn);
        e = mAvailabilityListener.updateEndpoint(esn, location, 5*60); // 5 minutes
      }
      if (e!=null) {
        mTransmitter.setTarget(e.getAddress(), e.getPort());
        mReceiver.setTarget(e.getLocation());
        queryChannels();
        // save current endpoint
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, 0);
        SharedPreferences.Editor editor = prefs.edit();
        editor.clear();
        editor.putString(PREFS_ATTR_UNIT_SELECTED, esn);
        editor.putString(esn, e.getLocation());
        editor.commit();
      } else Log.i(LOG_PREFIX,"no location for "+esn);
    } else Log.i(LOG_PREFIX,"no endpoint");
  }

  private void updateTitle() {
    final String actTitle = Remote.this.getString(R.string.app_name);
    StringBuffer title = new StringBuffer(actTitle);
    title.append(" " + ((mESN==null) ? "(not connected)" : mESN));
    if (mApp!=null) title.append(" - ").append(mApp);
    Remote.this.setTitle(title);
  }

  private void toggleScreen() {
    View tempScreen = mAltScreen;
    mAltScreen = mCurrentScreen;
    mCurrentScreen = tempScreen;
    mCurrentScreen.setVisibility(View.VISIBLE);
    mAltScreen.setVisibility(View.INVISIBLE);
    mTransmitter.setListener((StatusListener)mCurrentScreen);
    mCurrentScreen.setFocusableInTouchMode(true); // to get key presses/releases
  }

  private void queryChannels() {
    String error = null;
    try {
      mChannels.clear();
      byte[] xmlBytes = mReceiver.getHttp(new Transmission("query/apps"));
      if (xmlBytes!=null) {
        ByteArrayInputStream xmlStream = new ByteArrayInputStream(xmlBytes);
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder db = dbf.newDocumentBuilder();
        Document xmlDoc = db.parse(xmlStream);
        Node appDoc = xmlDoc.getFirstChild();
        if (appDoc!=null) {
          String nodeName = appDoc.getNodeName();
          if (nodeName.equals("apps")) {
            Node app = appDoc.getFirstChild();
            while (app!=null) {
              nodeName = app.getNodeName();
              if (nodeName.equals("app")) {
                Channel channel = new Channel(app);
                String name = channel.getName();
                mChannels.put(name,channel);
              }
              app = app.getNextSibling();
            }
          } else error = "not apps list '"+nodeName+"'";
        } else  error = "no XML contents"; 
      } else  error = "no response";
    } catch(Exception e) {
      Log.w(LOG_PREFIX,e.toString());
    } 
    if (error!=null) Log.w(LOG_PREFIX,mESN+" query/apps error: "+error);
  }

  private String[] getChannels() {
    String[] keys = new String[mChannels.size()];
    return mChannels.keySet().toArray(keys);
  }

  private void launchChannel(String channelName) {
    mApp = channelName;
    updateTitle();
    if (mApp!=null) {
      String channelID = mChannels.get(mApp).getID();
      mQueue.offer(new Transmission("launch/"+channelID));
    }
  }

  private BlockingQueue<Transmission> mQueue;
  private Buttons mButtons;
  private Touch mTouch;
  private Transmitter mTransmitter;
  private Receiver mReceiver;
  private AvailabilityListener mAvailabilityListener;
  private HttpServer mHttpServer;
  private Sensors mSensors;
  private MulticastLock mMulticastLock;
  private View mCurrentScreen;
  private View mAltScreen;
  private AbstractMap<String, Channel> mChannels;
  private String mESN;
  private String mApp;
}
