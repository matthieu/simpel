package com.intalio.simpel.expr;

import org.mozilla.javascript.*;
import org.mozilla.javascript.tools.shell.Main;
import org.mozilla.javascript.tools.shell.Global;
import org.mozilla.javascript.tools.ToolErrorReporter;

import java.io.*;
import java.net.URL;
import java.net.URLConnection;

public class JSTopLevel extends ImporterTopLevel {

    private static String _basePath;
    private InputStream inStream;
    private PrintStream outStream;
    private PrintStream errStream;

    public JSTopLevel(Context cx, String basePath) {
        super(cx);
        defineFunctionProperties(new String[] { "load", "print", "readFile", "readUrl", "runCommand" },
                JSTopLevel.class, ScriptableObject.DONTENUM);
        _basePath = basePath + "/";

        inStream = System.in;
        outStream = System.out;
        errStream = System.err;
    }

    public static void load(Context cx, Scriptable thisObj, Object[] args, Function funObj) {
        for (int i = 0; i < args.length; i++) {
            Main.processFile(cx, thisObj, _basePath + Context.toString(args[i]));
        }
    }

    public static Object print(Context cx, Scriptable thisObj, Object[] args, Function funObj) {
        PrintStream out = getInstance(funObj).getOut();
        for (int i=0; i < args.length; i++) {
            if (i > 0) out.print(" ");

            // Convert the arbitrary JavaScript value into a string form.
            String s = Context.toString(args[i]);
            out.print(s);
        }
        out.println();
        return Context.getUndefinedValue();
    }

    public static Object readFile(Context cx, Scriptable thisObj, Object[] args, Function funObj) throws IOException {
        if (args.length == 0)
            throw reportRuntimeError("msg.shell.readFile.bad.args");
        String path = ScriptRuntime.toString(args[0]);
        String charCoding = null;
        if (args.length >= 2)
            charCoding = ScriptRuntime.toString(args[1]);

        return readUrl(path, charCoding, true);
    }

    public static Object readUrl(Context cx, Scriptable thisObj, Object[] args, Function funObj) throws IOException {
        if (args.length == 0)
            throw reportRuntimeError("msg.shell.readUrl.bad.args");
        String url = ScriptRuntime.toString(args[0]);
        String charCoding = null;
        if (args.length >= 2)
            charCoding = ScriptRuntime.toString(args[1]);

        return readUrl(url, charCoding, false);
    }

    public static Object runCommand(Context cx, Scriptable thisObj, Object[] args, Function funObj) throws IOException {
        int L = args.length;
        if (L == 0 || (L == 1 && args[0] instanceof Scriptable)) {
            throw reportRuntimeError("msg.runCommand.bad.args");
        }

        InputStream in = null;
        OutputStream out = null, err = null;
        ByteArrayOutputStream outBytes = null, errBytes = null;
        Object outObj = null, errObj = null;
        String[] environment = null;
        Scriptable params = null;
        Object[] addArgs = null;
        if (args[L - 1] instanceof Scriptable) {
            params = (Scriptable)args[L - 1];
            --L;
            Object envObj = ScriptableObject.getProperty(params, "env");
            if (envObj != Scriptable.NOT_FOUND) {
                if (envObj == null) {
                    environment = new String[0];
                } else {
                    if (!(envObj instanceof Scriptable)) {
                        throw reportRuntimeError("msg.runCommand.bad.env");
                    }
                    Scriptable envHash = (Scriptable)envObj;
                    Object[] ids = ScriptableObject.getPropertyIds(envHash);
                    environment = new String[ids.length];
                    for (int i = 0; i != ids.length; ++i) {
                        Object keyObj = ids[i], val;
                        String key;
                        if (keyObj instanceof String) {
                            key = (String)keyObj;
                            val = ScriptableObject.getProperty(envHash, key);
                        } else {
                            int ikey = ((Number)keyObj).intValue();
                            key = Integer.toString(ikey);
                            val = ScriptableObject.getProperty(envHash, ikey);
                        }
                        if (val == ScriptableObject.NOT_FOUND) {
                            val = Undefined.instance;
                        }
                        environment[i] = key+'='+ScriptRuntime.toString(val);
                    }
                }
            }
            Object inObj = ScriptableObject.getProperty(params, "input");
            if (inObj != Scriptable.NOT_FOUND) {
                in = toInputStream(inObj);
            }
            outObj = ScriptableObject.getProperty(params, "output");
            if (outObj != Scriptable.NOT_FOUND) {
                out = toOutputStream(outObj);
                if (out == null) {
                    outBytes = new ByteArrayOutputStream();
                    out = outBytes;
                }
            }
            errObj = ScriptableObject.getProperty(params, "err");
            if (errObj != Scriptable.NOT_FOUND) {
                err = toOutputStream(errObj);
                if (err == null) {
                    errBytes = new ByteArrayOutputStream();
                    err = errBytes;
                }
            }
            Object addArgsObj = ScriptableObject.getProperty(params, "args");
            if (addArgsObj != Scriptable.NOT_FOUND) {
                Scriptable s = Context.toObject(addArgsObj,
                                                getTopLevelScope(thisObj));
                addArgs = cx.getElements(s);
            }
        }
        JSTopLevel global = getInstance(funObj);
        if (out == null) {
            out = (global != null) ? global.getOut() : System.out;
        }
        if (err == null) {
            err = (global != null) ? global.getErr() : System.err;
        }
        // If no explicit input stream, do not send any input to process,
        // in particular, do not use System.in to avoid deadlocks
        // when waiting for user input to send to process which is already
        // terminated as it is not always possible to interrupt read method.

        String[] cmd = new String[(addArgs == null) ? L : L + addArgs.length];
        for (int i = 0; i != L; ++i) {
            cmd[i] = ScriptRuntime.toString(args[i]);
        }
        if (addArgs != null) {
            for (int i = 0; i != addArgs.length; ++i) {
                cmd[L + i] = ScriptRuntime.toString(addArgs[i]);
            }
        }

        int exitCode = runProcess(cmd, environment, in, out, err);
        if (outBytes != null) {
            String s = ScriptRuntime.toString(outObj) + outBytes.toString();
            ScriptableObject.putProperty(params, "output", s);
        }
        if (errBytes != null) {
            String s = ScriptRuntime.toString(errObj) + errBytes.toString();
            ScriptableObject.putProperty(params, "err", s);
        }

        return new Integer(exitCode);
    }


    private static JSTopLevel getInstance(Function function) {
        Scriptable scope = function.getParentScope();
        if (!(scope instanceof JSTopLevel))
            throw reportRuntimeError("msg.bad.shell.function.scope", String.valueOf(scope));
        return (JSTopLevel)scope;
    }

    static RuntimeException reportRuntimeError(String msgId) {
        String message = ToolErrorReporter.getMessage(msgId);
        return Context.reportRuntimeError(message);
    }

    static RuntimeException reportRuntimeError(String msgId, String msgArg) {
        String message = ToolErrorReporter.getMessage(msgId, msgArg);
        return Context.reportRuntimeError(message);
    }

    private static String readUrl(String filePath, String charCoding, boolean urlIsFile) throws IOException {
        int chunkLength;
        InputStream is = null;
        try {
            if (!urlIsFile) {
                URL urlObj = new URL(filePath);
                URLConnection uc = urlObj.openConnection();
                is = uc.getInputStream();
                chunkLength = uc.getContentLength();
                if (chunkLength <= 0)
                    chunkLength = 1024;
                if (charCoding == null) {
                    String type = uc.getContentType();
                    if (type != null) {
                        charCoding = getCharCodingFromType(type);
                    }
                }
            } else {
                File f = new File(filePath);

                long length = f.length();
                chunkLength = (int)length;
                if (chunkLength != length)
                    throw new IOException("Too big file size: "+length);

                if (chunkLength == 0) { return ""; }

                is = new FileInputStream(f);
            }

            Reader r;
            if (charCoding == null) {
                r = new InputStreamReader(is);
            } else {
                r = new InputStreamReader(is, charCoding);
            }
            return readReader(r, chunkLength);

        } finally {
            if (is != null)
                is.close();
        }
    }

    private static String getCharCodingFromType(String type)
    {
        int i = type.indexOf(';');
        if (i >= 0) {
            int end = type.length();
            ++i;
            while (i != end && type.charAt(i) <= ' ') {
                ++i;
            }
            String charset = "charset";
            if (charset.regionMatches(true, 0, type, i, charset.length()))
            {
                i += charset.length();
                while (i != end && type.charAt(i) <= ' ') {
                    ++i;
                }
                if (i != end && type.charAt(i) == '=') {
                    ++i;
                    while (i != end && type.charAt(i) <= ' ') {
                        ++i;
                    }
                    if (i != end) {
                        // i is at the start of non-empty
                        // charCoding spec
                        while (type.charAt(end -1) <= ' ') {
                            --end;
                        }
                        return type.substring(i, end);
                    }
                }
            }
        }
        return null;
    }

    private static String readReader(Reader reader) throws IOException {
        return readReader(reader, 4096);
    }

    private static String readReader(Reader reader, int initialBufferSize) throws IOException {
        char[] buffer = new char[initialBufferSize];
        int offset = 0;
        for (;;) {
            int n = reader.read(buffer, offset, buffer.length - offset);
            if (n < 0) { break;    }
            offset += n;
            if (offset == buffer.length) {
                char[] tmp = new char[buffer.length * 2];
                System.arraycopy(buffer, 0, tmp, 0, offset);
                buffer = tmp;
            }
        }
        return new String(buffer, 0, offset);
    }

    private static int runProcess(String[] cmd, String[] environment, InputStream in,
                                  OutputStream out, OutputStream err) throws IOException {
        Process p;
        if (environment == null) {
            p = Runtime.getRuntime().exec(cmd);
        } else {
            p = Runtime.getRuntime().exec(cmd, environment);
        }

        try {
            PipeThread inThread = null;
            if (in != null) {
                inThread = new PipeThread(false, in, p.getOutputStream());
                inThread.start();
            } else {
                p.getOutputStream().close();
            }

            PipeThread outThread = null;
            if (out != null) {
                outThread = new PipeThread(true, p.getInputStream(), out);
                outThread.start();
            } else {
                p.getInputStream().close();
            }

            PipeThread errThread = null;
            if (err != null) {
                errThread = new PipeThread(true, p.getErrorStream(), err);
                errThread.start();
            } else {
                p.getErrorStream().close();
            }

            // wait for process completion
            for (;;) {
                try {
                    p.waitFor();
                    if (outThread != null) {
                        outThread.join();
                    }
                    if (inThread != null) {
                        inThread.join();
                    }
                    if (errThread != null) {
                        errThread.join();
                    }
                    break;
                } catch (InterruptedException ignore) {
                }
            }

            return p.exitValue();
        } finally {
            p.destroy();
        }
    }

    static void pipe(boolean fromProcess, InputStream from, OutputStream to) throws IOException {
        try {
            final int SIZE = 4096;
            byte[] buffer = new byte[SIZE];
            for (;;) {
                int n;
                if (!fromProcess) {
                    n = from.read(buffer, 0, SIZE);
                } else {
                    try {
                        n = from.read(buffer, 0, SIZE);
                    } catch (IOException ex) {
                        // Ignore exception as it can be cause by closed pipe
                        break;
                    }
                }
                if (n < 0) { break; }
                if (fromProcess) {
                    to.write(buffer, 0, n);
                    to.flush();
                } else {
                    try {
                        to.write(buffer, 0, n);
                        to.flush();
                    } catch (IOException ex) {
                        // Ignore exception as it can be cause by closed pipe
                        break;
                    }
                }
            }
        } finally {
            try {
                if (fromProcess) {
                    from.close();
                } else {
                    to.close();
                }
            } catch (IOException ex) {
                // Ignore errors on close. On Windows JVM may throw invalid
                // refrence exception if process terminates too fast.
            }
        }
    }

    private static InputStream toInputStream(Object value) throws IOException {
        InputStream is = null;
        String s = null;
        if (value instanceof Wrapper) {
            Object unwrapped = ((Wrapper)value).unwrap();
            if (unwrapped instanceof InputStream) {
                is = (InputStream)unwrapped;
            } else if (unwrapped instanceof byte[]) {
                is = new ByteArrayInputStream((byte[])unwrapped);
            } else if (unwrapped instanceof Reader) {
                s = readReader((Reader)unwrapped);
            } else if (unwrapped instanceof char[]) {
                s = new String((char[])unwrapped);
            }
        }
        if (is == null) {
            if (s == null) { s = ScriptRuntime.toString(value); }
            is = new ByteArrayInputStream(s.getBytes());
        }
        return is;
    }

    private static OutputStream toOutputStream(Object value) {
        OutputStream os = null;
        if (value instanceof Wrapper) {
            Object unwrapped = ((Wrapper)value).unwrap();
            if (unwrapped instanceof OutputStream) {
                os = (OutputStream)unwrapped;
            }
        }
        return os;
    }

    public InputStream getIn() {
        return inStream == null ? System.in : inStream;
    }

    public void setIn(InputStream in) {
        inStream = in;
    }

    public PrintStream getOut() {
        return outStream == null ? System.out : outStream;
    }

    public void setOut(PrintStream out) {
        outStream = out;
    }

    public PrintStream getErr() {
        return errStream == null ? System.err : errStream;
    }

    public void setErr(PrintStream err) {
        errStream = err;
    }

}

class PipeThread extends Thread {

    PipeThread(boolean fromProcess, InputStream from, OutputStream to) {
        setDaemon(true);
        this.fromProcess = fromProcess;
        this.from = from;
        this.to = to;
    }

    @Override
    public void run() {
        try {
            JSTopLevel.pipe(fromProcess, from, to);
        } catch (IOException ex) {
            throw Context.throwAsScriptRuntimeEx(ex);
        }
    }

    private boolean fromProcess;
    private InputStream from;
    private OutputStream to;
}
