package quarky.com.br.mercuryjacket.activity;

import android.Manifest;
import android.app.ActionBar;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.text.SpannableStringBuilder;

import java.util.UUID;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.ui.dialog.Alert;
import quarky.com.br.mercuryjacket.ui.layout.ActionBarLayout;

public class BaseActivity extends Activity {
    private static int STACK_COUNT = 0;

    private static final int REQUEST_ENABLE_BLUETOOTH = 99;
    private static final int PERMISSIONS_REQUEST_ACCESS_COARSE_LOCATION = 100;
    private static final int REQUEST_PERMISSION_SETTING = 101;

    protected BluetoothController bluetoothController;
    private Alert alert;

    ActionBar actionBar;
    protected ActionBarLayout actionBarView;

    BluetoothController.Listener bleListener;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);

        actionBar = getActionBar();
        if(actionBar!=null)
        {
            actionBar.setBackgroundDrawable(new ColorDrawable(getResources().getColor(R.color.darkgrey)));
            actionBar.setDisplayOptions(ActionBar.DISPLAY_SHOW_CUSTOM);
            actionBar.setDisplayShowCustomEnabled(true);
            actionBar.setCustomView(R.layout.actionbar);
            actionBarView = (ActionBarLayout) actionBar.getCustomView();
        }

        STACK_COUNT++;

        if(!(this instanceof SplashActivity)) {
            this.bleListener = new BluetoothController.Listener() {
                @Override
                public void onAdapterConnect() {
                    BaseActivity.this.onAdapterConnect();
                }

                @Override
                public void onAdapterDisconnect() {
                    BaseActivity.this.onAdapterDisconnect();
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

                }

                @Override
                public void onStartUpdate() {

                }
            };


            checkBluetooth();
        }
    }

    protected void onAdapterConnect()
    {
        if(alert!=null) {
            alert.dismiss();
            alert = null;
        }
    }

    protected void onAdapterDisconnect()
    {
        askBluetooth();
    }

    @Override
    protected void onResume() {
        super.onResume();
        bluetoothController = BluetoothController.getInstance();
        bluetoothController.registerReceiver(this);
        bluetoothController.setListener(bleListener);
        String className = this.getClass().getSimpleName();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if(bluetoothController!=null) {
            bluetoothController.unregisterReceiver(this);
            bluetoothController.removeListener(bleListener);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        STACK_COUNT--;
    }

    protected  void checkBluetooth()
    {
        if(BluetoothAdapter.getDefaultAdapter()==null)
        {
            noAdapter();
        }else{
            if (!BluetoothAdapter.getDefaultAdapter().isEnabled()) {
                Intent enableIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                startActivityForResult(enableIntent, REQUEST_ENABLE_BLUETOOTH);
            }else checkLocation();
        }
    }

    private void noAdapter()
    {
        alert = new Alert(this);
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                finish();
            }
        });
        String message = String.format(getResources().getString(R.string.bluetooth_required));
        alert.show(message, Alert.CONFIRM);
    }

    protected void checkLocation()
    {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.ACCESS_COARSE_LOCATION},
                    PERMISSIONS_REQUEST_ACCESS_COARSE_LOCATION);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions,
                                           int[] grantResults) {
        if (requestCode == PERMISSIONS_REQUEST_ACCESS_COARSE_LOCATION) {
            if(grantResults==null || grantResults[0] != PackageManager.PERMISSION_GRANTED){
                if (!ActivityCompat.shouldShowRequestPermissionRationale(this,Manifest.permission.ACCESS_COARSE_LOCATION)) {

                    Alert alert = new Alert(this);
                    alert.setActionListener(new Alert.ActionListener() {
                        @Override
                        public void onActionClick(int action) {
                            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                            Uri uri = Uri.fromParts("package", getPackageName(), null);
                            intent.setData(uri);
                            startActivityForResult(intent, REQUEST_PERMISSION_SETTING);
                        }
                    });
                    String message = String.format(getResources().getString(R.string.location_blocked));
                    alert.show(message, Alert.CONFIRM);

                }else askLocation();
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if(requestCode == REQUEST_ENABLE_BLUETOOTH)
        {
            if(resultCode == RESULT_OK){
                // bluetooth enabled
                checkLocation();
            }else askBluetooth();
        }else if(requestCode == REQUEST_PERMISSION_SETTING) checkLocation();
    }

    @Override
    public void onBackPressed() {
        //super.onBackPressed();

        if(STACK_COUNT==1) {
            askQuit();
        }else finish();
    }

    protected void askBluetooth()
    {
        alert = new Alert(this);
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                if(action==Alert.YES_ACTION) checkBluetooth();
                else finish();
                alert = null;
            }
        });
        String message = String.format(getResources().getString(R.string.bluetooth_request));
        alert.show(message, Alert.ASK);
    }

    protected void askLocation()
    {
        Alert alert = new Alert(this);
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                if(action==Alert.YES_ACTION) checkLocation();
                else finish();
            }
        });
        String message = String.format(getResources().getString(R.string.location_request));
        alert.show(message, Alert.ASK);
    }

    public void askQuit()
    {
        Alert alert = new Alert(this);
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                if(action==Alert.YES_ACTION) {
                    finish();
                }else {
                }
            }
        });
        SpannableStringBuilder message = new SpannableStringBuilder();
        message.append(String.format(getResources().getString(R.string.quit_message)));

        alert.show(message, Alert.ASK);
    }
}
