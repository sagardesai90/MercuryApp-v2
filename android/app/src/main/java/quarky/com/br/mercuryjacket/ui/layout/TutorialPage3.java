package quarky.com.br.mercuryjacket.ui.layout;

import android.content.Context;
import android.graphics.Typeface;
import androidx.annotation.Nullable;
import android.text.SpannableString;
import android.text.Spanned;
import android.util.AttributeSet;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.util.CustomTypefaceSpan;

public class TutorialPage3 extends TutorialPage {
    public TutorialPage3(Context context) {
        super(context);
    }

    public TutorialPage3(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public TutorialPage3(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public TutorialPage3(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        Typeface custom_font = Typeface.createFromAsset(getContext().getAssets(),"fonts/"+getResources().getString(R.string.regular_font));

        String s= "2: “Manual Mode”\n(Power Button: Red)";
        SpannableString ss1=  new SpannableString(s);
        ss1.setSpan (new CustomTypefaceSpan(custom_font), 17, 36, Spanned.SPAN_EXCLUSIVE_INCLUSIVE);
        //ss1.setSpan(new ForegroundColorSpan(getResources().getColor(R.color.grey7)), 41, 61, 0);

        title_txt.setText(ss1);
    }
}
