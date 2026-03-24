package quarky.com.br.mercuryjacket.activity;

import android.annotation.SuppressLint;
import android.app.Fragment;
import android.bluetooth.BluetoothDevice;
import android.os.Bundle;
import android.transition.Slide;
import android.util.Log;
import android.view.Gravity;
import android.view.View;

import java.util.UUID;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.controller.JacketGattAttributes;
import quarky.com.br.mercuryjacket.fragment.ConnectedFragment;
import quarky.com.br.mercuryjacket.fragment.DisconnectedFragment;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.ui.dialog.Alert;
import quarky.com.br.mercuryjacket.ui.layout.ActionBarLayout;

public class DashBoardActivity extends BaseActivity {

    public final static String TAG = "dashboard";//DashBoardActivity.class.getSimpleName();

    private static DashBoardActivity instance;

    private Jacket jacket;

    ActionBarLayout actionbar;
    Fragment currentFragment;
    ConnectedFragment connected_fragment;
    DisconnectedFragment disconnected_fragment;

    private BluetoothController bluetoothController;
    private BluetoothController.Listener bleListener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dash_board);

        instance = this;

        this.actionbar = (ActionBarLayout) getActionBar().getCustomView();

        this.connected_fragment    = new ConnectedFragment();
        this.disconnected_fragment = new DisconnectedFragment();

        this.bluetoothController = BluetoothController.getInstance();
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
                bluetoothController.writeCharacteristic(JacketGattAttributes.MOTION_TEMP,jacket.getSetting(Jacket.MOTION_CONTROL)?1:0);
            }

            @Override
            public void onDeviceConnecting() {

            }

            @Override
            public void onDeviceDisconnected(Boolean tryReconnect) {
                setFragment(disconnected_fragment);
            }

            @Override
            public void onUpdateCharacteristic(UUID uuid, String value) {
                int intValue = Integer.parseInt(value);

                if(uuid.toString().equals(JacketGattAttributes.MODE.toString()))
                {
                    intValue = Math.min(intValue,4);

                    Log.e(TAG,"DASHBOARD: MODE="+intValue);

                    if(intValue==0) {
                        bluetoothController.readCharacteristic(JacketGattAttributes.MODE);
                    }else{
                        setFragment(connected_fragment);
                    }
                }else if(uuid.toString().equals(JacketGattAttributes.EXTERNAL_TEMPERATURE.toString()))
                {
                    actionbar.update();
                }
            }

            @Override
            public void onStartUpdate() {

            }
        };
    }

    public static DashBoardActivity getInstance()
    {
        return instance;
    }

    @SuppressLint("ResourceType")
    public void setFragment(Fragment fragment)
    {
        if(this.currentFragment!=fragment)
        {
            this.currentFragment = fragment;

            //fragment.setRetainInstance(true);
            //fragment.setEnterTransition(new Slide(Gravity.RIGHT));
            //fragment.setExitTransition(new Slide(Gravity.LEFT));

            try{
                getFragmentManager()
                        .beginTransaction()
                        .setCustomAnimations(R.anim.slide_from_right,R.anim.slide_to_left)
                        .replace(R.id.fragment_container, fragment, "h")
                        .commit();
            }catch (Exception e)
            {

            }
        }
    }

    public void connected()
    {
        setFragment(connected_fragment);
    }

    @Override
    protected void onResume() {
        super.onResume();
        this.jacket = AppController.getCurrentJacket();
        actionbar.resume();
        this.bluetoothController.setListener(bleListener);
        if(currentFragment==null || (currentFragment!=null && !bluetoothController.isConnected()))
        {
            setFragment(disconnected_fragment);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        actionbar.pause();
        this.bluetoothController.removeListener(bleListener);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        instance = null;
    }
}
