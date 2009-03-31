from pygments.lexer import RegexLexer, bygroups
from pygments.token import *

import re

class SimPELLexer(RegexLexer):
    """
    For SimPEL source code.
    """

    name = 'SimPEL'
    aliases = ['simpel']
    filenames = ['*.simpel']
    mimetypes = ['application/x-simpel']

    flags = re.DOTALL
    tokens = {
        'root': [
            (r'//.*?\n', Comment),
            (r'/\*.*?\*/', Comment),
            (r'\|.*?\|', Name.Variable),
            (r'</?[^>]+/?>', Name.Tag),
            (r'[{}\[\]();.]+', Punctuation),
            (r'(process)(\s+)([$a-zA-Z_]+)', bygroups(Keyword, Text, Name.Class)),
            (r'(for|while|if|else|throw|try|receive|request|scope|onQuery|'
             r'onReceive|onUpdate|reply|'
             r'catch|var|with|function|new)\b', Keyword),
            (r'(self|processConfig)\b', Name.Builtin),
            (r'(true|false|null)\b', Keyword.Constant),
            (r'[$a-zA-Z_][a-zA-Z0-9_]*', Name.Other),
            (r'[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?', Number.Float),
            (r'0x[0-9a-fA-F]+', Number.Hex),
            (r'[0-9]+', Number.Integer),
            (r'"(\\\\|\\"|[^"])*"', String.Double),
            (r"'(\\\\|\\'|[^'])*'", String.Single),
            (r'[~\^\*!%&\|+=:;,/?\\-]+', Operator),
            (r'\s+', Text),
        ]
    }
