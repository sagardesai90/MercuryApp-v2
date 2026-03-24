package quarky.com.br.mercuryjacket.fragment;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Fragment;
import android.bluetooth.BluetoothDevice;
import android.os.Bundle;

import androidx.annotation.Nullable;
import android.transition.Slide;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import java.util.UUID;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.controller.JacketGattAttributes;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.ui.view.CustomTextView;

public class ConnectedFragment extends Fragment {

    public static ConnectedFragment instance;

    View motion_info;
    CustomTextView motion_info_txt;
    ImageView ic_motion;

    Fragment currentFragment;
    public RunningFragment running_fragment;
    public StandByFragment standby_fragment;

    private Activity activity;
    private Jacket jacket;
    private BluetoothController bluetoothController;
    private BluetoothController.Listener bleListener;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
        // Defines the xml file for the fragment
        return inflater.inflate(R.layout.connected_fragment, parent, false);
    }
    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        setup();
    }

    private void setup()
    {
        instance = this;

        this.activity = getActivity();
        this.motion_info = activity.findViewById(R.id.motion_info);
        this.bluetoothController = BluetoothController.getInstance();

        this.motion_info_txt = motion_info.findViewById(R.id.motion_info_txt);
        this.ic_motion = motion_info.findViewById(R.id.ic_motion);

        this.running_fragment = new RunningFragment();
        this.standby_fragment = new StandByFragment();

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

                if(uuid.toString().equals(JacketGattAttributes.MODE.toString()))
                {
                    Log.e("CONNECTED", "MODE = "+intValue);
                    setMode(intValue);
                }else if(uuid.toString().equals(JacketGattAttributes.ACTIVITY_LEVEL.toString()))
                {
                    setActivityLevel(intValue);
                }
            }

            @Override
            public void onStartUpdate() {

            }
        };
    }

    private void setActivityLevel(Integer value)
    {
        String text = getResources().getString(R.string.motion_sensor);

        if(value==0)
        {
            motion_info_txt.setText(String.format(text,"Static"));
            ic_motion.setImageResource(R.drawable.ic_static);
        }else{
            motion_info_txt.setText(String.format(text,"Moving"));
            ic_motion.setImageResource(R.drawable.ic_moving);
        }
    }

    public void setMode(int mode)
    {
        switch(mode){
            case JacketGattAttributes.PRE_MODE:
            case JacketGattAttributes.STANDBY_MODE:
                setFragment(standby_fragment);
                break;
            case JacketGattAttributes.MANUAL_MODE:
                setFragment(running_fragment);
                break;
            case JacketGattAttributes.SMART_MODE:
                setFragment(running_fragment);
                break;
        }
    }

    @SuppressLint("ResourceType")
    private void setFragment(Fragment fragment)
    {
        if(this.currentFragment!=fragment)
        {
            this.currentFragment = fragment;

            //fragment.setRetainInstance(true);
            //fragment.setEnterTransition(new Slide(Gravity.RIGHT));
            //fragment.setExitTransition(new Slide(Gravity.LEFT));

            try {
                getChildFragmentManager()
                        .beginTransaction()
                        .setCustomAnimations(R.anim.slide_from_right,R.anim.slide_to_left)
                        .replace(R.id.connected_fragment_container, fragment, "h2")
                        .commit();
            }catch(Exception e)
            {

            }

        }
    }

    @Override
    public void onResume() {
        this.jacket = AppController.getCurrentJacket();

        super.onResume();
        bluetoothController.setListener(bleListener);
        setMode(bluetoothController.getValue(JacketGattAttributes.MODE));
        setActivityLevel(bluetoothController.getValue(JacketGattAttributes.ACTIVITY_LEVEL));
    }

    @Override
    public void onPause() {
        super.onPause();
        bluetoothController.removeListener(bleListener);
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        Log.e("ASUHSAUHSA","onSaveInstanceState");
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        Log.e("ASUHSAUHSA","onActivityCreated");
    }
}
