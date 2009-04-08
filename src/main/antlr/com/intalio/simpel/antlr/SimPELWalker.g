tree grammar SimPELWalker;

options {
    tokenVocab=SimPEL;
    ASTLabelType=LinkedListTree;
}
tokens {
    XML_ELEMENT; XML_ATTRIBUTE; XML_NAME; XML_ATTRIBUTE_VALUE; XML_TEXT; XML_WS; XML_COMMENT; XML_CDATA; XML_PI;
}
scope BPELScope { OScope oscope; }
scope Parent { OBuilder.StructuredActivity activity; }
scope ReceiveBlock { OComm activity; boolean replied; }
scope ExprContext { SimPELExpr expr; }

@header {
package com.intalio.simpel.antlr;
import uk.co.badgersinfoil.e4x.antlr.LinkedListTree;
import uk.co.badgersinfoil.e4x.antlr.LinkedListToken;
import com.intalio.simpel.ErrorListener;
import com.intalio.simpel.omodel.OBuilder;
import com.intalio.simpel.omodel.SimPELExpr;
import org.apache.ode.bpel.rtrep.v2.*;
import org.apache.log4j.Logger;
}

@members {
    // Grammar level members

    private static final Logger __log = Logger.getLogger(SimPELWalker.class);

    public void displayRecognitionError(String[] tokenNames, RecognitionException e) {
    	  __log.debug("Tree grammar error " + e.line + ":" + e.charPositionInLine + " " + getErrorMessage(e, tokenNames));
    }
    
    public String getErrorMessage(RecognitionException e, String[] tokenNames) {
      	List stack = getRuleInvocationStack(e, this.getClass().getName());
    	  String msg = null;
    	  if ( e instanceof NoViableAltException ) {
       	    NoViableAltException nvae = (NoViableAltException)e;
       	    msg = " no viable alt; token="+e.token+" (decision="+nvae.decisionNumber+" state "+nvae.stateNumber+")"+
                  " decision=<<"+nvae.grammarDecisionDescription+">>";
        } else {
           msg = super.getErrorMessage(e, tokenNames);
        }
        return stack+" "+msg;
    }
    
    public String getTokenErrorDisplay(Token t) {
        return t.toString();
    }
    
    // Lamguage level members
    
    private OBuilder builder;

    public OBuilder getBuilder() {
	    return builder;
    }
    public void setBuilder(OBuilder builder) {
	      this.builder = builder;
    }

    private String text(org.antlr.runtime.tree.Tree t) {
    	  if (t == null) return null;
    	  else return t.getText();
    }

    private String deepText(org.antlr.runtime.tree.Tree t) {
    	LinkedListTree llt = ((LinkedListTree)t);
    	StringBuffer b = new StringBuffer();
    	LinkedListToken tok = ((LinkedListTree)t).getStartToken();
    	b.append(tok.getText());
    	while(tok != llt.getStopToken() && (tok = tok.getNext()) != null)
	    if (tok.getText() != null) b.append(tok.getText());
        return b.toString();
    }

}

program	:	^(ROOT declaration+);
declaration
	:	process | namespace;

namespace
	:	^(NAMESPACE ID STRING);

// Process
process
scope BPELScope, Parent;
	:	^(PROCESS ^(NS pr=ID? nm=ID) 
		{ OBuilder.StructuredActivity<OScope> scope = builder.buildProcess(text($pr), text($nm));
		  $BPELScope::oscope = scope.getOActivity(); 
		  $Parent::activity = scope;
		} 
		body);

proc_stmt
	:	pick | flow | if_ex | while_ex | until_ex | foreach | forall | try_ex | scope_ex | with_ex
		| invoke | receive | request | get | reply | assign | throw_ex | wait_ex | exit 
		| signal | join | variable | partner_link | funct_call;
block
scope Parent;
	:	^(SEQUENCE 
		{ OBuilder.StructuredActivity seq = builder.build(OSequence.class, $BPELScope::oscope, $Parent[-1]::activity); 
		  $Parent::activity = seq;
		}
		proc_stmt+);
param_block
scope Parent;
	:	^(SEQUENCE ids+=ID+
		{ OBuilder.StructuredActivity seq = builder.build($ID, OSequence.class, $BPELScope::oscope, $Parent[-1]::activity);
		  $Parent::activity = seq;
          for (Object c : $ids) {
              builder.setBlockParam($BPELScope::oscope, (OSequence)seq.getOActivity(), ((Tree)c).getText());
          }
		}
		proc_stmt+);
body	:	block | proc_stmt;
		

// Structured activities
pick	
	:	^(PICK receive* timeout*);
timeout	:	^(TIMEOUT expr block); 

// TODO links
flow	
	:	^(FLOW body+);
signal	:	^(SIGNAL ID expr?);
join	:	^(JOIN ID+ expr?);

if_ex	
scope ExprContext, Parent;
	:	^(IF {
        $ExprContext::expr = new SimPELExpr(builder.getProcess());
    }
    e=(expr) {
        $ExprContext::expr.setExpr(deepText($e));
        OBuilder.StructuredActivity<OSwitch> oswitch = builder.build($e, OSwitch.class,
            $BPELScope::oscope, $Parent[-1]::activity, $ExprContext::expr);
        $Parent::activity = oswitch;
        $ExprContext::expr = null;
    } b1=(body)
    (^(ELSE b2=(body)))?);

while_ex
scope ExprContext, Parent;
	:	^(WHILE {
        $ExprContext::expr = new SimPELExpr(builder.getProcess());
    }
    e=(expr) {
        $ExprContext::expr.setExpr(deepText($e));
        OBuilder.StructuredActivity<OWhile> owhile = builder.build($e, OWhile.class,
            $BPELScope::oscope, $Parent[-1]::activity, $ExprContext::expr);
        $Parent::activity = owhile;
    }
    body);

until_ex
scope ExprContext;
	:	^(UNTIL expr body);

foreach	
	:	^(FOREACH ID init=expr cond=expr assign body);
forall	
	:	^(FORALL ID from=expr to=expr body);

try_ex
scope BPELScope;
	:	^(TRY {
            OBuilder.StructuredActivity<OScope> oscope = builder.build(OScope.class, $BPELScope[-1]::oscope, $Parent::activity);
            $BPELScope::oscope = oscope.getOActivity();
        }
        body catch_ex*);
catch_ex:	^(CATCH ^(NS ID ID?) param_block);

scope_ex
scope BPELScope, Parent;
	:	^(SCOPE {
            OBuilder.StructuredActivity<OScope> oscope = builder.build(OScope.class, $BPELScope[-1]::oscope, $Parent[-1]::activity);
            $BPELScope::oscope = oscope.getOActivity();
            $Parent::activity = oscope;
        }
	    ID? body scope_stmt*);
scope_stmt
	:	onevent | onalarm | compensation | onquery | onrec | onupd;

onevent	:	^(ONEVENT ID ID param_block);
onalarm	:	^(ONALARM expr body);
onquery
scope ReceiveBlock, Parent;
    :	^(ONQUERY ID {
            OBuilder.StructuredActivity<OEventHandler.OEvent> on = builder.build($ID, OEventHandler.OEvent.class,
                $BPELScope::oscope, $Parent[-1]::activity, deepText($ID), "GET");
            $ReceiveBlock::activity = (OComm) on.getOActivity();
            $Parent::activity = on;
        }
        (block | param_block));
onrec
scope ReceiveBlock, Parent;
    :	^(ONRECEIVE ID {
            OBuilder.StructuredActivity<OEventHandler.OEvent> on = builder.build($ID, OEventHandler.OEvent.class,
                $BPELScope::oscope, $Parent[-1]::activity, deepText($ID), "POST");
            $ReceiveBlock::activity = (OComm) on.getOActivity();
            $Parent::activity = on;
        }
        (block | param_block));
onupd
scope ReceiveBlock, Parent;
    :	^(ONUPDATE ID {
            OBuilder.StructuredActivity<OEventHandler.OEvent> on = builder.build($ID, OEventHandler.OEvent.class,
                $BPELScope::oscope, $Parent[-1]::activity, deepText($ID), "PUT");
            $ReceiveBlock::activity = (OComm) on.getOActivity();
            $Parent::activity = on;
        }
        (block | param_block));
compensation
	:	^(COMPENSATION body);

with_ex 
scope ExprContext;
	: ^(WITH {
        $ExprContext::expr = new SimPELExpr(builder.getProcess());
    }
    with_map+ body);
with_map:       ^(MAP ID path_expr);

// Simple activities

invoke
scope ReceiveBlock;
    :	^(INVOKE ^(p=ID o=ID in=ID?)) {
            OBuilder.StructuredActivity<OInvoke> inv = builder.build($p, OInvoke.class, $BPELScope::oscope,
                $Parent::activity, text($p), text($o), text($in), null);
            $ReceiveBlock::activity = inv.getOActivity();
        }
        (prb=(param_block))?;

reply	
  :	^(REPLY (msg=ID (pl=ID (op=ID)?)?)?) {
      if (ReceiveBlock_stack.size() > 0) {
        builder.build($msg, OReply.class, $BPELScope::oscope, $Parent::activity,
			      $ReceiveBlock::activity, text($msg), text($pl), text($op));
        $ReceiveBlock::replied = true;
      } else {
        builder.build($msg, OReply.class, $BPELScope::oscope, $Parent::activity,
			      null, text($msg), text($pl), text($op));
	  }
    };
receive	
scope ReceiveBlock;
	:	^(RECEIVE ^(p=ID o=ID? hash_form?) {
	        // The receive input is the lvalue of the assignment expression in which this receive is enclosed (if it is)
	        OBuilder.StructuredActivity<OPickReceive> rec;
	        if (ExprContext_stack.size() > 0)
                rec = builder.build($p, OPickReceive.class, $BPELScope::oscope,
                    $Parent::activity, text($p), text($o), $ExprContext::expr);
            else
                rec = builder.build($p, OPickReceive.class, $BPELScope::oscope,
                    $Parent::activity, text($p), text($o), null);

            if (rec.getOActivity().onMessages.size() > 0)
		        $ReceiveBlock::activity = rec.getOActivity().onMessages.get(0);
            // TODO support for multiple "correlations"
            if ($hash_form.corr != null) builder.addCorrelationMatch(rec.getOActivity(), $hash_form.corr);
		} )
		(prb=(param_block) {
		    // Implicit empty reply
		    if ($ReceiveBlock::activity != null && $ReceiveBlock::replied == false && $ReceiveBlock::activity.isRestful()) {
                builder.build($p, OReply.class, $BPELScope::oscope, $Parent::activity,
                    $ReceiveBlock::activity, null, null, null);
                $ReceiveBlock::replied = true;
		    }
		})?;
request
scope ReceiveBlock, ExprContext;
    :	^(REQUEST {
            $ExprContext::expr = new SimPELExpr(builder.getProcess());
        }
        ^(REQ_BASE e=(expr) (meth=STRING (msg=ID)?)?)) {
            $ExprContext::expr.setExpr(deepText($e));

	        // The request output is the lvalue of the assignment expression in which this request is enclosed (if it is)
	        OBuilder.StructuredActivity<OInvoke> inv;
	        if (ExprContext_stack.size() > 1)
                inv = builder.build($e, OInvoke.class, $BPELScope::oscope,
                    $Parent::activity, $ExprContext::expr, text($meth), text($msg), $ExprContext[-1]::expr);
            else
                inv = builder.build($e, OInvoke.class, $BPELScope::oscope,
                    $Parent::activity, $ExprContext::expr, text($meth), text($msg), null);

            $ReceiveBlock::activity = inv.getOActivity();
        }
        (prb=(param_block))?;

// TODO implement get syntax sugar once we have hash support
get
scope ExprContext;
    : ^(GET_REQ {
        $ExprContext::expr = new SimPELExpr(builder.getProcess());
    } e=(expr) {
        $ExprContext::expr.setExpr(deepText($e));

        $ExprContext::expr = new SimPELExpr(builder.getProcess());
    } (e=(expr) {
        $ExprContext::expr.setExpr(deepText($e));
    } )?);

assign
scope ExprContext;
	:	^(ASSIGN {
        $ExprContext::expr = new SimPELExpr(builder.getProcess());
    }
    lv=(path_expr) {
        $ExprContext::expr.setLValue(deepText($lv));
    }
    rv=(rvalue)) {
        $ExprContext::expr.setExpr(deepText($rv));
        if (!"RESOURCE".equals($rv.getText()) && !"RECEIVE".equals($rv.getText()) && !"REQUEST".equals($rv.getText())) {
		    OBuilder.StructuredActivity<OAssign> assign =
                builder.build($rv, OAssign.class, $BPELScope::oscope, $Parent::activity, $ExprContext::expr);
            // The long, winding road of abstraction
            $ExprContext::expr = (SimPELExpr) ((OAssign.Expression)((OAssign.Copy)assign.
                getOActivity().operations.get(0)).from).expression;
        }
    };
rvalue	:	receive | invoke | request | resource | expr | xmlElement;
	
throw_ex:	^(THROW ns_id);

wait_ex
scope ExprContext;
    :	^(WAIT {
            $ExprContext::expr = new SimPELExpr(builder.getProcess());
        }
        e=(expr)) {
            $ExprContext::expr.setExpr(deepText($e));
		    OBuilder.StructuredActivity<OWait> wait =
                builder.build($e, OWait.class, $BPELScope::oscope, $Parent::activity, $ExprContext::expr);
        };

exit	:	EXIT;

// Other
variable:	^(VARIABLE ID VAR_MODS*) { builder.addVariableDecl($ID, text($ID), text($VAR_MODS)); };

resource
scope ExprContext;
    :   ^(RESOURCE {
        $ExprContext::expr = new SimPELExpr(builder.getProcess());
    }
    e=(expr)? ID?) {
        $ExprContext::expr.setExpr(deepText($e));
        // The resource name is the lvalue of the assignment expression in which this resource def is enclosed
        builder.addResourceDecl($e, $BPELScope::oscope, $ExprContext[-1]::expr.getLValue(), $ExprContext::expr, text($ID));
    };

partner_link
	:	^(PARTNERLINK ID+);

hash_form
returns [List corr]
	:	^(HASH (key_val {
	        corr = $key_val.res;
	    } )+);
key_val
returns [List res]
	:	^(HASH_KV fn=ID var=ID) {
	        res = new ArrayList(2);
	        res.add(deepText($fn));
	        res.add(deepText($var));
	    };

// XML
xmlElement
	:	^(XML_EMPTY_ELEMENT XML_NAME xmlAttribute*) | ^(XML_ELEMENT XML_NAME xmlAttribute* xmlElementContent*);
xmlAttribute
	:	^(XML_ATTRIBUTE XML_NAME XML_ATTRIBUTE_VALUE) { System.out.println("ATTR " + $XML_NAME.text); };
xmlElementContent
	:	xmlMarkup | xmlText | xmlElement | s_expr;
xmlText :	XML_TEXT | XML_NAME | XML_WS;
xmlMarkup
	:	XML_COMMENT | XML_CDATA | XML_PI;

// Expressions
expr	:	s_expr;

funct_call
@init { boolean inAssign = true; ArrayList exprs = new ArrayList(); }
	:	^(CALL {
	        if (ExprContext_stack.size() == 0 || ((ExprContext_scope)ExprContext_stack.peek()).expr == null) {
	            inAssign = false;
                ExprContext_stack.push(new ExprContext_scope());	            
	            $ExprContext::expr = new SimPELExpr(builder.getProcess());
	        }
	    }
	    ID (e=(expr) { exprs.add($e); })* {
	        if (!inAssign) {
	            // Writing this, I feel dirty. But BPEL assignment forced me to. A simple function call needs to be
	            // wrapped in an assignment, but assignment requires the rvalue to return something. So it's wrapped
	            // in an anonymous function that delegates the call and then returns an empty element.
	            StringBuffer fcall = new StringBuffer("(function() {");
	            fcall.append($ID.getText()).append("(");
                for (Object c : exprs) {
                    fcall.append(deepText((Tree)c)).append(",");
                }

	            $ExprContext::expr.setExpr(fcall.toString().substring(0, fcall.toString().length() -1)
	                + "); return <empty/>; } )()");
                OBuilder.StructuredActivity<OAssign> assign =
                    builder.build($ID, OAssign.class, $BPELScope::oscope, $Parent::activity, $ExprContext::expr);
                // The long, winding road of abstraction
                $ExprContext::expr = (SimPELExpr) ((OAssign.Expression)((OAssign.Copy)assign.
                    getOActivity().operations.get(0)).from).expression;
                ExprContext_stack.pop();
	        }
	    } );
path_expr
	:	^(PATH {
	        StringBuffer buff = new StringBuffer();
	    }
	    (i=ns_id {
	        if (buff.length() > 0) buff.append(".");
	        buff.append($i.qid);
	    } )+)

	    (p=predicate { buff.append($p.pred); } )?
	    {
            builder.addExprVariable($BPELScope::oscope, $ExprContext::expr, buff.toString());
        };
ns_id
returns [String qid]
    :	^(NS p=ID? n=ID) { qid = p == null ? n.getText() : (p.getText() + "::" + n.getText()); };

predicate
returns [String pred]
    : ^(PRED e=(expr)) { pred = deepText($e); };

s_expr	:	^('==' s_expr s_expr) 
	|	^('!=' s_expr s_expr) 
	|	^('<' s_expr s_expr) 
	|	^('>' s_expr s_expr) 
	|	^('>=' s_expr s_expr) 
	|	^('<=' s_expr s_expr) 
	|	^('+' s_expr s_expr) 
	|	^('-' s_expr s_expr?) 
	|	^('*' s_expr s_expr) 
	|	^('/' s_expr s_expr) 
	|	^('&&' s_expr s_expr)
	|	^('||' s_expr s_expr) 
	|	^('!' s_expr)
	|	path_expr | INT | STRING | funct_call;
