package com.roku.dvp;

import java.util.concurrent.BlockingQueue;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

public class Sensors implements SensorEventListener {
    private SensorManager mSensorManager;
    private Sensor mAccelerometer;
    private Sensor mGyroscope;
    private Sensor mMagnetometer;
    private int mUpdateRate = SensorManager.SENSOR_DELAY_NORMAL;
    private BlockingQueue<Transmission> mQueue;
    private static final String LOG_PREFIX = "Sensors";

    public Sensors(Context context, BlockingQueue<Transmission> queue) {
        mSensorManager = (SensorManager)context.getSystemService(Context.SENSOR_SERVICE);
        if (mSensorManager!=null) {
        	mAccelerometer = mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        	mGyroscope     = mSensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
        	mMagnetometer  = mSensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
        	Log.i(LOG_PREFIX,"detected" + got(mAccelerometer,"accel") + got(mGyroscope,"gyro") + got(mMagnetometer,"magnet"));
        }
        mQueue = queue;
    }

    private static String got(Sensor s, String t) { return (" " + t + ":" + (s==null?"none":("'"+s.getName()+"'"))); }

    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    }

    public void onSensorChanged(SensorEvent event) {
      if (mQueue.size()>-1) return;
      Transmission transmission = new Transmission();
   	  String prefix=null;
    	switch (event.sensor.getType()) {
	    	case Sensor.TYPE_ACCELEROMETER:  prefix = "acceleration."; break;
	    	case Sensor.TYPE_GYROSCOPE:      prefix = "rotation.";     break;
	    	case Sensor.TYPE_MAGNETIC_FIELD: prefix = "magnetic.";     break;
    	}
    	if (prefix!=null) {
	    	float x = event.values[0];
	        float y = event.values[1];
	        float z = event.values[2];
	        String action = "input?"+prefix+"x="+x+"&"+prefix+"y="+y+"&"+prefix+"z="+z;
	        Log.v(LOG_PREFIX, action);
	        transmission.packet = action;
	        mQueue.offer(transmission);
    	}
    }

    protected void onResume() {
        if (mAccelerometer!=null) mSensorManager.registerListener(this, mAccelerometer, mUpdateRate);
        if (mGyroscope!=null)     mSensorManager.registerListener(this, mGyroscope,     mUpdateRate);
        if (mMagnetometer!=null)  mSensorManager.registerListener(this, mMagnetometer,  mUpdateRate);
    }

    protected void onPause() {
    	if (mAccelerometer!=null || mGyroscope!=null || mMagnetometer!=null) mSensorManager.unregisterListener(this);
    }
}
