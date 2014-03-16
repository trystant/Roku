public class Endpoint {

	Endpoint(String location, long valid_time) {
		this.location = location;
		lastUpdate = System.currentTimeMillis();
		expiration = valid_time * 1000 + lastUpdate;
	}

	public boolean isExpired() {
		return expiration < System.currentTimeMillis();
	}

	public String getLocation() {
		return location;
	}

	public boolean okToUpdate() {
		return System.currentTimeMillis() - lastUpdate > 2000;
	}

	private long expiration;
	private long lastUpdate;
	private String location;
}
