package quarky.com.br.mercuryjacket.fragment;

import android.app.Activity;
import android.app.Fragment;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.UUID;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.activity.DashBoardActivity;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.ui.dialog.Alert;
import quarky.com.br.mercuryjacket.ui.layout.SearchJacketLoader;
import quarky.com.br.mercuryjacket.ui.view.CustomTextView;

public class DisconnectedFragment extends Fragment {

    SearchJacketLoader jacket_loader;
    View look_jacket_bt;
    CustomTextView status_txt;
    Activity activity;
    Jacket jacket;

    private BluetoothController bluetoothController;
    private BluetoothController.Listener bleListener;
    private Boolean searching = false;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
        // Defines the xml file for the fragment
        return inflater.inflate(R.layout.disconnected_fragment, parent, false);
    }
    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        setup();
    }

    private void setup()
    {
        this.activity = getActivity();
        this.bluetoothController = BluetoothController.getInstance();
        this.jacket   = AppController.getCurrentJacket();

        this.jacket_loader  = activity.findViewById(R.id.jacket_loader);
        this.look_jacket_bt = activity.findViewById(R.id.look_jacket_bt);
        this.status_txt     = activity.findViewById(R.id.status_txt);

        look_jacket_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startSearch();
            }
        });


        this.bleListener = new BluetoothController.Listener() {
            @Override
            public void onAdapterConnect() {
                startSearch();
            }

            @Override
            public void onAdapterDisconnect() {
                stopSearch();
            }

            @Override
            public void onScanFound(BluetoothDevice device) {

            }

            @Override
            public void onScanNotFound() {
                notFound();
            }

            @Override
            public void onUnableBluetooth() {

            }

            @Override
            public void onDeviceConnected() {
                found();
            }

            @Override
            public void onServicesDiscovered() {

            }

            @Override
            public void onDeviceConnecting() {

            }

            @Override
            public void onDeviceDisconnected(Boolean tryReconnect) {
                if( tryReconnect ) {
                    stopSearch();
                    startSearch();
                }else {
                    notFound();
                }
            }

            @Override
            public void onUpdateCharacteristic(UUID uuid, String value) {

            }

            @Override
            public void onStartUpdate() {

            }
        };
    }

    public void startSearch()
    {
        if(!searching)
        {
            searching = true;

            if(status_txt!=null)
            {
                status_txt.setText(String.format(getResources().getString(R.string.connecting_title), jacket.getName()));
                jacket_loader.startLoader();
                look_jacket_bt.setClickable(false);
                look_jacket_bt.setAlpha(0.35f);

                Log.e("JACKET","Connecting to device "+ jacket.getId());
                bluetoothController.scanDevice(jacket.getId());
            }
        }
    }

    private void found()
    {
        if(searching){
            status_txt.setText(getResources().getString(R.string.connected));
            jacket_loader.found();
        }
    }

    private void notFound()
    {
        stopSearch();
        if(isAdded()){
            Alert alert = new Alert(activity);
            alert.yesMessage = "Reconnect";
            alert.noMessage  = "Cancel";
            alert.setActionListener(new Alert.ActionListener() {
                @Override
                public void onActionClick(int action) {
                    if(action==Alert.YES_ACTION) {
                        startSearch();
                    }
                }
            });
            String message = String.format(getResources().getString(R.string.connection_lost),jacket.getName());
            alert.show(message, Alert.ASK);
        }
    }

    private void stopSearch()
    {
        if(searching)
        {
            searching = false;
            status_txt.setText(String.format(getResources().getString(R.string.jacket_disconnected), jacket.getName()));
            jacket_loader.stopLoader();
            look_jacket_bt.setClickable(true);
            look_jacket_bt.setAlpha(1.0f);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        if(!bluetoothController.isConnected()) stopSearch();
        Log.e("DisconnectedFragment","onResume");
        bluetoothController.setListener(bleListener);
        if(BluetoothAdapter.getDefaultAdapter()!=null && !bluetoothController.isConnected())
        {
            startSearch();
        }else if(bluetoothController.isConnected()){
            DashBoardActivity.getInstance().connected();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        Log.e("DisconnectedFragment","onStop");
        bluetoothController.removeListener(bleListener);
    }

    @Override
    public void onStop() {
        super.onStop();
        if(!bluetoothController.isConnected()) stopSearch();
    }
}
