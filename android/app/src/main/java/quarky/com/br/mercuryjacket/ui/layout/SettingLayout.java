package quarky.com.br.mercuryjacket.ui.layout;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;

import androidx.annotation.Nullable;

import android.os.Handler;
import android.util.AttributeSet;
import android.util.Log;
import android.widget.CompoundButton;
import android.widget.LinearLayout;
import android.widget.Switch;
import android.widget.TextView;

import com.amazon.identity.auth.device.AuthError;
import com.amazon.identity.auth.device.api.Listener;
import com.amazon.identity.auth.device.api.authorization.AuthCancellation;
import com.amazon.identity.auth.device.api.authorization.AuthorizationManager;
import com.amazon.identity.auth.device.api.authorization.AuthorizeListener;
import com.amazon.identity.auth.device.api.authorization.AuthorizeRequest;
import com.amazon.identity.auth.device.api.authorization.AuthorizeResult;
import com.amazon.identity.auth.device.api.authorization.ProfileScope;
import com.amazon.identity.auth.device.api.workflow.RequestContext;
import com.amazon.identity.auth.device.authorization.api.AmazonAuthorizationManager;
import com.amazon.identity.auth.device.authorization.api.AuthorizationListener;
import com.amazon.identity.auth.device.shared.APIListener;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.model.Jacket;

public class SettingLayout extends LinearLayout {

    private Jacket jacket;
    private Integer key;
    private Boolean value;
    private Boolean ignoreEvent = false;
    private RequestContext requestContext;

    TextView title_txt;
    Switch switch_bt;

    public SettingLayout(Context context) {
        super(context);
    }

    public SettingLayout(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public SettingLayout(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public SettingLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        this.title_txt = findViewById(R.id.title_txt);
        this.switch_bt = findViewById(R.id.switch_bt);
        this.switch_bt.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                value = isChecked;

                if(ignoreEvent){
                    ignoreEvent = false;
                    return;
                }

                if(key==Jacket.VOICE_CONTROL){
                    if(!isChecked)
                    {
                        AuthorizationManager.signOut(getContext(), new Listener< Void, AuthError >() {
                            @Override
                            public void onSuccess(Void response) {
                                jacket.setAmazonEmail(null);
                                jacket.updateSetting(key, false);
                            }
                            @Override
                            public void onError(AuthError authError) {
                                Log.e("AMAZON", "LOGOUT ERROR");
                                switch_bt.setChecked(true);
                            }
                        });
                    }else if(requestContext!=null){
                        AuthorizationManager.authorize(new AuthorizeRequest
                                .Builder(requestContext)
                                .addScopes(ProfileScope.profile(), ProfileScope.postalCode())
                                .build());
                    }
                }else{
                    jacket.updateSetting(key, value);
                }
            }
        });
        /*this.switch_bt.setOnClickListener(new SwitchButtonLayout.Listener() {
            @Override
            public void onClick(SwitchButtonLayout view, Boolean enabled) {
                value = enabled;
                jacket.updateSetting(key, value);
            }
        });*/
    }

    public void setup(Jacket jacket, Integer key, Boolean value)
    {
        this.jacket = jacket;
        this.key    = key;
        this.value  = value;

        this.title_txt.setText(AppController.getSettingName(key));
        this.switch_bt.setChecked(value);
        //if(value) this.switch_bt.on();
        //else this.switch_bt.off();

        if(key==Jacket.VOICE_CONTROL)
        {
            requestContext = RequestContext.create(getContext());
            requestContext.registerListener(new AuthorizeListener() {

                /* Authorization was completed successfully. */
                @Override
                public void onSuccess(AuthorizeResult result) {
                    Log.e("AMAZON", "onSuccess "+result.getUser().getUserEmail());
                    jacket.setAmazonEmail(result.getUser().getUserEmail());
                    jacket.updateSetting(key, true);

                    ((Activity) getContext()).runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            ignoreEvent = true;
                            switch_bt.setChecked(true);
                        }
                    });
                }

                /* There was an error during the attempt to authorize the
                application. */
                @Override
                public void onError(AuthError ae) {
                    Log.e("AMAZON","onError");

                    ((Activity) getContext()).runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            switch_bt.setChecked(false);
                        }
                    });
                    AuthorizationManager.signOut(getContext(), new Listener< Void, AuthError >() {
                        @Override
                        public void onSuccess(Void response) {
                        }
                        @Override
                        public void onError(AuthError authError) {
                        }
                    });
                }

                /* Authorization was cancelled before it could be completed. */
                @Override
                public void onCancel(AuthCancellation cancellation) {
                    Log.e("AMAZON","onCancel");

                    ((Activity) getContext()).runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            switch_bt.setChecked(false);
                        }
                    });

                    AuthorizationManager.signOut(getContext(), new Listener< Void, AuthError >() {
                        @Override
                        public void onSuccess(Void response) {
                        }
                        @Override
                        public void onError(AuthError authError) {
                        }
                    });
                }
            });
        }
    }

    public void onResume()
    {
        Log.e("SETTINGLAYOUT","onResume");
        if(requestContext!=null) {
            requestContext.onResume();

            final Handler handler = new Handler();
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    switch_bt.setChecked(jacket.getSetting(key));
                }
            }, 200);

        }
    }
}
