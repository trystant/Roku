package com.roku.dvp;

import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import android.util.Log;

public class Channel {
	
	private static final String LOG_PREFIX = "Channel"; 
 
	Channel(Node node) {
		try {
			NamedNodeMap map = node.getAttributes();
			id = map.getNamedItem("id").getNodeValue();
			version = map.getNamedItem("version").getNodeValue();
			name = node.getTextContent();
			if (name==null) Log.w(LOG_PREFIX,"couldn't get channel name");
		} catch(Exception e) { Log.w(LOG_PREFIX,e.toString()); }
	}
	
	String getName() { return name; }
	String getID() {return id;}
	String getVersion() { return version; }
	byte[] getIcon() { return icon; }
	
	void setIcon(byte[] bytes) { icon = bytes; }
	
	private String name;
	private String id;
	private String version;
	private byte[] icon;
}
