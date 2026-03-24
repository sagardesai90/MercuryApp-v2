package quarky.com.br.mercuryjacket.ui.layout;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import androidx.core.content.ContextCompat;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONException;
import org.json.JSONObject;

import java.math.BigDecimal;
import java.math.RoundingMode;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.activity.SettingsActivity;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.controller.JacketGattAttributes;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.ui.view.CustomTextView;

public class  ActionBarLayout extends RelativeLayout implements LocationListener {

    private  final static String WEATHER_URL = "https://api.openweathermap.org/data/2.5/weather?lat=%s&lon=%s&units=metric&APPID=c247dc8b8aaee1f5c2d1543f687b2f3b";

    Context context;
    View temperature_container;
    CustomTextView measure_txt;
    CustomTextView temperature_txt;
    RequestQueue weatherQueue;
    ImageView location_icon;

    private LocationManager locationManager;
    private boolean tempFromLocation = false;
    private Boolean loadWeatherError = false;
    private BluetoothController bluetoothController;
    private Float currentTemperature = Float.NaN;

    public ActionBarLayout(Context context) {
        super(context);
    }

    public ActionBarLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public ActionBarLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public ActionBarLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        this.context               = getContext();
        this.temperature_container = findViewById(R.id.temperature_container);
        this.measure_txt           = findViewById(R.id.measure_txt);
        this.temperature_txt       = findViewById(R.id.temperature_txt);
        this.location_icon         = findViewById(R.id.location_icon);
        this.bluetoothController   = BluetoothController.getInstance();

        final CustomTextView jacket_name_txt = findViewById(R.id.jacket_name_txt);
        jacket_name_txt.setText(AppController.getCurrentJacket().getName());

        final View settings_bt = findViewById(R.id.settings_bt);
        settings_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(getContext(),SettingsActivity.class);
                getContext().startActivity(i);
            }
        });

        temperature_container.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                if(currentTemperature!=Float.NaN)
                {
                    String newTemp = "";

                    if(AppController.getTemperatureMeasure()==AppController.FAHRENHEIT) {
                        AppController.setTemperatureMeasure(AppController.CELSIUS);
                        newTemp = String.valueOf(AppController.fahrenheitToCelsius(currentTemperature));
                    }else {
                        AppController.setTemperatureMeasure(AppController.FAHRENHEIT);
                        newTemp = String.valueOf(AppController.celsiusToFahrenheit(currentTemperature));
                    }

                    updateWeather(newTemp,tempFromLocation);
                }
            }
        });
    }

    private String getExternalTemperature()
    {
        Float value = Float.valueOf((float) (bluetoothController.getValue(JacketGattAttributes.EXTERNAL_TEMPERATURE)/10.0));
        if(AppController.getTemperatureMeasure()==AppController.FAHRENHEIT) value = AppController.celsiusToFahrenheit(value);
        return String.valueOf(value);
    }

    public void resume() {
        getWeather();
    }

    public void pause() {
        if(weatherQueue!=null)
        {
            weatherQueue.cancelAll("weather");
            weatherQueue = null;
        }
    }

    private void getWeather() {
        if(AppController.getCurrentJacket()!=null && AppController.getCurrentJacket().getSetting(Jacket.LOCATION_REQUEST)){
            try {
                tempFromLocation = true;
                loadWeatherError = false;

                locationManager = (LocationManager) context.getSystemService(context.LOCATION_SERVICE);

                boolean sGPSEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) && (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED);
                boolean isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
                Log.e("WEATHER", "GPS: "+sGPSEnabled+", NETWORK: "+isNetworkEnabled);
                locationManager.requestLocationUpdates(sGPSEnabled ? LocationManager.GPS_PROVIDER : LocationManager.NETWORK_PROVIDER, 0, 0, this);

                Location location = locationManager.getLastKnownLocation(sGPSEnabled ? LocationManager.GPS_PROVIDER : LocationManager.NETWORK_PROVIDER);
                Log.e("WEATHER", String.valueOf(location));
                if(location!=null) onLocationChanged(location);
                else if(bluetoothController.isConnected()){
                    loadWeatherError = true;
                    updateWeather(getExternalTemperature(),false);
                }
            }catch (SecurityException e){
                Log.e("ACTIONBARLAYOUT","getWeather() ERROR: "+e.getMessage());
            }
        }else updateWeather(getExternalTemperature(),false);
    }

    @Override
    public void onLocationChanged(Location location) {
        if (location != null) {
            loadWeatherError = false;

            Double lat = location.getLatitude();
            Double lng = location.getLongitude();

            Log.e("WEATHER", "LAT: "+lat+", LONG: "+lng);

            weatherQueue = Volley.newRequestQueue(context);

            final String url = String.format(WEATHER_URL, lat,lng);

            StringRequest weatherRquest = new StringRequest(Request.Method.GET, url,
                    new Response.Listener<String>() {
                        @Override
                        public void onResponse(String response) {
                            weatherQueue = null;
                            Log.e("WEATHER","LOADED FROM API");
                            try {
                                JSONObject jsonObject = new JSONObject(response);
                                JSONObject main = jsonObject.getJSONObject("main");
                                String temperature = main.getString("temp");
                                if(AppController.getTemperatureMeasure()==AppController.FAHRENHEIT) temperature = String.valueOf(Math.round(AppController.celsiusToFahrenheit(Float.parseFloat(temperature))));
                                updateWeather(temperature,true);
                            } catch (JSONException e) {
                                e.printStackTrace();
                            }
                        }
                    }, new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    weatherQueue = null;
                    loadWeatherError = true;
                    updateWeather(getExternalTemperature(),false);
                }
            });
            weatherRquest.setTag("weather");
            weatherQueue.add(weatherRquest);

            locationManager.removeUpdates(this);
        }
    }

    private void updateWeather(String temperature, Boolean tempFromLocation)
    {
        if(temperature!=null && !temperature.equals("-273"))
        {
            Log.e("WEATHER", "UPDATE TEMPERATURE: "+temperature);

            Double truncatedDouble = BigDecimal.valueOf(Double.parseDouble(temperature))
                    .setScale(1, RoundingMode.HALF_UP)
                    .doubleValue();
            temperature = String.valueOf(truncatedDouble);
            this.currentTemperature = Float.parseFloat(temperature);
            //this.currentTemperature = -10.0f;
            temperature = AppController.getTemperatureMeasure()==AppController.CELSIUS && this.currentTemperature<-4 ? "Below -5" : temperature;

            temperature_txt.setText(temperature);
            measure_txt.setText(AppController.getTemperatureMeasure()==AppController.FAHRENHEIT ? "F" : "C");
            location_icon.setImageResource(tempFromLocation?R.drawable.ic_location:R.drawable.ic_jacket);

            this.tempFromLocation = tempFromLocation;
        }
    }

    public void update()
    {
        if(weatherQueue==null)
        {
            boolean sGPSEnabled = false;
            boolean isNetworkEnabled = false;

            if(locationManager!=null)
            {
                sGPSEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) && (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED);
                isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
            }

            if(locationManager==null || loadWeatherError || !AppController.getCurrentJacket().getSetting(Jacket.LOCATION_REQUEST) || (!sGPSEnabled && !isNetworkEnabled)) updateWeather(getExternalTemperature(),false);
            else if(!tempFromLocation) getWeather();
        }
    }

    @Override
    public void onStatusChanged(String s, int i, Bundle bundle) {

    }

    @Override
    public void onProviderEnabled(String s) {

    }

    @Override
    public void onProviderDisabled(String s) {

    }

}
