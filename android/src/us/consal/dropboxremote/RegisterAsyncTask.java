package us.consal.dropboxremote;

import static us.consal.dropboxremote.Common.SERVER_URL;

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
import android.util.Pair;

import com.google.common.io.ByteStreams;
import com.google.common.io.Closeables;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

abstract class RegisterAsyncTask extends AsyncTask<Void, Void, Pair<Integer, String>> {

    private static final String TAG = RegisterAsyncTask.class.getName();

    private ProgressDialog mProgress;
    private Context mCtx;

    RegisterAsyncTask(Context ctx) {
        mCtx = ctx;
    }

    @Override
    protected void onPreExecute() {
        mProgress = ProgressDialog.show(mCtx, "Registering", "Registering to broadcast...");
    }

    @Override
    protected Pair<Integer, String> doInBackground(Void... params) {
        InputStream in = null;
        AndroidHttpClient client = null;
        try {
            client = AndroidHttpClient.newInstance("Android");
            HttpPost post = new HttpPost(SERVER_URL + "/broadcasts/");
            JsonObject jso = new JsonObject();
            jso.addProperty("remote_id", "Android");
            post.setEntity(new StringEntity(jso.toString()));
            post.addHeader("Content-Type", "application/json");
            HttpResponse resp = client.execute(post);
            int statCode = resp.getStatusLine().getStatusCode();
            if (statCode != 200) {
                return new Pair<Integer, String>(statCode, resp.getStatusLine().getReasonPhrase());
            }
            in = resp.getEntity().getContent();
            return new Pair<Integer, String>(200, new String(ByteStreams.toByteArray(in)));
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
    protected void onPostExecute(Pair<Integer, String> result) {
        mProgress.dismiss();
        if (result == null) {
            Log.d(TAG, "doInBackground failed. :(");
        } else if (result.first != 200) {
            Log.d(TAG, "Failed with " + result.first + ", " + result.second);
        } else {
            try {
                Log.d(TAG, "str: " + result.second);
                JsonObject jso = new JsonParser().parse(result.second).getAsJsonObject();
                Log.d(TAG, "js: " + jso);
                onSuccess(jso.get("broadcast_id").getAsInt());

            } catch (Exception e) {
                Log.d(TAG, "Got exception ", e);
            }
        }
    }

    protected abstract void onSuccess(int broadcastId);
}