package us.consal.dropboxremote;

public final class Common {
    static final boolean IS_PROD = true;

    static final String SERVER_URL = IS_PROD ? "http://ec2-54-235-229-59.compute-1.amazonaws.com:80" : "http://10.0.2.2:5000";

    static final String BROADCAST_ID = "BROADCAST_ID";

    static final String PREF_NAME = "REMOTE_PREFS";

}
