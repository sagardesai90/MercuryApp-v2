package quarky.com.br.mercuryjacket.ui.layout;

import android.animation.ValueAnimator;
import android.content.Context;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.core.content.ContextCompat;
import androidx.interpolator.view.animation.LinearOutSlowInInterpolator;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;

import quarky.com.br.mercuryjacket.R;

public class TemperatureSliderLayout extends ConstraintLayout {

    View bar;
    ImageView bar_image;
    ActionListener listener;
    private int value = 0;

    public interface ActionListener {
        public void onUpdate(int value);
    }

    public TemperatureSliderLayout(Context context) {
        super(context);
    }

    public TemperatureSliderLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public TemperatureSliderLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        View temperature_slider = findViewById(R.id.temperature_slider);
        bar = findViewById(R.id.bar);
        bar_image = findViewById(R.id.bar_image);

        temperature_slider.setOnTouchListener(new OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {

                final float height = view.getHeight();

                float dy = 0;
                dy =  motionEvent.getY();
                dy = Math.max(0,Math.min(dy,height));

                float pct = dy / height;

                int value = Math.abs(Math.round(pct*10)-10);

                /*Log.e("onTouch", "dy: "+dy);
                Log.e("onTouch", "pct: "+pct);
                Log.e("onTouch", "value: "+value);*/

                if(TemperatureSliderLayout.this.value!=value) listener.onUpdate(value);
                setValue(value, false);

                return true;
            }
        });
    }

    public void setActionListener(ActionListener listener)
    {
        this.listener = listener;
    }

    ValueAnimator animation;

    public void setValue(int value, Boolean animate)
    {
        this.value = value;
        final LinearLayout.LayoutParams layoutParams = (LinearLayout.LayoutParams) bar.getLayoutParams();

        if(animation!=null)
        {
            animation.pause();
            animation.cancel();
            animation = null;
        }
        if(animate)
        {
            animation = ValueAnimator.ofFloat(layoutParams.weight, 9.8f*value); //fromWeight, toWeight
            animation.setDuration(700);
            animation.setInterpolator(new LinearOutSlowInInterpolator());
            animation.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
                @Override
                public void onAnimationUpdate(ValueAnimator animation) {
                    layoutParams.weight = (float) animation.getAnimatedValue();
                    bar.requestLayout();
                }

            });
            animation.start();
        }else{
            layoutParams.weight = 9.8f*value;
        }

        bar.setLayoutParams(layoutParams);
    }

    public void setColor(int color)
    {
        if(animation!=null)
        {
            animation.pause();
            animation.cancel();
            animation = null;
        }
        bar_image.setColorFilter(ContextCompat.getColor(getContext(), color));
    }
}
