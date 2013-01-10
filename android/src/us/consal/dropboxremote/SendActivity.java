package us.consal.dropboxremote;

import static us.consal.dropboxremote.Common.BROADCAST_ID;
import static us.consal.dropboxremote.Common.PREF_NAME;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

public class SendActivity extends Activity {

    private static final String TAG = SendActivity.class.getName();

    private SharedPreferences mPrefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mPrefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
    }


    @Override
    public void onResume() {
        super.onResume();
        ensureHaveBroadcast();
    }

    @Override
    protected void onNewIntent(Intent i) {
        Log.d(TAG, "Got New Intent!:" + i);
        setIntent(i);
        super.onNewIntent(i);
    }

    private void ensureHaveBroadcast() {
        if (!mPrefs.contains(BROADCAST_ID)) {
            new RegisterAsyncTask(this) {

                @Override
                protected void onSuccess(int broadcastId) {
                    mPrefs.edit().putInt(BROADCAST_ID, broadcastId).commit();
                    onHaveBroadcastId(broadcastId);
                }

            }.execute();
        } else {
            int broadcastId = mPrefs.getInt(BROADCAST_ID, -1);
            Log.d(TAG, "We have an id: " + broadcastId);
            onHaveBroadcastId(broadcastId);
        }
    }

    private void onHaveBroadcastId(int broadcastId) {
        final Intent intent = getIntent();
        if (Intent.ACTION_SEND.equals(intent.getAction())) {
            Log.d(TAG, "We got ACTION_SEND!");
            String text = intent.getExtras() == null ? null : intent.getExtras().getString(Intent.EXTRA_TEXT);
            if (text != null) {
                broadcast(broadcastId, text);
            } else {
                Toast.makeText(this, "Can't send. sorry.", Toast.LENGTH_LONG).show();
                finish();
            }
        }
    }


    private void broadcast(int broadcastId, String value) {
        new BroadcastAsyncTask(this, broadcastId, value) {

            @Override
            protected void on404() {
                Log.d(TAG, "Got 404, trying again.");
                mPrefs.edit().clear().commit();
                ensureHaveBroadcast();
            }

            @Override
            protected void onSuccess() {
                finish();
            }

        }.execute();
    }
}
