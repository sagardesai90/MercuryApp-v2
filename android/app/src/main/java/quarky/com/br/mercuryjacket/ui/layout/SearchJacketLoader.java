package quarky.com.br.mercuryjacket.ui.layout;

import android.content.Context;

import androidx.core.content.ContextCompat;
import android.util.AttributeSet;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import java.io.IOException;

import pl.droidsonroids.gif.GifDrawable;
import pl.droidsonroids.gif.GifImageView;
import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.BluetoothController;

public class SearchJacketLoader extends RelativeLayout {

    ImageView ic_jacket;
    ImageView progress_bar_bg;
    GifImageView progress_bar;
    GifDrawable gifFromAssets;
    Boolean searching = false;

    private BluetoothController bluetoothController;

    public SearchJacketLoader(Context context) {
        super(context);
    }

    public SearchJacketLoader(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public SearchJacketLoader(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public SearchJacketLoader(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        this.ic_jacket       = findViewById(R.id.ic_jacket);
        this.progress_bar_bg = findViewById(R.id.progress_bar_bg);
        this.progress_bar    = findViewById(R.id.progress_bar);
    }

    public void startLoader()
    {
        if(!searching)
        {
            searching = true;
            try {
                gifFromAssets = new GifDrawable( getContext().getAssets(), "img/loader_black.gif" );
                progress_bar.setImageDrawable(gifFromAssets);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private void stopAnimation(Boolean finished)
    {
        if(gifFromAssets!=null)
        {
            gifFromAssets.stop();
            gifFromAssets = null;
        }
        progress_bar.setImageDrawable(null);

        if (finished) finish();
        else ic_jacket.setImageResource(R.drawable.jacket);
    }

    public void stopLoader()
    {
        searching = false;
        stopAnimation(false);
    }

    public void found()
    {
        stopAnimation(true);
    }

    private void finish()
    {
        progress_bar.setImageResource(R.drawable.loaded_bar);

        int red = ContextCompat.getColor(getContext(), R.color.redTwo);
        ic_jacket.setImageResource(R.drawable.jacket_found);
    }
}
