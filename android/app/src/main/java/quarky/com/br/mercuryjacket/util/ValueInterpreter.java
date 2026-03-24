package quarky.com.br.mercuryjacket.util;

import android.util.Log;

public class ValueInterpreter {
    public static final int FORMAT_UINT8 = 0x11;
    public static final int FORMAT_UINT16 = 0x12;
    public static final int FORMAT_UINT32 = 0x14;
    public static final int FORMAT_SINT8 = 0x21;
    public static final int FORMAT_SINT16 = 0x22;
    public static final int FORMAT_SINT32 = 0x24;
    public static final int FORMAT_SFLOAT = 0x32;
    public static final int FORMAT_FLOAT = 0x34;

    public static Integer getIntValue(byte[] value, int formatType, int offset) {
        if ((offset + getTypeLen(formatType)) > value.length) {
            Log.e("ValueInterpreter","Int formatType (0x%x) is longer than remaining bytes (%d) - returning null " + formatType + " "+(value.length - offset));
            return null;
        }

        switch (formatType) {
            case FORMAT_UINT8:
                return unsignedByteToInt(value[offset]);

            case FORMAT_UINT16:
                return unsignedBytesToInt(value[offset], value[offset + 1]);

            case FORMAT_UINT32:
                return unsignedBytesToInt(value[offset],   value[offset + 1],
                        value[offset + 2], value[offset + 3]);
            case FORMAT_SINT8:
                return unsignedToSigned(unsignedByteToInt(value[offset]), 8);

            case FORMAT_SINT16:
                return unsignedToSigned(unsignedBytesToInt(value[offset],
                        value[offset + 1]), 16);

            case FORMAT_SINT32:
                return unsignedToSigned(unsignedBytesToInt(value[offset],
                        value[offset + 1], value[offset + 2], value[offset + 3]), 32);
            default:
                Log.e("ValueInterpreter","Passed an invalid integer formatType (0x%x) - returning null " + formatType);
                return null;
        }
    }

    private static int getTypeLen(int formatType) {
        return formatType & 0xF;
    }

    private static int unsignedByteToInt(byte b) {
        return b & 0xFF;
    }

    private static int unsignedBytesToInt(byte b0, byte b1) {
        return (unsignedByteToInt(b0) + (unsignedByteToInt(b1) << 8));
    }

    private static int unsignedBytesToInt(byte b0, byte b1, byte b2, byte b3) {
        return (unsignedByteToInt(b0) + (unsignedByteToInt(b1) << 8))
                + (unsignedByteToInt(b2) << 16) + (unsignedByteToInt(b3) << 24);
    }

    private static int unsignedToSigned(int unsigned, int size) {
        if ((unsigned & (1 << size - 1)) != 0) {
            unsigned = -1 * ((1 << size - 1) - (unsigned & ((1 << size - 1) - 1)));
        }
        return unsigned;
    }
}
