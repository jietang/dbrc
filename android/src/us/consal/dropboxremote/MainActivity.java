package us.consal.dropboxremote;

import static us.consal.dropboxremote.Common.BROADCAST_ID;
import static us.consal.dropboxremote.Common.PREF_NAME;
import static us.consal.dropboxremote.Common.SERVER_URL;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.message.BasicNameValuePair;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.http.AndroidHttpClient;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.google.common.io.ByteStreams;
import com.google.common.io.Closeables;


public class MainActivity extends Activity {

    private static final String TAG = MainActivity.class.getName();

    private SharedPreferences mPrefs;

    private Button mScreenAddBtn;

    private EditText mScreenIdTxt;

    private Button mFakeSendBtn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        final View view = getLayoutInflater().inflate(R.layout.activity_main, null);
        mScreenAddBtn = (Button)view.findViewById(R.id.add_screen_btn);
        mScreenIdTxt = (EditText)view.findViewById(R.id.screen_id_txt);
        mFakeSendBtn = (Button)view.findViewById(R.id.fake_send_btn);

        mScreenAddBtn.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                doAddScreen(mScreenIdTxt.getText().toString());
            }

        });

        mFakeSendBtn.setOnClickListener(new OnClickListener() {

            @Override
            public void onClick(View v) {
                broadcast("http://www.google.com", false);
            }

        });

        setContentView(view);
        mPrefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
    }

    @Override
    public void onResume() {
        super.onResume();
        ensureHaveBroadcast();
    }

    private void ensureHaveBroadcast() {
        if (!mPrefs.contains(BROADCAST_ID)) {
            new RegisterAsyncTask(this) {

                @Override
                protected void onSuccess(int broadcastId) {
                    mPrefs.edit().putInt(BROADCAST_ID, broadcastId).commit();
                    onHaveBroadcast();
                }

            }.execute();
        } else {
            Log.d(TAG, "We have an id: " + mPrefs.getInt(BROADCAST_ID, -1));
            onHaveBroadcast();
        }
    }

    private static final int NEW_SESSION_MENU_ITEM = 1;

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.activity_main, menu);
        menu.add(Menu.NONE, NEW_SESSION_MENU_ITEM, Menu.NONE, "New session");
        return true;
     }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == NEW_SESSION_MENU_ITEM) {
            mPrefs.edit().clear().commit();
            ensureHaveBroadcast();
        }
        return true;
    }

    private void onHaveBroadcast() {
    }

    private void doAddScreen(final String screenId) {
        if (screenId.length() < 1) {
            Toast.makeText(this, "Screen id must not be empty.", Toast.LENGTH_LONG).show();
            return;
        }
        int broadcastId = mPrefs.getInt(BROADCAST_ID, -1);
        new AddScreenAsyncTask(this, broadcastId, screenId).execute();

    }

    private void broadcast(final String value, final boolean terminal) {
        int broadcastId = mPrefs.getInt(BROADCAST_ID, -1);
        new BroadcastAsyncTask(this, broadcastId, value) {

            @Override
            protected void on404() {
                mPrefs.edit().clear().commit();
                ensureHaveBroadcast();
            }

            @Override
            protected void onSuccess() {
                if (terminal) {
                    finish();
                }
            }

        }.execute();
    }


    private final class AddScreenAsyncTask extends AsyncTask<Void, Void, Integer> {
        private final Context mCtx;
        private ProgressDialog mProgress;
        private final String mScreenId;
        private int mBroadcastId;

        private AddScreenAsyncTask(Context ctx, int broadcastId, String screenId) {
            mCtx = ctx;
            mScreenId = screenId;
            mBroadcastId = broadcastId;
        }

        @Override
        protected void onPreExecute() {
            mProgress = ProgressDialog.show(mCtx, "Adding", "Adding Screen");
        }

        @Override
        protected Integer doInBackground(Void... unused) {
            AndroidHttpClient client = null;
            InputStream in = null;

            try {
                final HttpPost post = new HttpPost(SERVER_URL + "/broadcasts/" + mBroadcastId + "/screens/");
                List<NameValuePair> params = new ArrayList<NameValuePair>();
                params.add(new BasicNameValuePair("screen_id", mScreenId));
                post.setEntity(new UrlEncodedFormEntity(params));

                client = AndroidHttpClient.newInstance("Android");
                HttpResponse resp = client.execute(post);
                if (resp.getStatusLine().getStatusCode() != 200) {
                    Log.d(TAG, "Error in add screen: " + resp.getStatusLine().getReasonPhrase() + ", " + resp.getStatusLine().getStatusCode());
                } else {
                    in = resp.getEntity().getContent();
                    String result = new String(ByteStreams.toByteArray(in));
                    Log.d(TAG, "Got result: " + result);
                }

                return resp.getStatusLine().getStatusCode();
            } catch (Exception e) {
                Log.d(TAG, "Request failed.", e);
                return null;
            } finally {
                Closeables.closeQuietly(in);
                if (client != null) {
                    client.close();
                }
            }
        }

        @Override
        protected void onPostExecute(Integer statusCode) {
            mProgress.dismiss();
            if (statusCode != null && statusCode == 200) {
                Toast.makeText(mCtx, "Added screen", Toast.LENGTH_LONG).show();
                mScreenIdTxt.setText("");
                mScreenIdTxt.clearFocus();
                Log.d(TAG, "Add screnen succeeded.");
            } else {
                Log.d(TAG, "Add screen failed with " + statusCode);
                if (statusCode != null && statusCode == 404) {
                    mPrefs.edit().clear().commit();
                    ensureHaveBroadcast();
                }
            }
        }
    }

}
