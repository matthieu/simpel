"""
Pygments syntax highlighting for SimPEL
"""

from setuptools import setup

entry_points = """
[pygments.lexers]
simpelexer = intalio.highsimpelex:SimPELLexer
"""

setup(
  name         = 'highsimpelex',
  version      = '0.1',
  description  = "An highlight lexer for the SimPEL language.",
  author       = "Matthieu Riou",
  packages     = ['intalio'],
  entry_points = entry_points
) 
