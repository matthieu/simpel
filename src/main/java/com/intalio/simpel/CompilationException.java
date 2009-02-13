package com.intalio.simpel;

import java.util.List;

/**
 * Main exception for all possible errors happening during compilation. For recoverable errors, it's thrown
 * with a list of underlying errors that can be analyzed independently. For unrecoverable errors, it's treated
 * as a classic exception.
 */
public class CompilationException extends RuntimeException {

    public List<Error> errors;
    public String compilationMessages;

    public CompilationException(String message) {
        super(message);
    }

    public CompilationException(String message, Throwable cause) {
        super(message, cause);
    }

    public CompilationException(Throwable cause) {
        super(cause);
    }

    public CompilationException(List<Error> errors) {
        super();
        StringBuffer msg = new StringBuffer();
        for (Error error : errors)
            msg.append(error.line).append(":").append(error.column).append(" ").append(error.message).append("\n");
        this.compilationMessages = msg.toString();
        this.errors = errors;
    }

    @Override
    public String getMessage() {
        return compilationMessages == null ? super.getMessage() : compilationMessages;
    }

    public static class Error {
        public int line;
        public int column;
        public String message;
        public Exception recognitionException;

        public Error(int line, int column, String message, Exception e) {
            this.line = line;
            this.column = column;
            this.message = message;
            this.recognitionException = e;
        }
    }

}
