package us.consal.dropboxremote;

import java.io.IOException;
import java.io.InputStream;

import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;

import android.app.ProgressDialog;
import android.content.Context;
import android.net.http.AndroidHttpClient;
import android.os.AsyncTask;
import android.util.Log;
import android.widget.Toast;

import com.google.common.io.ByteStreams;
import com.google.common.io.Closeables;
import com.google.gson.JsonObject;

abstract class BroadcastAsyncTask extends AsyncTask<Void, Void, Integer> {

    private static final String TAG = BroadcastAsyncTask.class.getName();

    private final Context mCtx;
    private final String value;
    private ProgressDialog progress;

    private final int mBroadcastId;

    BroadcastAsyncTask(Context ctx, int broadcastId, String value) {
        mCtx = ctx;
        mBroadcastId = broadcastId;
        this.value = value;
    }

    @Override
    protected void onPreExecute() {
        progress = ProgressDialog.show(mCtx, "Publishing", "Publishing...");
    }

    @Override
    protected Integer doInBackground(Void... unused) {
        AndroidHttpClient client = null;
        InputStream in = null;
        try {
            HttpPost post = new HttpPost(Common.SERVER_URL + "/broadcasts/" + mBroadcastId + "/");
            post.addHeader("Content-Type", "application/json");
            JsonObject jso = new JsonObject();
            jso.addProperty("type", "url");
            jso.addProperty("url", value);
            post.setEntity(new StringEntity(jso.toString()));
            client = AndroidHttpClient.newInstance("Android");
            HttpResponse resp = client.execute(post);
            if (resp.getStatusLine().getStatusCode() != 200) {
                Log.d(TAG, "Error in broadcast: " + resp.getStatusLine().getReasonPhrase());
            } else {
                in = resp.getEntity().getContent();
                String result = new String(ByteStreams.toByteArray(in));
                Log.d(TAG, "Got publish result: " + result);
            }
            return resp.getStatusLine().getStatusCode();
        } catch (IOException e) {
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
        progress.dismiss();
        if (statusCode != null && statusCode == 200) {
            Log.d(TAG, "broadcast succeeded.");
            Toast.makeText(mCtx, "Published!", Toast.LENGTH_LONG).show();
            onSuccess();
        } else {
            Log.d(TAG, "Broadcast with " + statusCode);
            if (statusCode != null && statusCode == 404) {
                on404();
            }
        }
    }

    protected abstract void on404();

    protected abstract void onSuccess();
}