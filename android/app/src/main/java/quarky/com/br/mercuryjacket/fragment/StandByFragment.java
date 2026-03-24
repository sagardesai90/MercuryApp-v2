package quarky.com.br.mercuryjacket.fragment;

import android.app.Activity;
import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.controller.JacketGattAttributes;

public class StandByFragment extends Fragment {

    View turn_smart_bt;

    private Activity activity;
    private BluetoothController bluetoothController;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
        // Defines the xml file for the fragment
        return inflater.inflate(R.layout.stand_by_fragment, parent, false);
    }
    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        setup();
    }

    private void setup()
    {
        this.activity = getActivity();
        this.bluetoothController = BluetoothController.getInstance();
        this.turn_smart_bt = activity.findViewById(R.id.turn_smart_bt);

        turn_smart_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                bluetoothController.writeCharacteristic(JacketGattAttributes.MODE,JacketGattAttributes.SMART_MODE);
                bluetoothController.writeCharacteristic(JacketGattAttributes.MODE,JacketGattAttributes.SMART_MODE);
                //bluetoothController.readCharacteristics();
                ConnectedFragment.instance.setMode(JacketGattAttributes.SMART_MODE);
            }
        });
    }

}
