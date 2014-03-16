public class RokuFinder {

	private static final String LOG_PREFIX = "RokuFinder: ";

	public static void main(String[] args) {
		RokuFinder rf = new RokuFinder();
		rf.go(5);
	    while (true) rf.go(300);
	}

	RokuFinder() {
		mRSPs = new Endpoints();
		mAvailabilityListener = new AvailabilityListener(mRSPs);
		mAvailabilityListener.go();
	}

	void go(long secs) {
		try {
			Thread.sleep(secs * 1000);
		} catch (Exception e) {e.printStackTrace();}
		String[] rsps = mRSPs.getAll();
		System.out.println(LOG_PREFIX+"known RSPs:");
		for (String rsp : rsps) System.out.println(rsp);
	}

    private Endpoints mRSPs;	
	private AvailabilityListener mAvailabilityListener;
}
