package quarky.com.br.mercuryjacket.ui.layout;

import android.app.Activity;
import android.content.Context;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import android.text.SpannableStringBuilder;
import android.util.AttributeSet;
import android.util.Log;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.io.IOException;

import pl.droidsonroids.gif.GifDrawable;
import pl.droidsonroids.gif.GifImageView;
import quarky.com.br.mercuryjacket.R;

public class JacketLoaderLayout extends LinearLayout {
    ImageView jacket;
    TextView loader_status_txt;
    GifImageView loader;
    Context context;

    GifDrawable gifFromAssets;
    private Boolean connected = false;
    private Boolean finished = false;

    public JacketLoaderLayout(Context context) {
        super(context);
        this.context = context;
    }

    public JacketLoaderLayout(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        this.context = context;
    }

    public JacketLoaderLayout(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        this.context = context;
    }

    public JacketLoaderLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        this.context = context;
    }

    public void setContext(Context context)
    {
        this.context = context;
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        jacket              = findViewById(R.id.jacket);
        loader_status_txt   = findViewById(R.id.loader_status_txt);
        loader              = findViewById(R.id.loader);
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        startLoader();
        Log.e("LOADER","Opa, loader adicionado.");
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        stopLoader();
        Log.e("LOADER","Opa, loader removido.");
    }

    private void finish()
    {
        loader.setImageResource(R.drawable.loaded_bar);

        int red = ContextCompat.getColor(context, R.color.redTwo);
        //jacket.setColorFilter(red);
        jacket.setImageResource(R.drawable.jacket_found);
        loader_status_txt.setText( connected ? R.string.connected : R.string.found );
        loader_status_txt.setTextColor(red);
    }

    public void setTitle(SpannableStringBuilder value)
    {
        this.loader_status_txt.setText(value);
    }

    public void startLoader()
    {
        if(!finished)
        {
            try {
                gifFromAssets = new GifDrawable( getContext().getAssets(), "img/loader.gif" );
                loader.setImageDrawable(gifFromAssets);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public void resumeAnimation()
    {
        loader.setVisibility(VISIBLE);
        gifFromAssets.start();
    }

    public void pauseAnimation()
    {
        gifFromAssets.pause();
        loader.setVisibility(GONE);
    }

    private void stopAnimation()
    {
        if(gifFromAssets!=null)
        {
            gifFromAssets.stop();
            gifFromAssets = null;
        }
        loader.setImageDrawable(null);

        if (finished) {
            ((Activity) context).runOnUiThread(new Runnable() {
                public void run() {
                    finish();
                }
            });
        }
    }

    public void stopLoader()
    {
        finished = false;
        stopAnimation();
    }

    public void found(Boolean connected)
    {
        this.connected = connected;
        finished = true;
        stopAnimation();
    }
}
