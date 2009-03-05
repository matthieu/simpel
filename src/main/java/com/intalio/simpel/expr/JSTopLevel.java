package com.intalio.simpel.expr;

import org.mozilla.javascript.*;
import org.mozilla.javascript.tools.shell.Main;

public class JSTopLevel extends ImporterTopLevel {

    private static String _basePath;

    public JSTopLevel(Context cx, String basePath) {
        super(cx);
        defineFunctionProperties(new String[] { "load" }, JSTopLevel.class, ScriptableObject.DONTENUM);
        _basePath = basePath + "/";
    }

    public static void load(Context cx, Scriptable thisObj, Object[] args, Function funObj) {
        for (int i = 0; i < args.length; i++) {
            Main.processFile(cx, thisObj, _basePath + Context.toString(args[i]));
        }
    }

}
