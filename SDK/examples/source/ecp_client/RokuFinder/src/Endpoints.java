import java.util.AbstractMap;
import java.util.Collection;
import java.util.Iterator;
import java.util.TreeMap;

public class Endpoints {

	private static final String LOG_PREFIX = "Endpoints: ";

	Endpoints() { mMap = new TreeMap<String, Endpoint>(); }

	private void trim() { // remove expired entries
		synchronized (mMap) {
			Collection<String> coll = mMap.keySet();
			Iterator<String> iter = coll.iterator();
			while (iter.hasNext()) {
				String key = iter.next();
				Endpoint e = mMap.get(key);
				if (e.isExpired()) {
					System.out.println(LOG_PREFIX+key+" expires");
					mMap.remove(key);
				}
			}
		}
	}

	public String[] getAll() {
		synchronized (mMap) {
			trim();
			String[] keys = new String[mMap.size()];
			return mMap.keySet().toArray(keys);
		}
	}

	public String getLocation(String esn) {
		synchronized (mMap) {
			Endpoint e = mMap.get(esn);
			if (e != null) {
				return e.isExpired() ? null : e.getLocation();
			}
		}
		return null;
	}

	public void update(String esn, String location, long valid_time) {
		synchronized (mMap) {
			Endpoint ep = mMap.get(esn);
			if (ep==null || ep.okToUpdate()) {
				System.out.println(LOG_PREFIX+"Updating " + esn + " for " + valid_time + " seconds");
				mMap.put(esn, new Endpoint(location, valid_time));
			}
		}
	}

    private AbstractMap<String, Endpoint> mMap;	

}
