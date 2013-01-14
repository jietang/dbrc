package us.consal.dropboxremote;

import static us.consal.dropboxremote.Common.BROADCAST_ID;
import static us.consal.dropboxremote.Common.PREF_NAME;
import static us.consal.dropboxremote.Common.SERVER_URL;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map.Entry;

import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
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
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.google.common.io.ByteStreams;
import com.google.common.io.Closeables;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;


public class MainActivity extends Activity {

    private static final String TAG = MainActivity.class.getName();

    private SharedPreferences mPrefs;

    private Button mScreenAddBtn;

    private EditText mScreenIdTxt;

    private Button mFakeSendBtn;

    private ListView mListView;

    private HashSet<String> mLinked = new HashSet<String>();
    private ArrayList<Device> mDevices = new ArrayList<Device>();

    private class Device {
        public final String screenId;
        public final String deviceName;

        public Device(String sid, String dn) {
            screenId = sid;
            deviceName = dn;
        }

        boolean isLinked() {
            return mLinked.contains(screenId);
        }

        @Override
        public String toString() {
            String str = deviceName + "(" + screenId + ")";
            if (isLinked()) {
                return "+" + str;
            }
            return str;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        final View view = getLayoutInflater().inflate(R.layout.activity_main, null);
        mScreenAddBtn = (Button)view.findViewById(R.id.add_screen_btn);
        mScreenIdTxt = (EditText)view.findViewById(R.id.screen_id_txt);
        mFakeSendBtn = (Button)view.findViewById(R.id.fake_send_btn);

        mListView = (ListView)view.findViewById(R.id.listview);

        mListView.setOnItemClickListener(new OnItemClickListener() {

            @Override
            public void onItemClick(AdapterView<?> arg0, View arg1, int position, long arg3) {
                if (position >= 0 && position < mDevices.size()) {
                    Device device = mDevices.get(position);
                    if (device.isLinked()) {
                        unlink(device);
                    } else {
                        link(device);
                    }
                    Log.d(TAG, device.toString());
                } else {
                    Log.d(TAG, "Shucks.." + position);
                }
            }

        });

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

    protected void link(final Device device) {
        final int broadcastId = mPrefs.getInt(BROADCAST_ID, -1);
        new RpcAsyncTask(this) {

            @Override
            protected HttpUriRequest getRequest() throws IOException {
                final HttpPost post = new HttpPost(SERVER_URL + "/broadcasts/" + broadcastId + "/screens/");
                List<NameValuePair> params = new ArrayList<NameValuePair>();
                params.add(new BasicNameValuePair("screen_id", device.screenId));
                post.setEntity(new UrlEncodedFormEntity(params));
                return post;
            }

            @Override
            protected void onSuccess(JsonElement jse) {
                refreshScreens(broadcastId);
            }

        }.execute();
    }

    protected void unlink(final Device device) {
        final int broadcastId = mPrefs.getInt(BROADCAST_ID, -1);
        new RpcAsyncTask(this) {

            @Override
            protected HttpUriRequest getRequest() throws IOException {
                return new HttpDelete(SERVER_URL + "/broadcasts/" + broadcastId + "/screens/" + device.screenId);
            }

            @Override
            protected void onSuccess(JsonElement jse) {
                refreshScreens(broadcastId);
            }

        }.execute();
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
                    onHaveBroadcast(broadcastId);
                }

            }.execute();
        } else {
            int broadcastId = mPrefs.getInt(BROADCAST_ID, -1);
            Log.d(TAG, "We have an id: " + broadcastId);
            onHaveBroadcast(broadcastId);
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

    private void onHaveBroadcast(final int broadcastId) {
        refreshScreens(broadcastId);
    }

    private void refreshScreens(final int broadcastId) {
        new RpcAsyncTask(this) {

            @Override
            protected void onSuccess(JsonElement json) {
                JsonObject ar = json.getAsJsonObject();
                mLinked.clear();
                for (Entry<String, JsonElement> ent : ar.entrySet()) {
                    mLinked.add(ent.getKey());
                }
            }

            @Override
            protected HttpUriRequest getRequest() throws IOException {
                return new HttpGet(SERVER_URL + "/broadcasts/" + broadcastId + "/screens/");
            }

        }.execute();

        new RpcAsyncTask(this) {

            @Override
            protected void onSuccess(JsonElement json) {
                JsonArray ar = json.getAsJsonArray();
                mDevices.clear();
                for (JsonElement elt : ar) {
                    Log.d(TAG, elt.toString());
                    JsonObject obj = elt.getAsJsonObject();
                    mDevices.add(new Device(obj.get("screen_id").getAsString(), obj.get("device_name").getAsString()));
                }

                mListView.setAdapter(new Adapter(MainActivity.this, android.R.layout.simple_list_item_1, new ArrayList<Device>(mDevices)));
                //mListView.setAdapter(new ArrayAdapter<Device>(MainActivity.this, android.R.layout.simple_list_item_1, mDevices.toArray(new Device[mDevices.size()])));
            }

            @Override
            protected HttpUriRequest getRequest() throws IOException {
                return new HttpGet(SERVER_URL + "/broadcasts/" + broadcastId + "/known_screens/");
            }

        }.execute();
    }

    private class Adapter extends ArrayAdapter<Device> {

        public Adapter(Context context, int textViewResourceId, List<Device> objects) {
            super(context, textViewResourceId, objects);
        }

        @Override
        public View getView(int position, View previous, ViewGroup parent) {
            View v = getLayoutInflater().inflate(R.layout.device_item, null);
            Device d = getItem(position);
            TextView txt = (TextView)v.findViewById(R.id.device_txt);
            txt.setText(d.toString());
            ToggleButton toggle = (ToggleButton)v.findViewById(R.id.linked_btn);
            toggle.setChecked(d.isLinked());
            return v;
        }


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
