package com.intalio.simpel;

import java.util.List;

/**
 * @author Matthieu Riou <mriou@apache.org>
 */
public interface ErrorListener {

    List<CompilationException.Error> getErrors();

    void reportRecognitionError(int line, int column, String message, Exception e);
}
