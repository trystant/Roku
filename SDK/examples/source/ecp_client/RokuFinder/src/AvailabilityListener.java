import java.io.IOException;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.MulticastSocket;
import java.net.SocketException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
	private static final String SEARCH =
		"M-SEARCH * HTTP/1.1\r\n" +
		"Host: 239.255.255.250:1900\r\n" +
		"Man: ssdp:discover\r\n" +
		"ST: roku:rsp:ecp\r\n" +
		"MX: 3\r\n" ;
	protected static final byte [] MULTICAST_GROUP_IP =
		{ (byte)239, (byte)255, (byte)255, (byte)250 };
	protected static final int PORT = 1900;
		
	private static final String LOG_PREFIX = "AvailabilityListener: ";

	public AvailabilityListener(Endpoints rsps) {
		mRSPs = rsps;
		mThread = new Thread(this);
	}

	public void go() { mThread.start(); }

	protected void init() {
		try {
			mSocket = new MulticastSocket(PORT);
			mSocket.setReuseAddress(true);
			mSocket.setTimeToLive(255);
			mSocket.joinGroup(InetAddress.getByAddress(MULTICAST_GROUP_IP));
			mSocket.setLoopbackMode(true);
		} catch (SocketException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void destroy() {
		try {
			if (mSocket != null) {
				mSocket.leaveGroup(InetAddress.getByAddress(MULTICAST_GROUP_IP));
				mSocket.close(); // asynchronous close
				mSocket = null;
			}
			mThread.join();
			mThread = null;
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	protected void search() {
		try {
			DatagramPacket packet =
			new DatagramPacket(SEARCH.getBytes(), SEARCH.length(),InetAddress.getByAddress(MULTICAST_GROUP_IP),PORT);
			mSocket.send(packet);
			System.out.println(LOG_PREFIX+"searching for Roku service points");
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	protected void listen() {
		System.out.println(LOG_PREFIX+"listening for Roku service announcements");
		try {
			while (true) {
				DatagramPacket packet = new DatagramPacket(new byte [4096], 4096);
				mSocket.receive(packet);
				String data = new String(packet.getData(), 0, packet.getLength());
				if (!parse(data)) {
					//System.out.println(LOG_PREFIX+"unrecognized data:\n"+data);
				}
			}
		} catch (IOException e) {}
	}

	public void run() {
		init();
		search();
		listen();
		destroy();
		System.out.println(LOG_PREFIX + "Exiting listener thread");
	}

	protected boolean parse(String data) {
		String pa = parseAnnounce(data), pr = null;
		if (pa!=null) pr = parseResponse(data);
		boolean gotOne = (pa==null) || (pr==null);
		//if (!gotOne) System.out.println(LOG_PREFIX+pa+","+pr+":\n"+data);
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
							mRSPs.update(esn, location, valid_time);
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
						mRSPs.update(esn, location, valid_time);
					} else error = "no USN";
				} else error = "no location";
			} else error = "unrecognized service type";
		} else error = "not an OK response";
		return error;
	}

	private Endpoints mRSPs;	
	private MulticastSocket mSocket;
	private Thread mThread;
}
