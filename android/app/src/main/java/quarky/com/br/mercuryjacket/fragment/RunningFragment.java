package quarky.com.br.mercuryjacket.fragment;

import android.app.Activity;
import android.app.Fragment;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.gson.Gson;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import pl.droidsonroids.gif.GifDrawable;
import pl.droidsonroids.gif.GifImageView;
import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.activity.DashBoardActivity;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.controller.JacketGattAttributes;
import quarky.com.br.mercuryjacket.model.UserInput;
import quarky.com.br.mercuryjacket.ui.dialog.AboutSmartModeDialog;
import quarky.com.br.mercuryjacket.ui.layout.TemperatureSliderLayout;
import quarky.com.br.mercuryjacket.ui.view.CustomTextView;

public class RunningFragment extends Fragment {

    private static Boolean manualInfoRead = false;

    GifImageView circle_loader;
    GifDrawable gifFromAssets;
    GifDrawable gifFromAssets_red;
    GifDrawable gifFromAssets_green;
    TemperatureSliderLayout temperature_slider;
    CustomTextView status_txt;
    View smart_info_bt;
    ImageView smart_mode_bt;
    ImageView manual_mode_bt;
    View manual_info;
    View close_manual_info_bt;
    View debug_view;
    TextView debug_read_status_txt;
    TextView debug_write_status_txt;

    int greenColor = R.color.green1;
    int redColor   = R.color.redThree;

    Activity activity;
    BluetoothController bluetoothController;
    BluetoothController.Listener bleListener;

    private CountDownTimer learningTimer = null;
    private Boolean debug = false;
    private Boolean isSmartMode = false;
    private Boolean learning = false;
    private Boolean learned  = false;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
        // Defines the xml file for the fragment
        return inflater.inflate(R.layout.running_fragment, parent, false);
    }
    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        setup();
    }

    private void setup()
    {
        this.activity = getActivity();
        this.bluetoothController = BluetoothController.getInstance();

        this.circle_loader        = activity.findViewById(R.id.circle_loader);
        this.temperature_slider   = activity.findViewById(R.id.temperature_slider);
        this.status_txt           = activity.findViewById(R.id.status_learning);
        this.smart_info_bt        = activity.findViewById(R.id.smart_info_bt);
        this.smart_mode_bt        = activity.findViewById(R.id.smart_mode_bt);
        this.manual_mode_bt       = activity.findViewById(R.id.manual_mode_bt);
        this.manual_info          = activity.findViewById(R.id.manual_info);
        this.close_manual_info_bt = activity.findViewById(R.id.close_manual_info_bt);

        this.debug_view = activity.findViewById(R.id.debug_view);
        this.debug_read_status_txt = activity.findViewById(R.id.debug_read_status_txt);
        this.debug_write_status_txt = activity.findViewById(R.id.debug_write_status_txt);

        status_txt.setVisibility(View.INVISIBLE);
        //circle_loader.setVisibility(View.INVISIBLE);
        smart_mode_bt.setEnabled(false);
        manual_mode_bt.setEnabled(false);
        debug_view.setEnabled(false);
        debug_view.setClickable(false);
        debug_view.setVisibility(View.GONE);

        final int[] times = {0};
        circle_loader.setClickable(true);
        circle_loader.setEnabled(true);
        final CountDownTimer[] timer = {null};
        circle_loader.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                times[0]++;
                if(times[0]>=10){
                    //debugmode
                    debug = true;
                    circle_loader.setEnabled(false);
                    debug_view.setVisibility(View.VISIBLE);
                    timer[0] = new CountDownTimer(2000, 2000) {

                        public void onTick(long millisUntilFinished) {
                        }

                        public void onFinish() {
                            updateDebugStatus();
                            timer[0].start();
                        }
                    }.start();
                }
            }
        });

        boolean hasInfo = activity.getSharedPreferences(getResources().getString(R.string.app_name), 0).getBoolean("info", false);
        if(hasInfo)
        {
            ((ViewGroup) manual_info.getParent()).removeView(manual_info);
        }

        try {
            gifFromAssets_red = new GifDrawable(activity.getAssets(), "img/circle_loader_red.gif");
            gifFromAssets_red.seekToFrame(0);
            gifFromAssets_red.pause();

            gifFromAssets_green = new GifDrawable(activity.getAssets(), "img/circle_loader_green.gif");
            gifFromAssets_green.seekToFrame(0);
            gifFromAssets_green.pause();
        } catch (IOException e) {
            e.printStackTrace();
        }

        temperature_slider.setActionListener(new TemperatureSliderLayout.ActionListener() {
            @Override
            public void onUpdate(int value) {
                updateLevel(value);
                int newPowerLevel = value*1000;
                if(!isSmartMode)
                {
                    bluetoothController.writeCharacteristic(JacketGattAttributes.POWER_LEVEL, newPowerLevel);
                    updateDebugWrite(String.format("%s = %d",JacketGattAttributes.getName(JacketGattAttributes.POWER_LEVEL),newPowerLevel));
                }else{
                    startLearning(newPowerLevel);
                }
            }
        });
        smart_info_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                new AboutSmartModeDialog(activity).show();
            }
        });
        close_manual_info_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                manualInfoRead = true;
                ((ViewGroup) manual_info.getParent()).removeView(manual_info);
                close_manual_info_bt.setOnClickListener(null);
                close_manual_info_bt = null;
                manual_info = null;

                SharedPreferences.Editor edit = activity.getSharedPreferences(getResources().getString(R.string.app_name), 0).edit();
                edit.putBoolean("info",true);
                edit.commit();
            }
        });

        smart_mode_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                smartMode(true);
            }
        });
        manual_mode_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                manualMode(true);
            }
        });

        this.bleListener = new BluetoothController.Listener() {
            @Override
            public void onAdapterConnect() {

            }

            @Override
            public void onAdapterDisconnect() {

            }

            @Override
            public void onScanFound(BluetoothDevice device) {

            }

            @Override
            public void onScanNotFound() {

            }

            @Override
            public void onUnableBluetooth() {

            }

            @Override
            public void onDeviceConnected() {

            }

            @Override
            public void onServicesDiscovered() {

            }

            @Override
            public void onDeviceConnecting() {

            }

            @Override
            public void onDeviceDisconnected(Boolean tryReconnect) {

            }

            @Override
            public void onUpdateCharacteristic(UUID uuid, String value) {
                int intValue = Integer.parseInt(value);

                if(uuid.toString().equals(JacketGattAttributes.POWER_LEVEL.toString()))
                {
                    if(!learning || (learning && learned)){
                        if(learning)
                        {
                            stopLearning(false);
                        }
                        setPowerLevel(intValue);
                    }
                }else if(uuid.toString().equals(JacketGattAttributes.MODE.toString()))
                {
                    setMode(intValue);
                }
            }

            @Override
            public void onStartUpdate() {

            }
        };
    }

    private void updateDebugStatus()
    {
        if(debug)
        {
            HashMap<UUID,BluetoothGattCharacteristic> characteristics = bluetoothController.getCharacteristics();

            String text = "";

            for(Map.Entry<UUID, BluetoothGattCharacteristic> entry : characteristics.entrySet()) {
                UUID key = entry.getKey();
                BluetoothGattCharacteristic value = entry.getValue();
                text += JacketGattAttributes.getName(key)+" = "+bluetoothController.getValue(key)+"\n";
            }
            text += "**************************\n";
            String currentText = debug_read_status_txt.getText().toString();
            String oldText = (String) currentText.subSequence(0,currentText.length()>1000 ? 1000 : currentText.length());
            debug_read_status_txt.setText(text+oldText);
        }
    }

    private void updateDebugWrite(String text)
    {
        if(debug)
        {
            String currentText = debug_write_status_txt.getText().toString();
            String oldText = currentText.substring(0, currentText.length()>1000 ? 1000 : currentText.length());
            debug_write_status_txt.setText(text+"\n"+oldText);
        }
    }

    private void updateLevel(int level)
    {
        gifFromAssets.stop();
        if(level<=0)
        {
            gifFromAssets.seekToFrame(4);
        }else if(level>0 && level<4)
        {
            gifFromAssets.seekToFrame(13);
        }else if(level>=4 && level<=7){
            gifFromAssets.seekToFrame(20);
        }else if(level>7){
            gifFromAssets.seekToFrame(26);
        }
    }

    private void setPowerLevel(Integer value)
    {
        int level = Math.round(value/1000.0f);
        updateLevel(level);
        temperature_slider.setValue(level,true);
    }

    private void calculateSmartPower(Integer newPowerLevel)
    {
        UUID powerLevelUUID = JacketGattAttributes.POWER_LEVEL;
        UUID externalTemperatureUUID = JacketGattAttributes.EXTERNAL_TEMPERATURE;
        ArrayList<UserInput> arr = AppController.getUserHistoryInput();
        /*[
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 200, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 2000],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 250, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 100, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 5000],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": -210, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": -200, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 0],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 500, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 0],
         ["2973B788-15F2-4263-B412-8DA09F3F87F9": 10, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 5000]
        ]*/
        if(newPowerLevel!=null)
        {
            arr.remove(0);
            arr.add(new UserInput(newPowerLevel,bluetoothController.getValue(externalTemperatureUUID)));
            AppController.saveUserInput(newPowerLevel);
        }

        Log.e("INPUT_HISTORY", new Gson().toJson(arr));

        String tableStr = "";

        Double n = Double.valueOf(arr.size());
        Double Exy  = 0.0;
        Double Ex   = 0.0;
        Double Ey   = 0.0;
        Double xm   = 0.0;
        Double ym   = 0.0;
        Double Ex2  = 0.0;
        Double Ex_2 = 0.0;
        Double Ey2  = 0.0;

        for(UserInput input : arr)
        {
            Double x = Double.valueOf(input.externalTemperature);
            Double y = Double.valueOf(input.powerLevel);
            Exy = Exy+(x*y);
            Ex = Ex+x;
            Ey = Ey+y;
            Ex2 = Ex2+Math.pow(x, 2);
            Ey2 = Ey2+Math.pow(y, 2);

            tableStr += String.format("(%d, %d)\n",x.intValue(),y.intValue());
        }
        xm = Ex/n;
        ym = Ey/n;
        Ex_2 = Math.pow(Ex, 2);

        Double m = (n*Exy-Ex*Ey)/(n*Ex2-Ex_2);
        m = Double.isNaN(m) || m==0 ? -0.001 : m;
        Double b = ym-m*xm;

        Integer low_temp = Integer.parseInt(String.valueOf(Math.round((10000-b)/m)));
        Integer high_temp = Integer.parseInt(String.valueOf(Math.round((-b)/m)));

        //print(arr)
        Log.e("SMART","low_temp: "+ low_temp+ " high_temp: "+ high_temp+ " m: "+ m);

        bluetoothController.writeCharacteristic(JacketGattAttributes.SET_LOW_TEMP, low_temp);
        bluetoothController.writeCharacteristic(JacketGattAttributes.SET_HIGH_TEMP, high_temp);
        bluetoothController.writeCharacteristic(JacketGattAttributes.SAVE_NV_SETTINGS, 1);
        bluetoothController.readCharacteristic(JacketGattAttributes.POWER_LEVEL);
        updateDebugWrite("*******************");
        updateDebugWrite(String.format("%s = %d",JacketGattAttributes.getName(JacketGattAttributes.SET_LOW_TEMP),low_temp));
        updateDebugWrite(String.format("%s = %d",JacketGattAttributes.getName(JacketGattAttributes.SET_HIGH_TEMP),high_temp));
        updateDebugWrite(String.format("%s = %d",JacketGattAttributes.getName(JacketGattAttributes.SAVE_NV_SETTINGS),1));

        updateDebugWrite("high_temp = -b/m");
        updateDebugWrite("low_temp = (10000-b)/m");
        updateDebugWrite("b = "+b);
        updateDebugWrite("m = "+m);
        updateDebugWrite(tableStr);
        updateDebugWrite("*******************");

        learned = true;
    }

    private void startLearning(Integer newPowerLevel)
    {
        learning = true;
        //self.status_txt.text = "Mercury is learning..."
        status_txt.setVisibility(View.VISIBLE);
        gifFromAssets.start();

        if(learningTimer!=null)
        {
            learningTimer.cancel();
            learningTimer = null;
        }
        learningTimer = new CountDownTimer(2000, 2000) {

            public void onTick(long millisUntilFinished) {
            }

            public void onFinish() {
                calculateSmartPower(newPowerLevel);
            }
        }.start();
    }

    private void stopLearning(Boolean stopAnimation)
    {
        learning = false;
        learned = false;
        status_txt.setVisibility(View.INVISIBLE);
        if(stopAnimation)
        {
            if(gifFromAssets!=null) gifFromAssets.pause();
        }
        if(learningTimer!=null){
            learningTimer.cancel();
            learningTimer = null;
        }
    }

    private void setMode(int value)
    {
        switch(value){
            case JacketGattAttributes.MANUAL_MODE:
                manualMode(false);
                break;
            case JacketGattAttributes.SMART_MODE:
                smartMode(false);
                break;
                default:
                    smartMode(false);
        }
    }

    public void smartMode(Boolean update)
    {
        isSmartMode = true;

        gifFromAssets = gifFromAssets_green;
        circle_loader.setImageDrawable(gifFromAssets);

        stopLearning(true);
        smart_mode_bt.setEnabled(false);
        manual_mode_bt.setEnabled(true);
        smart_info_bt.setVisibility(View.VISIBLE);

        smart_mode_bt.setImageResource(R.drawable.smart_bt_active);
        manual_mode_bt.setImageResource(R.drawable.manual_bt_inactive);
        temperature_slider.setColor(greenColor);
        if(manual_info!=null) manual_info.setVisibility(View.GONE);

        bluetoothController.readCharacteristic(JacketGattAttributes.POWER_LEVEL);

        if(update) {
            bluetoothController.writeCharacteristic(JacketGattAttributes.MODE,JacketGattAttributes.SMART_MODE);
            bluetoothController.writeCharacteristic(JacketGattAttributes.MODE,JacketGattAttributes.SMART_MODE);
            updateDebugWrite(String.format("%s = %d",JacketGattAttributes.getName(JacketGattAttributes.MODE),JacketGattAttributes.SMART_MODE));
        }else{
            calculateSmartPower(null);
        }
    }

    public void manualMode(Boolean update)
    {
        isSmartMode = false;

        gifFromAssets = gifFromAssets_red;
        circle_loader.setImageDrawable(gifFromAssets);

        stopLearning(true);
        smart_mode_bt.setEnabled(true);
        manual_mode_bt.setEnabled(false);
        smart_info_bt.setVisibility(View.GONE);

        smart_mode_bt.setImageResource(R.drawable.smart_bt_inactive);
        manual_mode_bt.setImageResource(R.drawable.manual_bt_active);
        temperature_slider.setColor(redColor);
        if(!manualInfoRead) manual_info.setVisibility(View.VISIBLE);

        bluetoothController.readCharacteristic(JacketGattAttributes.POWER_LEVEL);

        if(update)
        {
            bluetoothController.writeCharacteristic(JacketGattAttributes.MODE,JacketGattAttributes.MANUAL_MODE);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        if(bluetoothController!=null && bleListener!=null) bluetoothController.setListener(bleListener);

        if(bluetoothController.isConnected())
        {
            bluetoothController.readCharacteristic(JacketGattAttributes.MODE);
            bluetoothController.readCharacteristic(JacketGattAttributes.POWER_LEVEL);

            setMode(bluetoothController.getValue(JacketGattAttributes.MODE));
            setPowerLevel(bluetoothController.getValue(JacketGattAttributes.POWER_LEVEL));
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        stopLearning(true);
        if(bluetoothController!=null && bleListener!=null) bluetoothController.removeListener(bleListener);
    }
}
