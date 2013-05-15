#!/usr/bin/env python

import ply.lex as lex
import ply.yacc as yacc

__all__ = ['parser', 'PlyException']

class PlyException(Exception):
    pass

tokens = (
        'LPAREN',
        'RPAREN',
        'CARD',
        'AND',
        'OR'
        )

t_LPAREN = r'\('
t_RPAREN = r'\)'
t_CARD = r'[^\(\)\&\|]+'
t_AND = r'\&'
t_OR = r'\|'

def t_error(t):
    raise PlyException("Illegal character '%s'" % t.value[0])

lexer = lex.lex()

def p_lparen_expression_rparen(p):
    'expression : LPAREN expression RPAREN'
    p[0] = [t_AND, p[2]]

def p_expression_and_expression(p):
    'expression : expression AND expression'
    if p[1][0] == t_AND and p[3][0] == t_AND:
        p[0] = p[1] + p[3][1:]
    else:
        p[0] = [t_AND, p[1], p[3]]

def p_expression_or_expression(p):
    'expression : expression OR expression'
    if (p[1][0] == t_OR or len(p[1]) == 2) and (p[3][0] == t_OR or len(p[3]) == 2):
        p[0] = [t_OR]
        p[0].extend(p[1][1:])
        p[0].extend(p[3][1:])
    else:
        p[0] = [t_OR, p[1], p[3]]

def p_card(p):
    'expression : CARD'
    p[0] = [t_AND, p[1].strip()]

def p_error(p):
    raise PlyException("Error parsing '%s'." % p)

parser = yacc.yacc()

if __name__ == '__main__':
    from sys import argv
    print parser.parse(argv[1])
