package quarky.com.br.mercuryjacket.activity;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.WindowManager;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.AppController;

public class SplashActivity extends BaseActivity {

    Handler handle;
    Runnable runnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);

        runnable = new Runnable() {
            @Override
            public void run() {
                Intent intent = new Intent(SplashActivity.this, AppController.hasJacket() ? DashBoardActivity.class : (AppController.hasJackets() ? SettingsActivity.class : TutorialActivity.class) );
                startActivity(intent);
                finish();
            }
        };

        handle = new Handler();
        handle.postDelayed(runnable, 2000);

        getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
    }
}
