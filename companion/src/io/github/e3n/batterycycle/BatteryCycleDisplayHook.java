package io.github.e3n.batterycycle;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.Locale;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

/**
 * DEPRECATED / Not shipped since v1.1.0-alpha.2 — FROZEN v1.1.0-alpha.1 artifact.
 *
 * This companion hooked the WRONG page. Verified against the on-device
 * Android 17 Security Center 13.6.6-261028.0.1 disassembly, the battery
 * protection screen the user actually opens is
 *
 *   com.miui.powercenter.nightcharge.ChargerProtectActivity
 *   com.miui.powercenter.nightcharge.ChargeProtectFragment.onCreatePreferences(Bundle, String)
 *   superclass com.miui.common.base.ui.OS4PreferenceFragment
 *
 * and its cycle row is the OEM preference whose key is the literal string
 * "reference_cycle_count", located with findPreference and held in the
 * fragment field Lcom/miui/powercenter/nightcharge/ChargeProtectFragment;.g
 * (a miuix.preference.TextPreference). ChargeProtectFragment then calls the
 * OEM capability gate oh.g.N()Z inside onCreatePreferences and, when that
 * gate returns false as it does on this CN firmware, it removes the row with
 * PreferenceGroup.removePreference from the category field .c together with
 * the production-date and first-use-date rows. Hooking
 * com.miui.powercenter.charge.ChargeFeatureFragment therefore never repaired
 * the screen the user reported, and the installed companion APK was removed
 * from the phone.
 *
 * Kept here unchanged as the frozen alpha.1 build source plus the recorded
 * target contract for the next Magisk-only patch. The next patch must bind to
 * the verified ChargeProtectFragment page, must key on "reference_cycle_count"
 * so the OEM row is restored rather than duplicated, must read only
 * miui.util.IMiCharge.getBatteryCycleCount() with read-only sysfs fallbacks,
 * must inject nothing when the real value is unavailable, and must not touch
 * the PowerCenterProvider return value, the persisted Security Center health
 * record, the raw SOH, the cycle counters or any charge policy.
 *
 * No standalone companion APK is published from v1.1.0-alpha.2 onward.
 */
public final class BatteryCycleDisplayHook implements IXposedHookLoadPackage {
    private static final String TAG = "E3N-BatteryCycleDisplay";
    private static final String PKG = "com.miui.securitycenter";
    /* Retired target: a different page than the one the user opens. */
    private static final String FRAGMENT =
            "com.miui.powercenter.charge.ChargeFeatureFragment";
    private static final String PREF_KEY = "e3n_actual_battery_cycle_count";
    private static final String[] READ_ONLY_NODES = new String[]{
            "/sys/class/xm_power/fg_master/cyclecount",
            "/sys/class/power_supply/battery/cycle_count"
    };

    @Override
    public void handleLoadPackage(final XC_LoadPackage.LoadPackageParam load) {
        if (!PKG.equals(load.packageName)) {
            return;
        }
        try {
            XposedHelpers.findAndHookMethod(FRAGMENT, load.classLoader,
                    "onCreatePreferences", Bundle.class, String.class,
                    new XC_MethodHook() {
                        @Override
                        protected void afterHookedMethod(MethodHookParam p) {
                            try {
                                restoreCyclePreference(p.thisObject, load.classLoader);
                            } catch (Throwable failure) {
                                Log.w(TAG, "Battery protection preference adapter skipped: "
                                        + failure.getClass().getSimpleName());
                            }
                        }
                    });
            Log.i(TAG, "Safe cycle display hook registered for SecurityCenter");
        } catch (Throwable unsupportedVersion) {
            Log.i(TAG, "Unsupported OEM fragment: skip without changing system behavior");
        }
    }

    private static void restoreCyclePreference(Object fragment, ClassLoader loader)
            throws Exception {
        Object ctxValue = XposedHelpers.callMethod(fragment, "getContext");
        Object screen = XposedHelpers.callMethod(fragment, "getPreferenceScreen");
        if (!(ctxValue instanceof Context) || screen == null) {
            return;
        }
        int cycles = readActualCycles(loader);
        if (cycles < 0) {
            Log.i(TAG, "OEM cycle count unavailable: no artificial value inserted");
            return;
        }

        // Do not duplicate a valid native cycle row when Xiaomi re-enables it.
        if (hasNativeVisibleCycleRow(screen)) {
            return;
        }

        Object existing = XposedHelpers.callMethod(screen, "findPreference", PREF_KEY);
        if (existing == null) {
            Class<?> prefClass = Class.forName(
                    "androidx.preference.Preference", false, loader);
            existing = prefClass.getConstructor(Context.class).newInstance(ctxValue);
            XposedHelpers.callMethod(existing, "setKey", PREF_KEY);
            XposedHelpers.callMethod(existing, "setSelectable", false);
            XposedHelpers.callMethod(existing, "setOrder", Integer.MAX_VALUE - 100);
            XposedHelpers.callMethod(screen, "addPreference", existing);
        }
        Locale locale = Locale.getDefault();
        boolean zh = "zh".equals(locale.getLanguage());
        XposedHelpers.callMethod(existing, "setTitle",
                zh ? "电池循环次数" : "Battery cycle count");
        XposedHelpers.callMethod(existing, "setSummary",
                zh ? cycles + " 次（原厂实时数据）"
                        : cycles + " cycles (OEM live value)");
        XposedHelpers.callMethod(existing, "setVisible", true);
        Log.i(TAG, "Read-only battery cycle row restored: " + cycles);
    }

    private static boolean hasNativeVisibleCycleRow(Object group) {
        try {
            int count = (Integer) XposedHelpers.callMethod(group, "getPreferenceCount");
            for (int i = 0; i < count && i < 100; i++) {
                Object item = XposedHelpers.callMethod(group, "getPreference", i);
                if (item == null) continue;
                Object keyObject = XposedHelpers.callMethod(item, "getKey");
                String key = keyObject == null ? "" : keyObject.toString();
                if (PREF_KEY.equals(key)) continue;
                Object titleObject = XposedHelpers.callMethod(item, "getTitle");
                String title = titleObject == null ? "" : titleObject.toString()
                        .trim().toLowerCase(Locale.ROOT);
                boolean nativeCycleTitle =
                        "电池循环次数".equals(title) || "充电循环次数".equals(title) ||
                        "循环次数".equals(title) || "cycle count".equals(title) ||
                        "battery cycle count".equals(title);
                if (nativeCycleTitle &&
                        Boolean.TRUE.equals(XposedHelpers.callMethod(item, "isVisible"))) {
                    return true;
                }
                try {
                    if (hasNativeVisibleCycleRow(item)) return true;
                } catch (Throwable notGroup) {
                    // Child is an ordinary Preference, not a PreferenceGroup.
                }
            }
        } catch (Throwable noGroup) {
            // OEM changed its PreferenceGroup API, do not alter native controls.
        }
        return false;
    }

    private static int readActualCycles(ClassLoader loader) {
        // Same OEM method the installed Security Center already uses.
        try {
            Class<?> miCharge = Class.forName("miui.util.IMiCharge", false, loader);
            Object instance = XposedHelpers.callStaticMethod(miCharge, "getInstance");
            Object response = XposedHelpers.callMethod(instance, "getBatteryCycleCount");
            int n = parseCycle(response == null ? null : response.toString());
            if (n >= 0) return n;
        } catch (Throwable oemUnavailable) {
            Log.i(TAG, "IMiCharge API unavailable; falling back to read-only fuel gauge");
        }
        for (String path : READ_ONLY_NODES) {
            try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
                int n = parseCycle(reader.readLine());
                if (n >= 0) return n;
            } catch (Exception unavailable) {
                // Do not change sysfs permissions and do not forge a value.
            }
        }
        return -1;
    }

    private static int parseCycle(String source) {
        if (source == null) return -1;
        source = source.trim();
        if (!source.matches("[0-9]{1,5}")) return -1;
        try {
            int value = Integer.parseInt(source);
            return value >= 0 && value <= 10000 ? value : -1;
        } catch (NumberFormatException invalid) {
            return -1;
        }
    }
}
