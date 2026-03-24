package quarky.com.br.mercuryjacket.ui.layout;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.widget.RelativeLayout;

import quarky.com.br.mercuryjacket.activity.BaseActivity;

public class CloseButtonLayout extends RelativeLayout implements View.OnClickListener {
    public CloseButtonLayout(Context context) {
        super(context);
    }

    public CloseButtonLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
        setOnClickListener(this);
    }

    public CloseButtonLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public CloseButtonLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    public void onClick(View view) {
        ((BaseActivity) getContext()).onBackPressed();
    }
}
