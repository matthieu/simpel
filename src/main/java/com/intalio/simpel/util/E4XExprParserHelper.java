package com.intalio.simpel.util;

import uk.co.badgersinfoil.e4x.E4XExpressionParser;
import uk.co.badgersinfoil.e4x.antlr.*;
import org.antlr.runtime.TokenSource;
import org.antlr.runtime.CharStream;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.ANTLRReaderStream;
import com.intalio.simpel.antlr.SimPELParser;
import com.intalio.simpel.antlr.SimPELLexer;
import com.intalio.simpel.ErrorListener;

import java.io.StringReader;
import java.io.IOException;
import java.io.Reader;

public class E4XExprParserHelper implements E4XExpressionParser {

    private ErrorListener el;

    public LinkedListTree parseSubExpression(TokenSource lexer, CharStream cs,
                 LinkedListTokenStream stream) throws RecognitionException {
        String tail = cs.substring(cs.index(), cs.size()-1);
        int initialTailLength = tail.length();
        SimPELParser parser;
        try {
            parser = xmlextParserOn(new StringReader(tail), stream);
        } catch (IOException e) {
            // TODO: better exception type?
            throw new RuntimeException(e);
        }
        LinkedListTree ast = (LinkedListTree) parser.e4x_expr().getTree();
        tail = parser.getInputTail();
        // skip over the XML in the original, underlying CharStream
        cs.seek(cs.index() + (initialTailLength - tail.length()));
        LinkedListTokenSource source = (LinkedListTokenSource)stream.getTokenSource();
        stream.setTokenSource(source);  // cause any remembered E4X state to be dropped
        stream.scrub(1); // erase the subsequent token that the E4X parser got from this stream
        source.setDelegate(lexer);
        return ast;
    }

    private SimPELParser xmlextParserOn(Reader in, LinkedListTokenStream stream) throws IOException {
        ANTLRReaderStream cs = new ANTLRReaderStream(in);
        SimPELLexer lexer = new SimPELLexer(cs);
        LinkedListTokenSource source = (LinkedListTokenSource)stream.getTokenSource();
        source.setDelegate(lexer);

        // The main grammar will see the initial '<' as an LT (less-than)
        // token, and lookahead in the AS3Parser will have already
        // grabbed references to that token in order to make it the
        // startToken for various AST subtrees, so we can't just delete
        // it.  We therefore find the LT token and change its type to
        // match the E4X vocabulary, and then rewind the token stream
        // so that this will be the first token that the E4XParser will
        // see.
        LinkedListToken startMarker = (LinkedListToken)stream.LT(-1);
        startMarker.setType(SimPELParser.L_CURLY);
        stream.seek(stream.index()-1);

        SimPELParser parser = new SimPELParser(stream);
        parser.setTreeAdaptor(new LinkedListTreeAdaptor());
        parser.setInput(lexer, cs);
        parser.setErrorListener(el);

        return parser;
    }

    public void setErrorListener(ErrorListener el) {
        this.el = el;
    }

}
