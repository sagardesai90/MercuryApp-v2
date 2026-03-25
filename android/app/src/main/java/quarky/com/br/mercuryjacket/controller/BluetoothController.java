package quarky.com.br.mercuryjacket.controller;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Handler;
import android.text.TextUtils;
import android.util.Log;

import com.amazon.identity.auth.device.AuthError;
import com.amazon.identity.auth.device.api.Listener;
import com.amazon.identity.auth.device.api.authorization.AuthorizationManager;
import com.amazon.identity.auth.device.api.authorization.AuthorizeResult;
import com.amazon.identity.auth.device.api.authorization.ProfileScope;
import com.amazon.identity.auth.device.api.authorization.Scope;
import com.amazon.identity.auth.device.api.workflow.RequestContext;
import com.amazon.identity.auth.device.authorization.api.AmazonAuthorizationManager;
import com.amazon.identity.auth.device.authorization.api.AuthzConstants;
import com.amazon.identity.auth.device.shared.APIListener;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.activity.BaseActivity;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.util.HexString;
import quarky.com.br.mercuryjacket.util.ValueInterpreter;

public class BluetoothController{
    private final String TAG                 = "BluetoothController";
    private final String DEFAULT_DEVICE_NAME = "Mercury App";
    private final int SCAN_TIME              = 12;
    private final int READ_TIME              = 3;
    private final String ALEXA_URL           = "https://x0i55e3ypk.execute-api.us-east-1.amazonaws.com/prod/?email=%s";

    private static BluetoothController instance;

    public interface Listener {
        void onAdapterConnect();
        void onAdapterDisconnect();
        void onScanFound(BluetoothDevice device);
        void onScanNotFound();
        void onUnableBluetooth();
        void onDeviceConnected();
        void onServicesDiscovered();
        void onDeviceConnecting();
        void onDeviceDisconnected(Boolean tryReconnect);
        void onUpdateCharacteristic(UUID uuid, String value);
        void onStartUpdate();
    }
    private ArrayList<Listener> listeners = new ArrayList<Listener>();

    private BluetoothAdapter adapter;
    private BluetoothGatt mGatt;
    private BluetoothDevice device;
    private HashMap<UUID,BluetoothGattCharacteristic> characteristicsDic = null;
    private HashMap<UUID,String> characteristicValuesDic = new HashMap<UUID, String>();
    private List<UUID> queueReadCharacteristic = new ArrayList<>();
    private List<HashMap<String,Object>> queueWriteCharacteristic = new ArrayList<>();

    private Boolean scanning = false;
    private Boolean deviceConnected = false;
    private String currentDeviceID = null;
    private CountDownTimer scanTimer;
    private CountDownTimer readTimer;
    private Boolean busy = false;

    //private AmazonAuthorizationManager mAuthManager;
    //private String amazon_email;
    private RequestQueue amazonQueue;
    private Boolean amazonLoading = false;

    private BaseActivity context;

    public BluetoothController()
    {
        instance = this;
        setupBluetooth();
    }

    public static BluetoothController getInstance()
    {
        if(instance==null) instance = new BluetoothController();
        return instance;
    }

    public HashMap<UUID,BluetoothGattCharacteristic> getCharacteristics()
    {
        return characteristicsDic;
    }

    public Integer getValue(UUID uuid)
    {
        String value = characteristicValuesDic.get(uuid);
        return value!=null ? Integer.parseInt(value) : 0;
    }

    public Boolean isConnected()
    {
        return deviceConnected;
    }

    private void startTimer()
    {
        stopTimer();
        Integer time = SCAN_TIME*1000;
        scanTimer = new CountDownTimer(time, time) {

            public void onTick(long millisUntilFinished) {
            }

            public void onFinish() {
                notFoud();
            }
        }.start();
    }

    private void stopTimer()
    {
        if(scanTimer != null)
        {
            scanTimer.cancel();
            scanTimer = null;
        }
    }

    public void connect(BluetoothDevice device)
    {
        this.device = device;
        this.dispatchEvent("onDeviceConnecting");
        this.startTimer();

        if(device.getBondState()==BluetoothDevice.BOND_BONDED)
        {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) mGatt = device.connectGatt(AppController.getContext(), true, gattCallback, BluetoothDevice.TRANSPORT_LE);
            else mGatt = device.connectGatt(AppController.getContext(), true, gattCallback);
        }else device.createBond();
    }

    private void unpairDevice(BluetoothDevice device) {
        try {
            Method m = device.getClass().getMethod("removeBond", (Class[]) null);
            m.invoke(device, (Object[]) null);
        } catch (Exception e) { Log.e(TAG, e.getMessage()); }
    }

    public void stopConnection()
    {
        Log.e(TAG,"stopConnection");
        if(mGatt!=null)
        {
            mGatt.disconnect();
            if(mGatt!=null) mGatt.close();
            mGatt = null;
        }
        if(readTimer!=null)
        {
            readTimer.cancel();
            readTimer = null;
        }
        deviceConnected = false;
        busy = false;
        characteristicsDic = null;
        queueReadCharacteristic.clear();
        queueWriteCharacteristic.clear();
        characteristicValuesDic.clear();

        if(amazonQueue!=null){
            amazonQueue.cancelAll("alexa");
            amazonLoading = false;
        }

        stopScan();
        if(device != null) {
            //unpairDevice(device);
            device = null;
        }
        this.adapter.cancelDiscovery();
    }

    private void notFoud()
    {
        Log.e(TAG,"notFoud");
        stopConnection();
        dispatchEvent("onScanNotFound");
    }

    public void scanDevice(String id)
    {
        if(!scanning) {
            Log.e(TAG,"scanDevices");
            currentDeviceID = id;
            scanning = true;
            startTimer();

            if(id!=null)
            {
                BluetoothDevice device = null;

                Set<BluetoothDevice> pairedDevices = adapter.getBondedDevices();
                for(BluetoothDevice bt : pairedDevices)
                {
                    if(bt.getAddress().equals(id)){
                        device = bt;
                        Log.e("CURRENT_DEVICE", "getBondedDevices() "+String.valueOf(device));
                        break;
                    }
                }

                if(device==null){
                    device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(id);
                    if(device!=null) Log.e("CURRENT_DEVICE", "getRemoteDevice() "+String.valueOf(device));
                }
                
                if(device!=null)
                {
                    connect(device);
                    return;
                }
            }

            this.adapter.startDiscovery();
        }
    }

    public void stopScan()
    {
        if(scanning)
        {
            scanning = false;
            this.adapter.cancelDiscovery();
            stopTimer();
        }
    }

    private void runQueue()
    {
        if(queueWriteCharacteristic.size()>0)
        {
            nextQueueWrite();
        }else{
            if(queueReadCharacteristic.size()>0)
            {
                nextQueueRead();
            }else{
                if(readTimer!=null)
                {
                    readTimer.cancel();
                }
                context.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {

                        Integer time = READ_TIME*1000;
                        readTimer = new CountDownTimer(time, time) {

                            public void onTick(long millisUntilFinished) {
                            }

                            public void onFinish() {
                                readCharacteristics();
                            }
                        }.start();

                    }
                });
            }
        }
    }

    public void readCharacteristics()
    {
        if(readTimer!=null)
        {
            readTimer.cancel();
            readTimer = null;
        }

        Log.e("readCharacteristics","*******************************************************");

        checkVoiceControl();

        for(Map.Entry<UUID, BluetoothGattCharacteristic> entry : characteristicsDic.entrySet()) {
            UUID key = entry.getKey();
            //BluetoothGattCharacteristic value = entry.getValue();
            readCharacteristic(key);
        }
    }

    public void readCharacteristic(UUID uuid)
    {
        queueReadCharacteristic.add(uuid);
        nextQueueRead();
    }

    private void nextQueueRead()
    {
        if(!busy && mGatt!=null)
        {
            busy = true;
            mGatt.readCharacteristic(characteristicsDic.get(queueReadCharacteristic.get(0)));
        }
    }

    public void writeCharacteristic(UUID uuid, Integer intValue)
    {
        //Log.e(TAG, "writeCharacteristic: "+JacketGattAttributes.getName(uuid) +" value: "+intValue);
        //add to queue
        HashMap<String, Object> hash = new HashMap<>();
        hash.put("uuid",uuid);
        hash.put("value",intValue);
        queueWriteCharacteristic.add(hash);
        nextQueueWrite();
    }

    private void nextQueueWrite()
    {
        if(!busy)
        {
            busy = true;

            HashMap<String, Object> hash = queueWriteCharacteristic.get(0);
            UUID uuid = (UUID) hash.get("uuid");
            Integer intValue = (Integer) hash.get("value");
            int format = JacketGattAttributes.getFormat(uuid);

            if(uuid!=null && characteristicsDic!=null){
                BluetoothGattCharacteristic characteristic = characteristicsDic.get(uuid);
                characteristic.setValue(intValue,format,0);

                mGatt.writeCharacteristic(characteristic);
            }
        }
    }

    private final BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            Log.e("onConnectionStateChange", "Status: " + status);
            switch (newState) {
                case BluetoothProfile.STATE_CONNECTED:
                    Log.e("gattCallback", "STATE_CONNECTED");

                    deviceConnected = true;
                    stopScan();
                    dispatchEvent("onDeviceConnected");

                    gatt.discoverServices();
                    break;
                case BluetoothProfile.STATE_DISCONNECTED:
                    Log.e("gattCallback", "STATE_DISCONNECTED");
                    if(deviceConnected)
                    {
                        deviceConnected = false;
                        stopConnection();
                        dispatchEvent("onDeviceDisconnected",true);
                    }else{
                        notFoud();
                    }
                    break;
                default:
                    Log.e("gattCallback", "STATE_OTHER");
            }

        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            List<BluetoothGattService> services = gatt.getServices();

            if(services.size()>0 && characteristicsDic==null)
            {
                Log.e("onServicesDiscovered", services.toString());

                UUID[] characteristics = {
                        JacketGattAttributes.EXTERNAL_TEMPERATURE,
                        JacketGattAttributes.ACTIVITY_LEVEL,
                        JacketGattAttributes.SET_LOW_TEMP,
                        JacketGattAttributes.SET_HIGH_TEMP,
                        JacketGattAttributes.HIGH_TEMP_PT,
                        JacketGattAttributes.LOW_TEMP_PT,
                        JacketGattAttributes.MODE,
                        JacketGattAttributes.POWER_LEVEL,
                        JacketGattAttributes.SAVE_NV_SETTINGS,
                        JacketGattAttributes.MOTION_TEMP
                };

                characteristicsDic = new HashMap<UUID, BluetoothGattCharacteristic>();

                for (BluetoothGattService service : services) {
                    if(service.getUuid().toString().equals(JacketGattAttributes.SERVICE.toString()))
                    {
                        for (UUID uuid : characteristics) {
                            BluetoothGattCharacteristic characteristic = service.getCharacteristic(uuid);
                            if(characteristic!=null)
                            {
                                if(characteristic.getUuid().equals(JacketGattAttributes.ACTIVITY_LEVEL.toString()))
                                {
                                    gatt.setCharacteristicNotification(characteristic, true);
                                }
                                characteristicsDic.put(uuid,characteristic);
                            }
                        }
                        break;
                    }
                }

                dispatchEvent("onServicesDiscovered");

                readCharacteristics();
            }
        }

        @Override
        public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {

            busy = false;

            final byte[] data = characteristic.getValue();

            //check if exist write in queue -------
            Boolean hasWriteInQueue = false;
            for (HashMap<String,Object> hash : queueWriteCharacteristic)
            {
                UUID writeUUid = (UUID) hash.get("uuid");
                if(writeUUid.toString().equals(characteristic.getUuid().toString())){
                    hasWriteInQueue = true;
                    break;
                }
            }
            //-------------------------------------

            if(data==null || hasWriteInQueue || status==BluetoothGatt.GATT_FAILURE) {
                runQueue();
                return;
            }

            readValue(characteristic);

            runQueue();
        }

        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            super.onCharacteristicWrite(gatt, characteristic, status);
            Log.e(TAG,"onCharacteristicWrite: "+JacketGattAttributes.getName(characteristic.getUuid()));
            busy = false;
            if(status==BluetoothGatt.GATT_FAILURE)
            {
                runQueue();
                return;
            }
            if(characteristic.getUuid().toString().equals(JacketGattAttributes.SAVE_NV_SETTINGS.toString()))
            {
                characteristicValuesDic.put(JacketGattAttributes.POWER_LEVEL,null);
            }
            queueWriteCharacteristic.remove(0);
            runQueue();
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            super.onCharacteristicChanged(gatt, characteristic);
            readValue(characteristic);
        }
    };

    private void readValue(BluetoothGattCharacteristic characteristic)
    {
        String value = "";
        byte[] data = characteristic.getValue();
        UUID uuid = characteristic.getUuid();
        int format = JacketGattAttributes.getFormat(uuid);

        if(format==-1) {
            if (data != null && data.length > 0) {
                final StringBuilder stringBuilder = new StringBuilder(data.length);
                for (byte byteChar : data)
                    stringBuilder.append(String.format("%02X ", byteChar));
                value = new String(data) + "\n" + stringBuilder.toString();
                value = value.replaceAll("[^\\d.]", "");
            }
        }else if(format>0) value = String.valueOf(ValueInterpreter.getIntValue(data, format, 0));
        else value = HexString.bytesToHex(data);

        Log.e("CHARACTERISTIC",JacketGattAttributes.getName(uuid)+" = "+value);
        //Log.e("ASUASHUASHUASUH",JacketGattAttributes.getName(uuid)+" - "+characteristicValuesDic.get(JacketGattAttributes.EXTERNAL_TEMPERATURE)+" - "+value+" - "+value.equals(characteristicValuesDic.get(uuid)));

        if(!characteristicValuesDic.containsKey(uuid) || !value.equals(characteristicValuesDic.get(uuid)))
        {
            //Log.e("CHARACTERISTIC",JacketGattAttributes.getName(uuid)+" = "+value);
            characteristicValuesDic.put(uuid,value);
            dispatchEvent("onUpdateCharacteristic",uuid,value);
        }

        queueReadCharacteristic.remove(0);
    }

    private final BroadcastReceiver stateBluetoothReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            ((Activity) context).runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    String action = intent.getAction();

                    Log.e(TAG,"Broadcast Receiver:" + action);
                    
                    if (action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
                        if (adapter.getState() == BluetoothAdapter.STATE_OFF) {
                            Log.e(TAG,"BLUETOOTH OFF");
                            dispatchEvent("onAdapterDisconnect");
                            if(deviceConnected)
                            {
                                deviceConnected = false;
                                stopConnection();
                                dispatchEvent("onDeviceDisconnected",true);
                            }
                        }else if(adapter.getState() == BluetoothAdapter.STATE_ON){
                            Log.e(TAG,"BLUETOOTH ON");
                            dispatchEvent("onAdapterConnect");
                            setupBluetooth();
                        }
                    }else if (action.equalsIgnoreCase( BluetoothDevice.ACTION_FOUND)) {

                        BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

                        String name = device.getName();
                        Log.e("DEVICE", "Name: "+name);

                        if(currentDeviceID != null)
                        {
                            if(device.getAddress().equals(currentDeviceID))
                            {
                                adapter.cancelDiscovery();
                                connect(device);
                            }
                        }else{
                            if (name != null && name.equals(DEFAULT_DEVICE_NAME)) {

                                int hashCode = device.hashCode();
                                String address = device.getAddress();

                                Log.e("DEVICE", "Device Name: " + name + ", Address: " + address + ", HashCode: " + hashCode + " ");

                                String prefKey = context.getResources().getString(R.string.jackets_pref_key);
                                SharedPreferences preferences = context.getSharedPreferences(prefKey, 0);

                                if (!preferences.contains(address)) {
                                    stopScan();
                                    dispatchEvent("onScanFound",device);
                                }
                            }
                        }
                    }else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                        Log.e(TAG,"ACTION_DISCOVERY_FINISHED");
                    }else if (BluetoothDevice.ACTION_BOND_STATE_CHANGED.equals(action)) {
                        int state = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, -1);
                        switch (state) {
                            case BluetoothDevice.BOND_NONE:
                                Log.e("BOND","The remote device is not bonded.");
                                stopConnection();
                                dispatchEvent("onDeviceDisconnected",false);
                                break;
                            case BluetoothDevice.BOND_BONDING:
                                Log.e("BOND","Bonding is in progress with the remote device.");
                                break;
                            case BluetoothDevice.BOND_BONDED:
                                Log.e("BOND","The remote device is bonded.");
                                if(device!=null) {
                                    final Handler handler = new Handler();
                                    handler.postDelayed(new Runnable() {
                                        @Override
                                        public void run() {
                                            connect(device);
                                        }
                                    }, 500);
                                }
                                break;
                            default:
                                Log.e("BOND","Unknown remote device bonding state.");
                                break;
                        }
                    }
                }
            });
        }
    };

    private void setupBluetooth()
    {
        adapter = BluetoothAdapter.getDefaultAdapter();
    }

    public void registerReceiver(BaseActivity context)
    {
        this.context = context;

        Log.e(TAG,"registerReceiver: "+context);

        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        filter.addAction(BluetoothDevice.ACTION_PAIRING_REQUEST);
        filter.addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED);
        filter.setPriority(IntentFilter.SYSTEM_HIGH_PRIORITY);

        context.registerReceiver(stateBluetoothReceiver, filter);
    }

    public void unregisterReceiver(BaseActivity context)
    {
        Log.e(TAG,"unregisterReceiver: "+context);
        context.unregisterReceiver(stateBluetoothReceiver);
    }

    public void setListener(Listener listener)
    {
        this.listeners.add(listener);
    }

    public void removeListener(Listener listener)
    {
        this.listeners.remove(listener);
    }

    private void dispatchEvent(String event, Object... args)
    {
        context.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                for(int j=0;j<listeners.size();j++) {
                    Listener listener = listeners.get(j);
                    try {
                        Class<?> params[] = new Class[args.length];
                        for (int i = 0; i < args.length; i++) {
                            params[i] = args[i].getClass();
                        }
                        Method method = Listener.class.getDeclaredMethod(event,params);
                        method.invoke(listener,args);
                    } catch (NoSuchMethodException e) {
                        e.printStackTrace();
                    } catch (IllegalAccessException e) {
                        e.printStackTrace();
                    } catch (InvocationTargetException e) {
                        e.printStackTrace();
                    }catch (RuntimeException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }

    public void destroy()
    {
        if(mGatt!=null)
        {
            mGatt.disconnect();
            mGatt.close();
        }
        /*if(adapter!=null)
        {
            adapter.disable();
        }*/
    }

    private void loadAlexaStatus()
    {
        if(!amazonLoading) {
            if(amazonQueue==null) amazonQueue = Volley.newRequestQueue(context);

            amazonLoading = true;

            final String url = String.format(ALEXA_URL, AppController.getCurrentJacket().getAmazonEmail());
            Log.e("ALEXA","URL: "+url);
            StringRequest alexaRquest = new StringRequest(Request.Method.GET, url,
                    new Response.Listener<String>() {
                        @Override
                        public void onResponse(String response) {
                            amazonLoading = false;
                            try {
                                JSONObject jsonObject = new JSONObject(response);
                                Integer status = jsonObject.has("jacketStatus") ? jsonObject.getInt("jacketStatus") : -1;
                                Log.e("JACKETSTATUS", String.valueOf(status));
                                if(isConnected() && status > -1){
                                    writeCharacteristic(JacketGattAttributes.MODE, status);
                                    writeCharacteristic(JacketGattAttributes.MODE, status);
                                }
                            } catch (JSONException e) {
                                e.printStackTrace();
                            }
                        }
                    }, new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    Log.e("ALEXA","jacketStatus error");
                    amazonLoading = false;
                }
            });
            alexaRquest.setTag("alexa");
            amazonQueue.add(alexaRquest);
        }
    }

    public void checkVoiceControl()
    {
        Boolean voiceControl = AppController.getCurrentJacket().getSetting(Jacket.VOICE_CONTROL);

        Log.e("AMAZON_EMAIL",""+AppController.getCurrentJacket().getAmazonEmail());
        if(voiceControl && !TextUtils.isEmpty(AppController.getCurrentJacket().getAmazonEmail()))
        {
            loadAlexaStatus();
        }
    }
}
