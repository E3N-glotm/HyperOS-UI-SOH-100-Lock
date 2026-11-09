package de.robv.android.xposed;
public final class XposedHelpers {
    private XposedHelpers() {}
    public static XC_MethodHook.Unhook findAndHookMethod(
            String className, ClassLoader classLoader,
            String methodName, Object... parameterTypesAndCallback) {
        throw new AssertionError("Compile-only stub must never be packaged");
    }
    public static Object callMethod(Object obj, String methodName, Object... args) {
        throw new AssertionError("Compile-only stub must never be packaged");
    }
    public static Object callStaticMethod(Class<?> clazz, String methodName, Object... args) {
        throw new AssertionError("Compile-only stub must never be packaged");
    }
}
