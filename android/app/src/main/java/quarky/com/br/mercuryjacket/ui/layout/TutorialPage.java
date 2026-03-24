package quarky.com.br.mercuryjacket.ui.layout;

import android.content.Context;
import androidx.annotation.Nullable;
import android.util.AttributeSet;
import android.widget.LinearLayout;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.ui.view.CustomTextView;

public class TutorialPage extends LinearLayout {

    CustomTextView title_txt;

    public TutorialPage(Context context) {
        super(context);
    }

    public TutorialPage(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public TutorialPage(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public TutorialPage(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        this.title_txt = findViewById(R.id.title_txt);
    }
}
