package com.example.meatspace;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import android.os.AsyncTask;

@SuppressWarnings("serial")
public class Message extends HashMap<String, String> {

	private final static String server = Constants.ENDPOINT + "meatspace"; 
	
	public Message(String action) {
		super();
        put("id",  MainActivity._android_id);
        put("action", action);
	}
	

	public void transmit() {

		new AsyncTask<Void, Void, Void>() {

			@Override
			protected Void doInBackground(Void... arg0) {
				try {
					URL url = new URL(server);
					HttpURLConnection conn = (HttpURLConnection) url.openConnection();
					conn.setDoOutput(true);
					conn.setRequestMethod("POST");
					conn.setRequestProperty("Content-Type", "application/json");
					conn.setRequestProperty("Accept", "application/json");

					String input = "{";
					boolean isFirst = true;
					for (Map.Entry<String, String> entry : entrySet()) {
						if (!isFirst) input += ", "; else isFirst = false;
						input += "\"" + entry.getKey() + "\" : \"" + entry.getValue() +"\"";
					}
					input += "}";

					System.out.println("Transmitting: "+input);

					OutputStream os = conn.getOutputStream();
					os.write(input.getBytes());
					os.flush();

					if (conn.getResponseCode() != HttpURLConnection.HTTP_OK) {
						throw new RuntimeException("Failed : HTTP error code : "
								+ conn.getResponseCode());
					}
			
					conn.disconnect(); 		
				} catch (Exception e) {
					System.out.println(e.toString());
					e.printStackTrace();
				}
				return null;
			}


		}.execute();
	}

}
