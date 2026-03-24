package quarky.com.br.mercuryjacket.ui.layout;

import android.content.Context;
import androidx.annotation.Nullable;
import android.util.AttributeSet;
import android.view.View;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.ui.dialog.SearchJacketDialog;

public class TutorialPage5 extends TutorialPage {
    public TutorialPage5(Context context) {
        super(context);
    }

    public TutorialPage5(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public TutorialPage5(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public TutorialPage5(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();

        final View add_jacker_bt = findViewById(R.id.add_jacker_bt);
        add_jacker_bt.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                final SearchJacketDialog searchJacketDialog = new SearchJacketDialog(getContext());
                searchJacketDialog.show();
            }
        });
    }
}
