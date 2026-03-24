package quarky.com.br.mercuryjacket.ui.view;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Typeface;
import androidx.annotation.Nullable;
import android.util.AttributeSet;
import android.widget.TextView;

import quarky.com.br.mercuryjacket.R;

public class CustomTextView extends TextView {
    public CustomTextView(Context context) {
        super(context);
    }

    public CustomTextView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.CustomTextView);
        setFontFamily(a.getString(0));
    }

    public CustomTextView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public CustomTextView(Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    public void setFontFamily(String fontFamily) {
        if(fontFamily!=null)
        {
            Typeface custom_font = Typeface.createFromAsset(getContext().getAssets(),"fonts/"+fontFamily);
            setTypeface(custom_font);
        }
    }
}
