package quarky.com.br.mercuryjacket.controller;

import android.bluetooth.BluetoothGattCharacteristic;

import java.util.HashMap;
import java.util.UUID;

public class JacketGattAttributes {
    private static HashMap<String, String> attributes = new HashMap<String,String>();

    public static final UUID SERVICE = UUID.fromString("1DF5BAEA-7CE1-4FA2-B31F-CF108FAEAAD2");

    public static final UUID INTERNAL_TEMPERATURE = UUID.fromString("2521d200-3748-4a52-9175-cbc8163a450c");
    public static final UUID EXTERNAL_TEMPERATURE = UUID.fromString("2973b788-15f2-4263-b412-8da09f3f87f9");
    public static final UUID APP_TEMP             = UUID.fromString("939B2D40-E498-4DFE-B7E7-FEB058CAC481");
    public static final UUID POWER_OUTPUT         = UUID.fromString("FB806B90-EC02-42FA-9641-E50D656E7BF6");
    public static final UUID ACTIVITY_LEVEL       = UUID.fromString("7e325bef-a17c-4f13-a0fe-9e49df91a8e2");
    public static final UUID BATTERY_LEVEL        = UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb");
    public static final UUID SET_LOW_TEMP         = UUID.fromString("7669f03f-cbe5-4850-bb04-32797aba3b82");
    public static final UUID SET_HIGH_TEMP        = UUID.fromString("cedbd484-6965-4c96-8dbf-b9d3bac14332");
    public static final UUID HIGH_TEMP_PT         = UUID.fromString("EE4A5607-C1BE-4B4C-A602-A999CA4B585B");
    public static final UUID LOW_TEMP_PT          = UUID.fromString("802CE3F8-BACA-4CA7-9DD3-A7E56EF3BE26");

    public static final UUID MODE                 = UUID.fromString("7b46fb49-be72-4113-af8b-fa2bd5fd2c68");
    public static final UUID POWER_LEVEL          = UUID.fromString("f669680f-eb1d-4136-8b95-8852f0ec6a1a");
    public static final UUID CONFIG               = UUID.fromString("696D06B0-1B3E-4E18-AC62-384CEEBF6E68");
    public static final UUID BOOT_DELAY           = UUID.fromString("631492AB-333F-4701-885B-49A76F39098B");
    public static final UUID PREHEAT_TIME         = UUID.fromString("A223DC3B-2FAC-4353-B674-0D77E490B690");
    public static final UUID PREHEAT_DELAY        = UUID.fromString("4BF1A842-2B01-4F8E-B749-727C3F11A0BC");
    public static final UUID NO_POWER_STARTUP_TIME= UUID.fromString("A5DEA1D9-A86D-4904-B9CA-57EA4F54C3A4");
    public static final UUID ACCEL_THRESHOLD_HI   = UUID.fromString("6E7501B3-FE0A-42C8-A383-A1CA6DF57E1A");
    public static final UUID ACCEL_THRESHOLD_LO   = UUID.fromString("0F32CF12-8AE6-4209-823B-93A039369CAA");
    public static final UUID MOTION_TEMP          = UUID.fromString("A8D30C8E-D0D6-4A3E-8505-B0A13FDD9474");
    public static final UUID NO_MOTION_TIME       = UUID.fromString("57C9D431-2207-4ABE-8794-642710A33D70");
    public static final UUID DEFAULT_MODE         = UUID.fromString("AAFAA054-BA7E-427E-A456-C65F0D4D09B8");
    public static final UUID SAVE_NV_SETTINGS     = UUID.fromString("E0662BAA-0C2F-42CA-821C-F70465EDB6B4");
    public static final UUID HOOK_1               = UUID.fromString("D5B6929D-D140-4B3B-A8F0-7F2767C735C6");
    public static final UUID HOOK_2               = UUID.fromString("847E0167-C9AE-486D-A110-CD478486D90B");
    public static final UUID HOOK_3               = UUID.fromString("CBF93B1A-8584-4DE1-9125-5685EC767DE1");
    public static final UUID HOOK_4               = UUID.fromString("00E20DED-5FFB-40CE-82C0-52274EC47672");

    public final static int STANDBY_MODE = 1;
    public final static int SMART_MODE   = 2;
    public final static int MANUAL_MODE  = 3;
    public final static int PRE_MODE     = 4;

    public static final HashMap<String,Integer> formatMap = new HashMap<String,Integer>();

    static {
        attributes.put(INTERNAL_TEMPERATURE.toString(), "Internal Temperature");
        attributes.put(EXTERNAL_TEMPERATURE.toString(), "External Temperature");
        attributes.put(APP_TEMP.toString(), "App Temperature");
        attributes.put(POWER_OUTPUT.toString(), "Power Output");
        attributes.put(ACTIVITY_LEVEL.toString(), "Activity Level");
        attributes.put(BATTERY_LEVEL.toString(), "Battery Level");
        attributes.put(SET_LOW_TEMP.toString(), "Low Temp");
        attributes.put(SET_HIGH_TEMP.toString(), "High Temp");
        attributes.put(LOW_TEMP_PT.toString(), "Low Temp 10*K");
        attributes.put(HIGH_TEMP_PT.toString(), "High Temp 10*K");
        attributes.put(MODE.toString(), "Mode");
        attributes.put(POWER_LEVEL.toString(), "Power Level");
        attributes.put(BOOT_DELAY.toString(), "Boot Delay");
        attributes.put(PREHEAT_TIME.toString(), "Preheat Time");
        attributes.put(PREHEAT_DELAY.toString(), "Preheat Delay");
        attributes.put(NO_POWER_STARTUP_TIME.toString(), "No Power Startup Time");
        attributes.put(ACCEL_THRESHOLD_HI.toString(), "Accel Threshold High");
        attributes.put(ACCEL_THRESHOLD_LO.toString(), "Accel Threshold Low");
        attributes.put(MOTION_TEMP.toString(), "Motion Temperature");
        attributes.put(CONFIG.toString(), "Config");
        attributes.put(NO_MOTION_TIME.toString(), "No Motion Time");
        attributes.put(DEFAULT_MODE.toString(), "Default Mode");
        attributes.put(SAVE_NV_SETTINGS.toString(), "Save Non-volatile Settings");
        attributes.put(HOOK_1.toString(), "Hook #1");
        attributes.put(HOOK_2.toString(), "Hook #2");
        attributes.put(HOOK_3.toString(), "Hook #3");
        attributes.put(HOOK_4.toString(), "Hook #4");

        formatMap.put(INTERNAL_TEMPERATURE.toString(),BluetoothGattCharacteristic.FORMAT_SINT16);
        formatMap.put(EXTERNAL_TEMPERATURE.toString(),BluetoothGattCharacteristic.FORMAT_SINT16);
        formatMap.put(POWER_OUTPUT.toString(),BluetoothGattCharacteristic.FORMAT_UINT16);
        formatMap.put(ACTIVITY_LEVEL.toString(),BluetoothGattCharacteristic.FORMAT_UINT16);
        formatMap.put(POWER_LEVEL.toString(),BluetoothGattCharacteristic.FORMAT_UINT16);
        formatMap.put(SET_LOW_TEMP.toString(),BluetoothGattCharacteristic.FORMAT_SINT16);
        formatMap.put(SET_HIGH_TEMP.toString(),BluetoothGattCharacteristic.FORMAT_SINT16);
        formatMap.put(MOTION_TEMP.toString(),BluetoothGattCharacteristic.FORMAT_SINT16);
        formatMap.put(MODE.toString(),BluetoothGattCharacteristic.FORMAT_UINT8);
    }

    public static String getName(UUID uuid) {
        String name = attributes.get(uuid.toString());
        return name;
    }

    public static int getFormat(UUID uuid) {
        return  formatMap.containsKey(uuid.toString()) ? formatMap.get(uuid.toString()) : 0;
    }
}
