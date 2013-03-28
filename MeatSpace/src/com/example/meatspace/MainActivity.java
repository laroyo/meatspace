package com.example.meatspace;

import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.provider.Settings.Secure;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.EditText;
import android.widget.Toast;

public class MainActivity extends Activity implements LocationListener {

	public LocationManager _locationManager;
	public static String _android_id;
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().requestFeature(Window.FEATURE_PROGRESS);
        setContentView(R.layout.activity_main);
        _locationManager = (LocationManager)this.getSystemService(Context.LOCATION_SERVICE);
        _locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 5000,
        										10, this);
        _locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 5000,
				10, this);
        _android_id = Secure.getString(getApplicationContext().getContentResolver(),
                Secure.ANDROID_ID);
        WebView wv = (WebView) findViewById(R.id.webView1);
        wv.getSettings().setJavaScriptEnabled(true);
        final Activity activity = this;
        wv.setWebChromeClient(new WebChromeClient() {
        	public void onProgressChanged(WebView view, int progress) {
        		activity.setProgress(progress*1000);
        	}
        });
        wv.setWebViewClient(new WebViewClient() {
        	public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
        		Toast.makeText(activity, "Oh no, something went wrong: " + description, Toast.LENGTH_SHORT).show();
        	}
        });
        wv.loadUrl(Constants.ENDPOINT + "?id="+_android_id);
    }
    
    @Override
    protected void onStart() {
    	super.onStart();
        new Message("start").transmit();
    }

    @Override
    protected void onStop() {
    	super.onStop();
    	new Message("stop").transmit();
    }

    
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

	@Override
	public void onLocationChanged(Location loc) {
		Message msg = new Message("update");
		msg.put("latitude", ""+loc.getLatitude());
		msg.put("longitude", ""+loc.getLongitude());
		msg.transmit();
	}

	@Override
	public void onProviderDisabled(String name) {
		System.out.println("Lost provider: "+name);
	}

	@Override
	public void onProviderEnabled(String name) {
		System.out.println("Acquired provider: "+name);
		
	}

	@Override
	public void onStatusChanged(String arg0, int arg1, Bundle arg2) {
		System.out.println("Location status changed.");
	}
	
	public boolean doSettings(MenuItem item) {
		AlertDialog.Builder alert = new AlertDialog.Builder(this);
		alert.setTitle("Change Name");
		alert.setMessage("Enter your name here");
		alert.setCancelable(false);
		final EditText input = new EditText(this);
		alert.setView(input);
		
		alert.setPositiveButton("OK", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				String value = input.getText().toString();
				System.out.println("Name: " + value);
				Message msg = new Message("name");
				msg.put("name", value);
				msg.transmit(); 
			}
		});
		
		alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {

			@Override
			public void onClick(DialogInterface dialog, int which) {
				// TODO Auto-generated method stub
				
			}
			
		});
		alert.show();
		return true;
	}
  
}
