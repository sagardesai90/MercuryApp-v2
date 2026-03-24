package quarky.com.br.mercuryjacket.model;

import android.app.Activity;
import android.util.Log;

import com.google.gson.Gson;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

import quarky.com.br.mercuryjacket.R;
import quarky.com.br.mercuryjacket.controller.AppController;
import quarky.com.br.mercuryjacket.controller.BluetoothController;
import quarky.com.br.mercuryjacket.controller.JacketGattAttributes;
import quarky.com.br.mercuryjacket.ui.layout.SettingLayout;

public class Jacket {
    public static final int DEBUG                = 0;
    public static final int VOICE_CONTROL        = 1;
    public static final int BATTERY_NOTIFICATION = 2;
    public static final int LOCATION_REQUEST     = 3;
    public static final int MOTION_CONTROL       = 4;

    private static final LinkedHashMap<Integer, Boolean> defaultSettings = new LinkedHashMap<Integer, Boolean>();
    static {
        defaultSettings.put(DEBUG, false);
        defaultSettings.put(VOICE_CONTROL, false);
        //defaultSettings.put(BATTERY_NOTIFICATION, true);
        defaultSettings.put(LOCATION_REQUEST, true);
        defaultSettings.put(MOTION_CONTROL, true);
    }

    private LinkedHashMap<Integer, Boolean> settings;

    private String id;
    private String name;
    private int hashCode;
    private long time;
    private String amazonEmail;

    public Jacket(String id){
        this.id = id;
    }

    public int getHashCode() {
        return hashCode;
    }

    public void setHashCode(int hashCode) {
        this.hashCode = hashCode;
    }

    public Date getTime() {
        Date date = new Date();
        date.setTime(time);
        return date;
    }

    public void setTime(Date time) {
        this.time = time.getTime();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAmazonEmail() {
        return amazonEmail;
    }

    public void setAmazonEmail(String amazonEmail) {
        this.amazonEmail = amazonEmail;
    }

    public LinkedHashMap<Integer,Boolean> getSettings()
    {
        LinkedHashMap<Integer,Boolean> tempSettings = (LinkedHashMap<Integer, Boolean>) defaultSettings.clone();
        if(settings!=null)
        {
            for(Map.Entry<Integer, Boolean> entry : tempSettings.entrySet()) {
                Integer key = entry.getKey();
                if(settings.containsKey(key)) tempSettings.put(key,settings.get(key));
            }
        }
        settings = tempSettings;
        return settings;
    }

    public Boolean getSetting(int key)
    {
        return getSettings().containsKey(key) ? getSettings().get(key) : false;
    }

    public String serialize()
    {
        return new Gson().toJson(this);
    }

    public void save()
    {
        for (Map.Entry<Integer, Boolean> entry: getSettings().entrySet()) {
            String name  = AppController.getSettingName(entry.getKey());
            String value = entry.getValue().toString();

            AppController.setUserProperty(name, value);
        }

        AppController.addJacket(this);
    }

    public void delete()
    {
        AppController.removeJacket(this);
    }

    public void updateSetting(Integer key, Boolean value)
    {
        if(BluetoothController.getInstance().isConnected() && key==MOTION_CONTROL)
        {
            BluetoothController.getInstance().writeCharacteristic(JacketGattAttributes.MOTION_TEMP, value ? 1 : 0);
        }
        getSettings().put(key, value);
        save();
    }
}
