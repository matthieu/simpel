" Vim syntax file
" Language:		SimPEL
" Maintainer:		Apache ODE Developers <dev@ode.apache.org>
" Last Change:		2007 Dec 18
" Original Author:	Matthieu Riou <matthieu@offthelip.org>

if version < 600
  syn clear
elseif exists("b:current_syntax")
  finish
endif

syn keyword simpelCommentTodo		TODO FIXME XXX TBD contained
syn region  simpelString		start=+"+  skip=+\\\\\|\\"+  end=+"+
syn match   simpelNumber	       "-\=\<\d\+L\=\>\|0[xX][0-9a-fA-F]\+\>"
syn match   simpelLineComment		"#.*$"
syn match   simpelBlockParam		"|.*|$"
syn keyword simpelConditional		if else
syn keyword simpelRepeat		while for forall do until
syn keyword simpelParallel		parallel and
syn keyword simpelException		try catch throw
syn keyword simpelBoolean		true false
syn keyword simpelIdentifier		var partnerLink namespace
syn keyword simpelReserved		process scope event alarm compensation pick
syn keyword simpelStatement		invoke receive reply wait compensate exit join signal with

syn keyword simpelFunction      	function
syn match   simpelBraces	   	"[{}\[\]]"
syn match   simpelParens	   	"[()]"


" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_hs_syntax_inits")
  if version < 508
    let did_hs_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink simpelLineComment		Comment
  HiLink simpelCommentTodo		Todo
  HiLink simpelConditional		Conditional
  HiLink simpelRepeat			Repeat
  HiLink simpelParallel			Repeat
  HiLink simpelString			String
  HiLink simpelXML			String
  HiLink simpelBoolean			Boolean
  HiLink simpelException		Exception
  HiLink simpelReserved			Keyword
  HiLink simpelIdentifier		Identifier
  HiLink simpelIdentifier		Identifier
  HiLink simpelFunction			Function
  HiLink simpelBraces			Function
  HiLink simpelParens			Function
  HiLink simpelNumber			Number
  HiLink simpelBlockParam		Label
  HiLink simpelStatement		Statement

  delcommand HiLink
endif

let b:current_syntax = "simpel"
