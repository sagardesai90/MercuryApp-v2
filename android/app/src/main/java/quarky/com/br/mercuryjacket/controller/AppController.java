package quarky.com.br.mercuryjacket.controller;

import android.app.ActivityManager;
import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import com.google.firebase.analytics.FirebaseAnalytics;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.activity.BaseActivity;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.model.UserInput;

public class AppController extends Application {

    //public static Boolean DEBUG_MODE = false;

    public static final String SCAN_NEW_JACKET_EVENT = "scan_new_jacket";
    public static final String NEW_JACKET_ADDED_EVENT = "new_jacket_added";
    public static final String JACKET_WAS_DELETED_EVENT = "jacket_was_deleted";
    public static final String DEVICE_CONNECTED_EVENT = "device_connected";
    public static final String DEVICE_DISCONNECTED_EVENT = "device_disconnected";

    public static final int CELSIUS    = 1;
    public static final int FAHRENHEIT = 2;
    public static final int KELVIN     = 3;
    public static int TEMPERATURE_MEASURE = -1;

    //isso é apenas em caso de alguma mudança no settings, deve ser incrementado.
    public static final String VERSION = "2";
    private static final String VERSION_KEY = "version";

    private static Context context;
    private static FirebaseAnalytics mFirebaseAnalytics;
    private static final HashMap<Integer,String> mapSettingsNames = new HashMap<Integer,String>();
    private static Jacket currentJacket;
    private static BluetoothController bluetoothController;

    @Override
    public void onCreate() {
        super.onCreate();

        bluetoothController = BluetoothController.getInstance();
        context = getApplicationContext();
        mFirebaseAnalytics = FirebaseAnalytics.getInstance(this);

        /*Jacket jacket1 = new Jacket("00:FD:D6:00:00:02");
        jacket1.setName("Mercury 2");
        jacket1.save();

        Jacket jacket2 = new Jacket("00:FD:D6:00:00:03");
        jacket2.setName("Mercury");
        jacket2.save();*/

        //checkVersion();
        setupSettingsNames();

        if(currentJacket==null && hasJacket()){
            String key = context.getResources().getString(R.string.current_jacket);

            SharedPreferences preferences = getPrefs(context.getResources().getString(R.string.jackets_pref_key));
            String id = getAppPrefs().getString(key, null);

            Jacket instance = new Gson().fromJson(preferences.getString(id, null), Jacket.class);
            currentJacket = instance;
        }

        String historyKey = context.getResources().getString(R.string.input_history);
        if(!getAppPrefs().contains(historyKey))
        {
            UUID powerLevelUUID = JacketGattAttributes.POWER_LEVEL;
            UUID externalTemperatureUUID = JacketGattAttributes.EXTERNAL_TEMPERATURE;

            ArrayList<UserInput> list = new ArrayList<UserInput>();
            list.add(new UserInput(10000,0));
            list.add(new UserInput(2000,200));
            list.add(new UserInput(10000,250));
            list.add(new UserInput(5000,100));
            list.add(new UserInput(10000,0));
            list.add(new UserInput(10000,-210));
            list.add(new UserInput(10000,-200));
            list.add(new UserInput(0,0));
            list.add(new UserInput(0,500));
            list.add(new UserInput(5000,10));

            SharedPreferences appPrefs = getAppPrefs();
            SharedPreferences.Editor edit = appPrefs.edit();
            edit.putString(historyKey,new Gson().toJson(list));
            edit.commit();
        }
    }

    private static void checkVersion()
    {
        SharedPreferences preferences = getAppPrefs();

        final String version = preferences.getString(VERSION_KEY, null);
        if(version==null ||  (version!=null && !version.equals(VERSION)))
        {
            SharedPreferences.Editor edit = preferences.edit();
            edit.clear();
            edit.putString(VERSION_KEY,VERSION);
            edit.commit();

            getPrefs(context.getResources().getString(R.string.jackets_pref_key)).edit().clear().commit();
            getAppPrefs().edit().clear().commit();
        }
    }

    private static void setupSettingsNames()
    {
        mapSettingsNames.put(Jacket.DEBUG, "DEBUG");
        mapSettingsNames.put(Jacket.VOICE_CONTROL, String.format(context.getString(R.string.voice_control)));
        //mapSettingsNames.put(Jacket.BATTERY_NOTIFICATION, String.format(context.getString(R.string.battery_notification)));
        mapSettingsNames.put(Jacket.LOCATION_REQUEST, String.format(context.getString(R.string.allow_connection)));
        mapSettingsNames.put(Jacket.MOTION_CONTROL, String.format(context.getString(R.string.motion_control)));
    }

    public static Context getContext()
    {
        return context;
    }

    public static FirebaseAnalytics getFirebaseAnalytics()
    {
        return mFirebaseAnalytics;
    }

    public static Jacket getCurrentJacket() {
        return currentJacket;
    }

    public static String getSettingName(int key)
    {
        return mapSettingsNames.get(key);
    }

    public static Boolean hasJacket()
    {
        String key = context.getResources().getString(R.string.current_jacket);
        return getAppPrefs().contains(key);
    }

    public static Boolean hasJackets()
    {
        String prefKey = context.getResources().getString(R.string.jackets_pref_key);
        SharedPreferences preferences = getPrefs(prefKey);

        Map<String, ?> prefsMap = preferences.getAll();

        return prefsMap.size()>0;
    }

    public static void addJacket(Jacket jacket)
    {
        String prefKey = context.getResources().getString(R.string.jackets_pref_key);
        SharedPreferences preferences = getPrefs(prefKey);

        SharedPreferences.Editor edit = preferences.edit();
        edit.putString(jacket.getId(),jacket.serialize());
        edit.commit();

        if(getCurrentJacket()!=null && getCurrentJacket().getId().equals(jacket.getId())) connectedTo(jacket);
    }

    public static void removeJacket(Jacket jacket)
    {
        String prefKey = context.getResources().getString(R.string.jackets_pref_key);
        SharedPreferences preferences = getPrefs(prefKey);
        SharedPreferences.Editor edit = preferences.edit();
        edit.remove(jacket.getId());
        edit.commit();

        if(getCurrentJacket()!=null && getCurrentJacket().getId().equals(jacket.getId())){
            currentJacket = null;

            preferences = getAppPrefs();

            String key = context.getResources().getString(R.string.current_jacket);
            edit = preferences.edit();
            edit.remove(key);
            edit.commit();
        }
    }

    public static ArrayList<Jacket> getJacketsList()
    {
        String prefKey = context.getResources().getString(R.string.jackets_pref_key);
        SharedPreferences preferences = getPrefs(prefKey);

        ArrayList<Jacket> list = new ArrayList<Jacket>();

        Map<String, ?> prefsMap = preferences.getAll();
        for (Map.Entry<String, ?> entry: prefsMap.entrySet()) {
            String value = entry.getValue().toString();
            Jacket instance = new Gson().fromJson(value, Jacket.class);
            instance = (getCurrentJacket()!=null && instance.getId().equals(getCurrentJacket().getId())) ? getCurrentJacket() : instance;
            list.add(instance);
        }

        Collections.sort(list, new Comparator<Jacket>() {
            @Override
            public int compare(Jacket jacket, Jacket t1) {
                return  t1.getTime().compareTo(jacket.getTime());
            }

        });

        return list;
    }

    public static void saveUserInput(Integer newPowerLevel)
    {
        UUID powerLevelUUID = JacketGattAttributes.POWER_LEVEL;
        UUID externalTemperatureUUID = JacketGattAttributes.EXTERNAL_TEMPERATURE;

        SharedPreferences appPrefs = getAppPrefs();
        String key = context.getResources().getString(R.string.input_history);
        String string = appPrefs.getString(key, null);

        ArrayList<UserInput> list = string!=null ? (ArrayList<UserInput>) new Gson().fromJson(string, new TypeToken<ArrayList<UserInput>>(){}.getType()) : new ArrayList<UserInput>();
        list.add(new UserInput(newPowerLevel,bluetoothController.getValue(externalTemperatureUUID)));

        if(list.size()>10)
        {
            list.remove(0);
        }

        //Log.e("SAVED_USER_INPUT", String.valueOf(list) + " - " + list.size());

        SharedPreferences.Editor edit = appPrefs.edit();
        edit.putString(key,new Gson().toJson(list));
        edit.commit();
    }

    public static ArrayList<UserInput> getUserHistoryInput()
    {
        SharedPreferences appPrefs = getAppPrefs();
        String key = context.getResources().getString(R.string.input_history);
        String string = appPrefs.getString(key, null);

        ArrayList<UserInput> list = string!=null ? (ArrayList<UserInput>) new Gson().fromJson(string, new TypeToken<ArrayList<UserInput>>(){}.getType()) : new ArrayList<UserInput>();
        return list;
    }

    public static void connectedTo(Jacket jacket)
    {
        currentJacket = jacket;

        SharedPreferences.Editor edit = getAppPrefs().edit();
        String key = context.getResources().getString(R.string.current_jacket);

        if(jacket!=null) edit.putString(key,currentJacket.getId());
        else edit.remove(key);

        edit.commit();
    }

    public static void setTemperatureMeasure(int value)
    {
        TEMPERATURE_MEASURE = value;
        SharedPreferences.Editor edit = getAppPrefs().edit();
        edit.putInt(context.getString(R.string.temperature_measure),TEMPERATURE_MEASURE);
        edit.commit();
    }

    public static int getTemperatureMeasure()
    {
        if(TEMPERATURE_MEASURE<0) TEMPERATURE_MEASURE = getAppPrefs().getInt(context.getString(R.string.temperature_measure), FAHRENHEIT);
        return TEMPERATURE_MEASURE;
    }

    private static SharedPreferences getAppPrefs()
    {
        String prefKey = context.getResources().getString(R.string.app_name);
        SharedPreferences preferences = getPrefs(prefKey);
        return preferences;
    }

    private static SharedPreferences getPrefs(String key)
    {
        SharedPreferences preferences = context.getSharedPreferences(key, 0);
        return preferences;
    }

    public static float celsiusToFahrenheit(float value)
    {
        return (float) ((value*(9.0/5))+32);
    }

    public static float fahrenheitToCelsius(float value)
    {
        return (float) ((value-32)/(9.0/5));
    }

    public static void setUserProperty(String name, String value)
    {
        mFirebaseAnalytics.setUserProperty(name, value);
    }

}
