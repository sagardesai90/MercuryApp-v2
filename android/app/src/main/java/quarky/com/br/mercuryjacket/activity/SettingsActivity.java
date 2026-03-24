package quarky.com.br.mercuryjacket.activity;

import android.content.Intent;
import android.os.Bundle;
import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;

import java.util.ArrayList;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.model.Jacket;
import quarky.com.br.mercuryjacket.ui.dialog.SearchJacketDialog;
import quarky.com.br.mercuryjacket.ui.layout.SettingsLayout;

public class SettingsActivity extends BaseActivity {

    ViewGroup jackets_container;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        jackets_container = findViewById(R.id.jackets_container);

        View add_bt = findViewById(R.id.add_bt);
        View intro_bt = findViewById(R.id.intro_bt);

        add_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                final SearchJacketDialog searchJacketDialog = new SearchJacketDialog(SettingsActivity.this);
                searchJacketDialog.show();
            }
        });

        intro_bt.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(SettingsActivity.this,TutorialActivity.class);
                i.putExtra("back",true);
                SettingsActivity.this.startActivity(i);
            }
        });


        setup();
    }

    private void setup()
    {
        //Jacket seila = AppController.getCurrentJacket();
        ArrayList<Jacket> jackets = AppController.getJacketsList();

        for(int i=0;i<jackets.size();i++){
            Jacket jacket = jackets.get(i);
            SettingsLayout child = (SettingsLayout) getLayoutInflater().inflate(R.layout.settings_jacket, null);
            child.setup(jacket);
            jackets_container.addView(child);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        for(int i=0;i<jackets_container.getChildCount();i++)
        {
            SettingsLayout child = (SettingsLayout) jackets_container.getChildAt(i);
            child.onResume();
        }
    }
}
