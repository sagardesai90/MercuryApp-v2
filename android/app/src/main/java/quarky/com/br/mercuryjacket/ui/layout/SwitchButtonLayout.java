package quarky.com.br.mercuryjacket.ui.layout;

import android.content.Context;
import androidx.core.content.ContextCompat;
import android.util.AttributeSet;
import android.view.View;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import quarky.com.br.mercuryjacket.R;

public class SwitchButtonLayout extends RelativeLayout implements View.OnClickListener {

    private ImageView drag;
    public int colorOn = R.color.redThree;
    public int colorOff = R.color.greyTwo;
    private Boolean enabled = false;

    protected Listener listener;

    public interface Listener {
        public void onClick(SwitchButtonLayout view, Boolean enabled);
    }

    public void setOnClickListener(Listener listener)
    {
        this.listener = listener;
    }

    public SwitchButtonLayout(Context context) {
        super(context);
    }

    public SwitchButtonLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public SwitchButtonLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public SwitchButtonLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();
        //this.drag    = findViewById(R.id.drag);
        setOnClickListener(this);
        off();
    }

    public void on()
    {
        this.enabled = true;
        RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams)drag.getLayoutParams();
        params.removeRule(RelativeLayout.ALIGN_PARENT_LEFT);
        params.addRule(RelativeLayout.ALIGN_PARENT_RIGHT, RelativeLayout.TRUE);
        drag.setLayoutParams(params);
        drag.setColorFilter(ContextCompat.getColor(getContext(), colorOn));
    }

    public void off()
    {
        this.enabled = false;
        RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams)drag.getLayoutParams();
        params.removeRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        params.addRule(RelativeLayout.ALIGN_PARENT_LEFT, RelativeLayout.TRUE);
        drag.setLayoutParams(params);
        drag.setColorFilter(ContextCompat.getColor(getContext(), colorOff));
    }

    public void toggle()
    {
        if(enabled) off();
        else on();
    }

    public Boolean isOn()
    {
        return enabled;
    }

    @Override
    public void onClick(View view) {
        toggle();
        if(listener!=null) listener.onClick(this, SwitchButtonLayout.this.enabled);
    }
}