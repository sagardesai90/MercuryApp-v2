package quarky.com.br.mercuryjacket.ui.dialog;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.text.SpannableStringBuilder;
import android.view.View;
import android.view.Window;
import android.widget.TextView;

import quarky.com.br.mercuryjacket.R;

/**
 * Created by andreluisponce on 26/12/17.
 */

public class Alert {
    public static final int CONFIRM = 0;
    public static final int ASK = 1;
    public static final int WAIT = 2;

    public static final int CONFIRM_ACTION = 0;
    public static final int YES_ACTION = 1;
    public static final int NO_ACTION = 2;

    public String confirmMessage = "Continue";
    public String yesMessage = "Yes";
    public String noMessage = "No";

    private Context context;
    private ActionListener listener;
    private Dialog dialog;

    public static Alert INSTANCE;

    public Alert(Context context)
    {
        if(INSTANCE!=null) INSTANCE.dismiss();
        INSTANCE = this;
        this.listener = null;
        this.context = context;
    }

    public static Alert show(Context context, String message)
    {
        Alert alert = new Alert(context);
        alert.show(message,Alert.CONFIRM);
        return alert;
    }

    public Dialog show(String message, int ask) {
        SpannableStringBuilder newMessage = new SpannableStringBuilder();
        newMessage.append(message);
        return show(newMessage,ask);
    }

    public interface ActionListener {
        public void onActionClick(int action);
    }

    public void setActionListener(ActionListener listener) {
        this.listener = listener;
    }

    public Dialog show(final SpannableStringBuilder message, final int type)
    {
        Activity activity = (Activity) context;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                dialog = new Dialog(context, R.style.NewDialog);
                dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
                dialog.setCancelable(false);
                dialog.setContentView(R.layout.alert);

                View buttons_container = dialog.findViewById(R.id.buttons_container);
                View bt_ok             = dialog.findViewById(R.id.bt_ok);
                View bts_question      = dialog.findViewById(R.id.bts_question);
                View bt_yes            = dialog.findViewById(R.id.bt_yes);
                View bt_no             = dialog.findViewById(R.id.bt_no);

                switch(type)
                {
                    case CONFIRM:
                        buttons_container.setVisibility(View.VISIBLE);
                        bt_ok.setVisibility(View.VISIBLE);
                        bts_question.setVisibility(View.GONE);
                        break;
                    case ASK:
                        buttons_container.setVisibility(View.VISIBLE);
                        bt_ok.setVisibility(View.GONE);
                        bts_question.setVisibility(View.VISIBLE);
                        break;
                    case WAIT:
                        buttons_container.setVisibility(View.GONE);
                        break;
                }


                TextView txt_ok = bt_ok.findViewById(R.id.label_txt);
                TextView txt_yes = bt_yes.findViewById(R.id.label_txt);
                TextView txt_no = bt_no.findViewById(R.id.label_txt);
                TextView message_txt = (TextView) dialog.findViewById(R.id.message_txt);

                message_txt.setText(message);
                txt_ok.setText(confirmMessage);
                txt_yes.setText(yesMessage);
                txt_no.setText(noMessage);

                bt_ok.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        actionHandle(CONFIRM_ACTION);
                    }
                });

                bt_yes.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        actionHandle(YES_ACTION);
                    }
                });

                bt_no.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        actionHandle(NO_ACTION);
                    }
                });
            }
        });

        try {
            if(dialog!=null) {
                dialog.dismiss();
                dialog.show();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return dialog;
    }

    private void actionHandle(int action)
    {
        dismiss();
        try {
            listener.onActionClick(action);
            listener = null;
        }catch(NullPointerException e){

        }
    }

    public void dismiss()
    {
        dialog.dismiss();
        INSTANCE = null;
    }
}
