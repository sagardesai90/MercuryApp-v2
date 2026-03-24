package quarky.com.br.mercuryjacket.ui.layout;

import android.content.Context;

import androidx.constraintlayout.widget.ConstraintLayout;
import android.util.AttributeSet;

public class RoundedClipLayout extends ConstraintLayout {
    public RoundedClipLayout(Context context) {
        super(context);
        init(context);
    }

    public RoundedClipLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public RoundedClipLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

//    @Override
//    protected void onDraw(Canvas canvas) {
//        super.onDraw(canvas);
//
//    }

    public void init(final Context context) {
        setClipToOutline(true);
    }
}