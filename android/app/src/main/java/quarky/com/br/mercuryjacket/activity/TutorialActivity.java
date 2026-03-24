package quarky.com.br.mercuryjacket.activity;

import android.content.Intent;
import android.os.Bundle;
import androidx.core.content.ContextCompat;
import androidx.viewpager.widget.ViewPager;

import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.adapter.PageAdapter;

public class TutorialActivity extends BaseActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_tutorial);

        /*Alert alert = new Alert(this);
        alert.confirmMessage = "Continue";
        alert.yesMessage = "Cancel";
        alert.noMessage = "Disconnect";
        alert.show("Are you sure you would like to disconnect “Name’s Jacket” from the app?",Alert.CONFIRM);*/
        View close_bt = findViewById(R.id.close_bt);

        Intent intent = getIntent();
        close_bt.setVisibility(intent.getBooleanExtra("back",false) ? View.VISIBLE : View.GONE);

        setupSlider();
    }

    private int dotscount;
    private ImageView[] dots;

    private void setupSlider()
    {
        final ViewPager slider = findViewById(R.id.slider);
        final LinearLayout slider_dots = findViewById(R.id.slider_dots);

        int[] layouts = { R.layout.tutorial_page_1, R.layout.tutorial_page_2, R.layout.tutorial_page_3, R.layout.tutorial_page_4, R.layout.tutorial_page_5 };

        PageAdapter pageAdapter = new PageAdapter(this, layouts);
        slider.setAdapter(pageAdapter);

        dotscount   = pageAdapter.getCount();
        dots        = new ImageView[dotscount];

        for(int i = 0; i < dotscount; i++){

            ImageView dot = new ImageView(this);
            dot.setImageDrawable(ContextCompat.getDrawable(getApplicationContext(), R.drawable.dot_not_active));

            dots[i] = dot;

            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            params.setMargins(10, 0, 10, 0);
            slider_dots.addView(dots[i], params);
        }

        dots[0].setImageDrawable(ContextCompat.getDrawable(getApplicationContext(), R.drawable.dot_active));

        slider.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
                for(int i = 0; i< dotscount; i++){
                    dots[i].setImageDrawable(ContextCompat.getDrawable(getApplicationContext(), R.drawable.dot_not_active));
                }

                dots[position].setImageDrawable(ContextCompat.getDrawable(getApplicationContext(), R.drawable.dot_active));
            }

            @Override
            public void onPageSelected(int position) {

            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        //getWindow().setStatusBarColor(ContextCompat.getColor(this,R.color.darkgrey));
    }
}
