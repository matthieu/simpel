grammar SimPEL;

options {
    output=AST; 
    language=Java;
    ASTLabelType=LinkedListTree;
}
tokens {
    ROOT; PROCESS; PICK; SEQUENCE; FLOW; IF; ELSEIF; ELSE; WHILE; UNTIL; FOREACH; FORALL; INVOKE;
    RECEIVE; REPLY; ASSIGN; THROW; WAIT; EXIT; TIMEOUT; TRY; CATCH; CATCH_ALL; SCOPE; EVENT;
    RESOURCE;
    REQUEST; REQ_BASE; GET_REQ; ONEVENT; ONALARM; ONRECEIVE; ONUPDATE; ONQUERY; COMPENSATION; COMPENSATE;
    HASH; HASH_KV; PARTNERLINK; VARIABLE; BLOCK_PARAM;
    SIGNAL; JOIN; WITH; MAP;
    EXPR; EXT_EXPR; XML_LITERAL; CALL; NAMESPACE; NS; PATH; XML; PRED;
}

@lexer::header {
package com.intalio.simpel.antlr;
import com.intalio.simpel.ErrorListener;
import com.intalio.simpel.util.ErrorMessageBuilder;
}

@parser::header {
package com.intalio.simpel.antlr;

import uk.co.badgersinfoil.e4x.antlr.LinkedListTokenStream;
import uk.co.badgersinfoil.e4x.antlr.LinkedListTree;
import uk.co.badgersinfoil.e4x.E4XHelper;
import uk.co.badgersinfoil.e4x.E4XRecognitionException;
import com.intalio.simpel.ErrorListener;
import com.intalio.simpel.util.ErrorMessageBuilder;
import com.intalio.simpel.util.JSHelper;
}

@lexer::members {
    private ErrorListener el;

    public void setErrorListener(ErrorListener el) {
    	this.el = el;
    }
    public void displayRecognitionError(String[] tokenNames, RecognitionException e) {
    	el.reportRecognitionError(e.line, e.charPositionInLine, getErrorMessage(e, tokenNames), e);
    }
    public String getErrorMessage(RecognitionException e, String[] tokenNames) {
        String msg = ErrorMessageBuilder.msg(e, tokenNames, null);
        if (msg == null) msg = super.getErrorMessage(e, tokenNames);
        return msg;
    }
}

@parser::members {
    public static final int CHANNEL_PLACEHOLDER = 999;

    private SimPELLexer lexer;
    private CharStream cs;
    private ErrorListener el;
    private Stack paraphrases = new Stack();
    private E4XHelper e4xHelper;

    public void setInput(SimPELLexer lexer, CharStream cs) {
        this.lexer = lexer;
        this.cs = cs;
    }
    public void setErrorListener(ErrorListener el) {
    	this.el = el;
    }
    public void setE4XHelper(E4XHelper h) {
        e4xHelper = h;
    }

    /** Handle 'island grammar' for embeded XML-literal elements. */
    private LinkedListTree parseXMLLiteral() throws RecognitionException {
        return e4xHelper.parseXMLLiteral(lexer, cs, (LinkedListTokenStream)input);
    }
    /** Handle 'island grammar' for embeded JavaScript-literal elements. */
    private LinkedListTree parseJSLiteral() throws RecognitionException {
        return JSHelper.parseJSLiteral(lexer, cs, (LinkedListTokenStream)input);
    }
    
    public void displayRecognitionError(String[] tokenNames, RecognitionException e) {
        el.reportRecognitionError(e.line, e.charPositionInLine, getErrorMessage(e, tokenNames), e);
    }
    
    public String getErrorMessage(RecognitionException e, String[] tokenNames) {
        if (paraphrases.size() == 0) return super.getErrorMessage(e, tokenNames);
        String msg = ErrorMessageBuilder.msg(e, tokenNames, (String) paraphrases.peek());
        if (msg == null) msg = super.getErrorMessage(e, tokenNames);
        return msg;
    }
    
    public String getTokenErrorDisplay(Token t) {
        return t.toString();
    }

    /**
     * Returns the input left unconsumed after the last parse operation.
     * Because of lookahead in the parser, there is no guarantee that the
     * lexer has not consumed input ahead of the current parse-point for
     * any abritrary rule. This method is only intended to grab the
     * remaining input after recognising 'xmlPrimary'.
     */
    public String getInputTail() {
        return cs.substring(cs.index()-1, cs.size()-1);
    }

}

// MAIN BPEL SYNTAX

program	:	declaration+ -> ^(ROOT declaration+);
declaration
	:	funct | process | namespace;

// Process
process	:	'process' ns_id body -> ^(PROCESS ns_id body);

proc_stmt
@init { paraphrases.push("in a process"); }
@after { paraphrases.pop(); }
	:	pick | flow | if_ex | while_ex | until_ex | foreach | forall | try_ex | scope_ex | with_ex
		| receive | request | invoke | ((reply | assign | throw_ex | wait_ex | exit | get  
		| signal | join | variables | partner_link | funct_call) SEMI!);

block
@init { paraphrases.push("in a block of statements"); }
@after { paraphrases.pop(); }
        :	'{' proc_stmt+ '}' -> ^(SEQUENCE proc_stmt+);

param_block
@init { paraphrases.push("in a parameterized block of statements"); }
@after { paraphrases.pop(); }
	:	'{' ('|' in+=ID (',' in+=ID)* '|')? proc_stmt+ '}' -> ^(SEQUENCE $in* proc_stmt+);

body	:	block | proc_stmt;

// Structured activities
pick
@init { paraphrases.push("in a pick"); }
@after { paraphrases.pop(); }
        :	'pick' '{' receive* timeout* '}' -> ^(PICK receive* timeout*);

timeout
@init { paraphrases.push("in a timeout"); }
@after { paraphrases.pop(); }
        :	'timeout' '(' expr ')' block -> ^(TIMEOUT expr block);

flow
@init { paraphrases.push("in a flow"); }
@after { paraphrases.pop(); }
        :	'parallel' b+=body ('and' b+=body)* -> ^(FLOW $b*);
signal	:	'signal' '('ID (',' expr)? ')' -> ^(SIGNAL ID expr?);
join
        :	'join' '(' k+=ID (',' k+=ID)* (',' expr)? ')' -> ^(JOIN $k+ expr?);

if_ex
@init { paraphrases.push("in a if expression"); }
@after { paraphrases.pop(); }
        :	'if' '(' expr ')' ifb=body ('else' eb=body)? -> ^(IF expr $ifb (^(ELSE $eb))?);

while_ex
@init { paraphrases.push("in a while"); }
@after { paraphrases.pop(); }
        :	'while' '(' expr ')' body -> ^(WHILE expr body);

until_ex
@init { paraphrases.push("in an until"); }
@after { paraphrases.pop(); }
        :	'do' body 'until' '(' expr ')' -> ^(UNTIL expr body);

foreach
@init { paraphrases.push("in a foreach loop"); }
@after { paraphrases.pop(); }
        :	'for' '(' ID '=' init=expr ';' cond=expr ';' assign ')' body -> ^(FOREACH ID $init $cond assign body);
forall
@init { paraphrases.push("in a forall loop"); }
@after { paraphrases.pop(); }
        :	'forall' '(' ID '=' from=expr ';r' to=expr ')' body -> ^(FORALL ID $from $to body);

try_ex
@init { paraphrases.push("in a try block"); }
@after { paraphrases.pop(); }
        :	'try' body catch_ex* -> ^(TRY body catch_ex*);
catch_ex
@init { paraphrases.push("in a catch block"); }
@after { paraphrases.pop(); }
        :	'catch' '(' ns_id ')' param_block -> ^(CATCH ns_id param_block);

scope_ex
@init { paraphrases.push("in a scope declaration"); }
@after { paraphrases.pop(); }
        :	'scope' ('(' ID ')')? body scope_stmt* -> ^(SCOPE ID? body scope_stmt*);
scope_stmt
    	:	onevent | onalarm | compensation | onquery | onrec | onupd;

onevent
@init { paraphrases.push("in an onEvent"); }
@after { paraphrases.pop(); }
        :	'onEvent' '(' p=ID ',' o=ID ')' param_block -> ^(ONEVENT $p $o param_block);
onalarm
@init { paraphrases.push("in an onAlarm"); }
@after { paraphrases.pop(); }
        :	'onAlarm' '(' expr ')' body -> ^(ONALARM expr body);
onquery
@init { paraphrases.push("in an onQuery"); }
@after { paraphrases.pop(); }
        :	'onQuery' '(' r=ID ')' param_block -> ^(ONQUERY $r param_block);
onrec
@init { paraphrases.push("in an onReceive"); }
@after { paraphrases.pop(); }
        :	'onReceive' '(' r=ID ')' param_block -> ^(ONRECEIVE $r param_block);
onupd
@init { paraphrases.push("in an onUpdate"); }
@after { paraphrases.pop(); }
        :	'onUpdate' '(' r=ID ')' param_block -> ^(ONUPDATE $r param_block);

compensation
@init { paraphrases.push("in an compensation"); }
@after { paraphrases.pop(); }
	:	'compensation' body -> ^(COMPENSATION body);

with_ex
@init { paraphrases.push("in a with expression"); }
@after { paraphrases.pop(); }
        : 'with' '(' wm+=with_map (',' wm+=with_map)* ')' body -> ^(WITH $wm+ body);
with_map:       ID ':' path_expr -> ^(MAP ID path_expr);

// Simple activities

invoke : invoke_base param_block -> ^(INVOKE invoke_base) param_block
          | invoke_base SEMI -> ^(INVOKE invoke_base);
invoke_base
@init { paraphrases.push("in an invoke"); }
@after { paraphrases.pop(); }
        :	'invoke' '(' p=ID ',' o=ID (',' in=ID)? ')' -> ^($p $o $in?);

receive	: receive_base param_block -> ^(RECEIVE receive_base) param_block
          | receive_base SEMI -> ^(RECEIVE receive_base);
receive_base
@init { paraphrases.push("in a receive"); }
@after { paraphrases.pop(); }
        : 'receive' '(' p=ID (',' o=ID (',' hash_form)? )? ')' -> ^($p $o? hash_form?);

request
options {backtrack=true;}
        : request_base param_block -> ^(REQUEST request_base) param_block
          | request_base SEMI -> ^(REQUEST request_base);

request_base
@init { paraphrases.push("in a request"); }
@after { paraphrases.pop(); }
        : 'request' '(' expr (',' meth=STRING (',' msg=ID)?)? ')' -> ^(REQ_BASE expr $meth? $msg?);

get     : 'get' '(' path=expr (',' head=expr)? ')' -> ^(GET_REQ $path $head?);

reply
@init { paraphrases.push("in a reply"); }
@after { paraphrases.pop(); } // todo allow expressions in replied element
        : 'reply' '(' (ID (',' ID (',' ID)?)?)? ')' -> ^(REPLY (ID (ID ID?)?)?);

assign
@init { paraphrases.push("in an assignment"); }
@after { paraphrases.pop(); }
        : path_expr '=' rvalue -> ^(ASSIGN path_expr rvalue);

rvalue
@init { paraphrases.push("in an assignment right value"); }
@after { paraphrases.pop(); }
	    : receive_base -> ^(RECEIVE receive_base)
		  | invoke_base -> ^(INVOKE invoke_base)
          | request_base -> ^(REQUEST request_base)
          | resource | expr | xml_literal;
	
throw_ex
@init { paraphrases.push("in a throw"); }
@after { paraphrases.pop(); }
        : 'throw' '('? ns_id ')'? -> ^(THROW ns_id);

wait_ex
@init { paraphrases.push("in a wait"); }
@after { paraphrases.pop(); }

        : 'wait' '('expr')' -> ^(WAIT expr);

compensate
@init { paraphrases.push("in a compensate"); }
@after { paraphrases.pop(); }
	    : 'compensate' ('(' ID ')')? -> ^(COMPENSATE ID?);

exit	:	'exit' -> ^(EXIT);

// Others
namespace
        : 'namespace' ID '=' STRING SEMI -> ^(NAMESPACE ID STRING);

resource
@init { paraphrases.push("in a resource declaration"); }
@after { paraphrases.pop(); }
        : 'resource' '(' expr? (',' ID)? ')' -> ^(RESOURCE expr? ID?);

variables
@init { paraphrases.push("in variable declaration"); }
@after { paraphrases.pop(); }
        : 'var'! v+=variable (','! v+=variable)*;
variable:	ID VAR_MODS* -> ^(VARIABLE ID VAR_MODS*);

partner_link
@init { paraphrases.push("in a partner link declaration"); }
@after { paraphrases.pop(); }
	:	'partnerLink' pl+=ID (',' pl+=ID)* -> ^(PARTNERLINK $pl+);

hash_form
	:	'{' key_val (',' key_val)* '}' -> ^(HASH key_val+);
key_val
	:	k=ID ':' val=ID -> ^(HASH_KV $k $val);

funct	:	'function'^ f=ID '(' ID? (','! ID)* ')' js_block;

// Expressions
expr	:	s_expr;

funct_call
	    :	fn=ID '(' (e+=expr)? (',' e+=expr)* ')' -> ^(CALL ID $e*);
s_expr	:	condExpr;
condExpr:	boolExpr ( ('==' ^|'!=' ^|'<' ^|'>' ^|'<=' ^|'>=' ^) boolExpr )?;
boolExpr:	aexpr (('&&'|'||')^ aexpr )?;
aexpr	:	mexpr (('+'|'-') ^ mexpr)*;
mexpr	:	unary (('*'|'/') ^ unary)*;
unary   :   ((('!'|'-')^)? atom) | STRING;
atom	:	path_expr | INT | '(' s_expr ')' -> s_expr | funct_call;
path_expr
	:	pelmt+=ns_id ('.' pelmt+=ns_id)* predicate? -> ^(PATH $pelmt+);
predicate
    : L_SQUARE expr R_SQUARE -> ^(PRED expr);

ns_id	:	(pr=ID '::')? loc=ID ('(' ')')? -> ^(NS $pr? $loc);

// In-line XML

xml_literal
@init { LinkedListTree xml = null; }
	:	// We have to have the LT in the outer grammar for lookahead
		// to be able to predict that the xmlLiteral rule should be used.
		'<' {
		    try {
    		    xml=parseXMLLiteral();
            } catch (RecognitionException re) {
                 if (re instanceof E4XRecognitionException) {
                     re.line = retval.start.getLine();
                     re.charPositionInLine = retval.start.getCharPositionInLine();
                 }
                 throw re;
            }
		} -> { xml };

e4x_expr
        : L_CURLY! s_expr '}'!;

js_block
@init { LinkedListTree js = null; }
	:	'{' { js=parseJSLiteral(); } -> { js };

// Basic tokens
VAR_MODS:	'unique' | 'external' | ('string' | 'int' | 'float');
SEMI	:	';';
ID	:	(LETTER | '_' ) (LETTER | DIGIT | '_' | '-' )*;
INT	:	(DIGIT )+ ;
STRING	:	'"' ( ESCAPE_SEQ | ~('\\'|'"') )* '"';
ESCAPE_SEQ
	:	'\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\');

L_CURLY: '{';

L_SQUARE: '[';
R_SQUARE: ']';

SL_COMMENTS
	:	'//' .* CR { $channel = HIDDEN; };
CR	:	('\r' | '\n' )+ { $channel = HIDDEN; };
WS	:	( ' ' | '\t' )+ { skip(); };
fragment DIGIT
    :    '0'..'9';
fragment LETTER
    : 'a'..'z' | 'A'..'Z';
