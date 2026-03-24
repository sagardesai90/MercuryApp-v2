package quarky.com.br.mercuryjacket.ui.dialog;

import android.app.Dialog;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.os.Handler;
import android.text.SpannableString;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.Window;
import android.widget.ImageView;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.model.Jacket;

public class AboutSmartModeDialog {

    private Context context;
    private Dialog dialog;

    public AboutSmartModeDialog(Context context)
    {
        this.context = context;

        dialog = new Dialog(context, R.style.JacketDialog);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCancelable(false);
        dialog.setContentView(R.layout.alert_about_smart_mode);

        ImageView close_bt = dialog.findViewById(R.id.close_bt);
        close_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                dismiss();
            }
        });
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
        }
    }

    public void dismiss()
    {
        dialog.dismiss();
    }
}
