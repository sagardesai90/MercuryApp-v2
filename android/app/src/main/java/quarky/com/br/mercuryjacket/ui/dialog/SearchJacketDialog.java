package quarky.com.br.mercuryjacket.ui.dialog;

import android.app.Activity;
import android.app.Dialog;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.Window;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageView;

import java.util.Date;
import java.util.UUID;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.activity.DashBoardActivity;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.ui.layout.JacketLoaderLayout;

public class SearchJacketDialog {

    private static final int TIME_TO_START = 1500;
    EditText name_txt;
    private BluetoothDevice device;
    private Handler handle_delay;
    private Runnable runnable_delay;
    private BluetoothController bluetoothController;

    private Dialog dialog;
    private JacketLoaderLayout jacket_loader;
    private Context context;
    private BluetoothController.Listener listener;

    private Handler handlerFound;
    private Runnable runnableFound;
    private Boolean keyBoardVisible = false;

    public SearchJacketDialog(Context context)
    {
        this.context = context;

        dialog = new Dialog(context, R.style.JacketDialog);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCancelable(false);
        dialog.setContentView(R.layout.alert_search_jacket);

        ImageView close_bt = dialog.findViewById(R.id.close_bt);
        close_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                dismiss();
            }
        });

        jacket_loader = dialog.findViewById(R.id.jacket_loader);
        name_txt      = dialog.findViewById(R.id.name_txt);

        jacket_loader.setContext(context);

        name_txt.setOnKeyListener(new View.OnKeyListener() {
            public boolean onKey(View v, int keyCode, KeyEvent event) {
                if ((event.getAction() == KeyEvent.ACTION_DOWN) && (keyCode == KeyEvent.KEYCODE_ENTER)) {
                    hideKeyboard();

                    String name = name_txt.getText().toString();
                    if(name.length()<1){
                        Alert.show(context,context.getString(R.string.enter_jack_name));
                    }else{
                        saveJacket();
                    }

                    return true;
                }
                return false;
            }
        });

        bluetoothController = BluetoothController.getInstance();

        this.listener = new BluetoothController.Listener() {
            @Override
            public void onAdapterConnect() {

            }

            @Override
            public void onAdapterDisconnect() {
                dismiss();
            }

            @Override
            public void onScanFound(BluetoothDevice device) {
                found(device);
            }

            @Override
            public void onScanNotFound() {
                jacket_loader.pauseAnimation();
                Alert alert = new Alert(context);
                alert.yesMessage = "Try Again";
                alert.noMessage = "Cancel";
                alert.setActionListener(new Alert.ActionListener() {
                    @Override
                    public void onActionClick(int action) {
                        if(action==Alert.YES_ACTION) {
                            jacket_loader.resumeAnimation();
                            bluetoothController.scanDevice(null);
                        }
                        else dismiss();
                    }
                });
                String message = String.format(context.getResources().getString(R.string.no_jacket_found));
                alert.show(message, Alert.ASK);
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
            public void onDeviceDisconnected(Boolean tryeReconnect) {

            }

            @Override
            public void onUpdateCharacteristic(UUID uuid, String value) {

            }

            @Override
            public void onStartUpdate() {

            }
        };

        bluetoothController.setListener(listener);
    }

    private void saveJacket()
    {
        String id    = device!=null ? device.getAddress() : String.valueOf(new Date().getTime());
        String name  = name_txt.getText().toString();
        int hashCode = device!=null ? device.hashCode() : (int) Math.round(Math.random() * 1000000);
        Date time    = new Date();

        Jacket instance =  new Jacket(id);
        instance.setName(name);
        instance.setHashCode(hashCode);
        instance.setTime(time);
        instance.save();

        AppController.connectedTo(instance);

        confirmAdded();
    }

    private void confirmAdded()
    {
        dismiss();

        Alert alert = new Alert(context);
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                Intent intent = new Intent(context, DashBoardActivity.class);
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                context.startActivity(intent);
                ((Activity) context).finish();
            }
        });

        String message = context.getResources().getString(R.string.confirm_added);
        alert.show(message, Alert.CONFIRM);
    }

    public void show()
    {
        if( dialog!=null) {
            try{
                dialog.show();
            }catch (Exception e)
            {
                e.printStackTrace();
            }

            if(bluetoothController!=null)
            {
                handle_delay = new Handler();
                runnable_delay = new Runnable() {
                    @Override
                    public void run() {
                        bluetoothController.scanDevice(null);
                    }
                };
                handle_delay.postDelayed(runnable_delay, TIME_TO_START);
                Log.e("SCAN","START SCAN");
            }
        }
    }

    public void dismiss()
    {
        if(handlerFound!=null) handlerFound.removeCallbacks(runnableFound);
        if(handle_delay!=null) handle_delay.removeCallbacks(runnable_delay);
        if(bluetoothController!=null)
        {
            bluetoothController.removeListener(listener);
            bluetoothController.stopScan();
            Log.e("SCAN","STOP SCAN");
        }
        hideKeyboard();
        dialog.dismiss();
    }

    private void found(BluetoothDevice device)
    {
        Log.e("SEARCH_JACKET","found "+device.getName());
        this.device = device;
        jacket_loader.found(false);
        int time = 2000;
        runnableFound = new Runnable() {
            @Override
            public void run() {
                setupName();
            }
        };

        handlerFound = new Handler();
        handlerFound.postDelayed(runnableFound, time);
    }

    private void setupName()
    {
        jacket_loader.setVisibility(View.GONE);
        name_txt.setVisibility(View.VISIBLE);
        name_txt.requestFocus();
        showKeyBoard();
    }

    private void hideKeyboard()
    {
        if(keyBoardVisible)
        {
            keyBoardVisible = false;
            Log.e("KEYBOARD","hideKeyboard");
            InputMethodManager imm = (InputMethodManager) context.getSystemService(Activity.INPUT_METHOD_SERVICE);
            //imm.hideSoftInputFromWindow(name_txt.getWindowToken(), 0);
            if (imm.isAcceptingText()) imm.toggleSoftInput(InputMethodManager.HIDE_IMPLICIT_ONLY, 0);
        }
    }

    private void showKeyBoard()
    {
        if(!keyBoardVisible) {
            keyBoardVisible = true;
            Log.e("KEYBOARD", "showKeyBoard");
            InputMethodManager imm = (InputMethodManager) context.getSystemService(context.INPUT_METHOD_SERVICE);
            imm.showSoftInput(name_txt, InputMethodManager.SHOW_IMPLICIT);
        }
    }
}
