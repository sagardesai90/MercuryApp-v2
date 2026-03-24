package quarky.com.br.mercuryjacket.ui.layout;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.util.LinkedHashMap;
import java.util.Map;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.activity.DashBoardActivity;
import quarky.com.br.mercuryjacket.activity.TutorialActivity;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.ui.dialog.Alert;

public class SettingsLayout extends LinearLayout implements View.OnClickListener {

    private Jacket jacket;
    private TextView name_txt;
    private LinearLayout options;
    private View bt_delete;
    private View bt_disconnect;
    private View bt_connect;
    private RelativeLayout title_bt;
    private RelativeLayout arrow;

    private Boolean active = true;

    public SettingsLayout(Context context) {
        super(context);
    }

    public SettingsLayout(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public SettingsLayout(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public SettingsLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    public void setup(final Jacket jacket)
    {
        this.jacket = jacket;

        this.bt_disconnect.setVisibility(GONE);

        if(AppController.getCurrentJacket()!=null && jacket.getId().equals(AppController.getCurrentJacket().getId())){
            this.bt_connect.setVisibility(GONE);
            this.title_bt.setBackgroundColor(ContextCompat.getColor(getContext(), R.color.greyTwo));
            on();
        }/*else{
            this.bt_disconnect.setVisibility(GONE);
        }*/

        name_txt.setText(jacket.getName());

        LinkedHashMap<Integer, Boolean> settings = jacket.getSettings();
        if(settings!=null)
        {
            for(Map.Entry<Integer, Boolean> entry : settings.entrySet()) {
                Integer key = entry.getKey();
                Boolean value = entry.getValue();

                if(key==Jacket.DEBUG) continue;

                SettingLayout setting = (SettingLayout) ((Activity) getContext()).getLayoutInflater().inflate(R.layout.setting_line, null);
                setting.setup(jacket,key,value);
                options.addView(setting,0);
            }
        }

        ((TextView) bt_disconnect.findViewById(R.id.label_txt)).setText(String.format(getResources().getString(R.string.disconnect),jacket.getName()));
        ((TextView) bt_delete.findViewById(R.id.label_txt)).setText(String.format(getResources().getString(R.string.delete),jacket.getName()));
        ((TextView) bt_connect.findViewById(R.id.label_txt)).setText(String.format(getResources().getString(R.string.connect),jacket.getName()));
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        this.name_txt   = findViewById(R.id.name_txt);
        this.options    = findViewById(R.id.options);
        this.bt_delete  = findViewById(R.id.bt_delete);
        this.bt_disconnect  = findViewById(R.id.bt_disconnect);
        this.bt_connect = findViewById(R.id.bt_connect);
        this.title_bt   = findViewById(R.id.title_bt);
        this.arrow      = findViewById(R.id.arrow);

        bt_delete.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                askDelete();
            }
        });
        bt_disconnect.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                askDisconnect();
            }
        });
        bt_connect.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                askConnect();
            }
        });
        title_bt.setOnClickListener(this);

        off();
    }

    private void askDelete()
    {
        Alert alert = new Alert(getContext());
        alert.yesMessage = getContext().getResources().getString(R.string. delete_yes);
        alert.noMessage = getContext().getResources().getString(R.string.delete_no);
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                if(action==Alert.NO_ACTION){
                    BluetoothController.getInstance().stopConnection();
                    jacket.delete();
                    ((ViewGroup) getParent()).removeView(SettingsLayout.this);
                    if(AppController.getCurrentJacket()==null && DashBoardActivity.getInstance()!=null) DashBoardActivity.getInstance().finish();
                    confirmDelete();
                }
            }
        });


        String message = String.format(getContext().getResources().getString(R.string.ask_delete),jacket.getName());
        alert.show(message, Alert.ASK);
    }

    private void askDisconnect()
    {
        Alert alert = new Alert(getContext());
        alert.yesMessage = getContext().getResources().getString(R.string. delete_yes);
        alert.noMessage = getContext().getResources().getString(R.string.disconnect_no);
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                if(action==Alert.NO_ACTION){
                    BluetoothController.getInstance().stopConnection();
                    BluetoothController.getInstance().destroy();
                    AppController.connectedTo(null);
                    SettingsLayout.this.bt_disconnect.setVisibility(GONE);
                    SettingsLayout.this.bt_connect.setVisibility(VISIBLE);
                    SettingsLayout.this.title_bt.setBackgroundColor(0);

                    if(DashBoardActivity.getInstance()!=null) DashBoardActivity.getInstance().finish();

                    String message = String.format(getContext().getResources().getString(R.string.confirm_disconnect),jacket.getName());
                    Alert.show(getContext(),message);
                }
            }
        });

        String message = String.format(getContext().getResources().getString(R.string.ask_disconnect),jacket.getName());
        alert.show(message, Alert.ASK);
    }

    private void confirmDelete()
    {
        Alert alert = new Alert(getContext());
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                if(!AppController.hasJackets()){
                    Intent intent = new Intent(getContext(), TutorialActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    ((Activity) getContext()).startActivity(intent);
                }
            }
        });

        String message = String.format(getContext().getResources().getString(R.string.confirm_delete),jacket.getName());
        alert.show(message, Alert.CONFIRM);
    }

    private void askConnect()
    {
        Alert alert = new Alert(getContext());
        alert.setActionListener(new Alert.ActionListener() {
            @Override
            public void onActionClick(int action) {
                if(action==Alert.YES_ACTION){
                    BluetoothController.getInstance().stopConnection();
                    AppController.connectedTo(jacket);

                    Intent intent = new Intent(getContext(), DashBoardActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    ((Activity) getContext()).startActivity(intent);
                }
            }
        });

        String message = String.format(getContext().getResources().getString(R.string.ask_connect),jacket.getName());
        alert.show(message, Alert.ASK);
    }

    public void on()
    {
        active = true;
        options.setVisibility(VISIBLE);
        arrow.setBackgroundResource(R.drawable.ic_arrow_up);

        /*ValueAnimator widthAnimator = ValueAnimator.ofInt(view.getWidth(), newWidth);
        widthAnimator.setDuration(500);
        widthAnimator.setInterpolator(new DecelerateInterpolator());
        widthAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
            @Override
            public void onAnimationUpdate(ValueAnimator animation) {
                view.getLayoutParams().width = (int) animation.getAnimatedValue();
                view.requestLayout();
            }
        });
        widthAnimator.start();*/
        //int parentWidth = ((View)view.getParent()).getMeasuredWidth();
    }

    public void off()
    {
        active = false;
        options.setVisibility(GONE);
        arrow.setBackgroundResource(R.drawable.ic_arrow_down);
    }

    @Override
    public void onClick(View view) {
        if(active) off();
        else on();
    }

    public void onResume()
    {
        for(int i=0;i<options.getChildCount();i++)
        {
            View child = options.getChildAt(i);
            if(child instanceof SettingLayout) ((SettingLayout) child).onResume();
        }
    }
}