#!/usr/bin/env python
"""
Prints probabilities of drawing requested cards.
"""

from compiler.ast import flatten
from copy import deepcopy
from random import shuffle
from sys import stderr

from card_expression import parser as expression_parser, PlyException, t_OR, t_AND

def reduceExpression(card, expression, depth=0):
    # trivial case
    if expression is True:
        return False, True

    # found string, reducing to trivial case if match
    if isinstance(expression, str):
        if card == expression:
            return True, True
        return False, expression

    # iterating otherwise
    expr_type = expression[0]
    assert(expr_type in (t_OR, t_AND))
    for expr_count in xrange(len(expression) - 1):
        found, expression[expr_count + 1] = reduceExpression(card, expression[expr_count + 1], depth + 1)
        # if anything is true, the entire expression is true for OR
        if found is True and expression[expr_count + 1] is True and expr_type == t_OR:
            return found, True
        # otherwise we only return true if every subexpression is also true
        elif found is True:
            if reduce(lambda x, y: x is True and y is True, expression[1:]):
                return found, True
            return found, expression
    return False, expression

def matchesExpression(hand, expression):
    expression = deepcopy(expression)
    #print hand
    for card_index in xrange(len(hand)):
        found, expression = reduceExpression(hand[card_index], expression)
        #print found, expression
        if expression is True:
            return card_index + 1
    return -1

def asciify(string):
    return ''.join([ch for ch in string if ord(ch) < 128])

def main():
    from argparse import ArgumentParser

    parser = ArgumentParser(description=__doc__)
    parser.add_argument('deck_file')
    parser.add_argument('cards_expression')
    parser.add_argument('-c', '--count', type=int, default=1000)
    args = parser.parse_args()

    deck = []
    expression = None
    results = {}

    print >>stderr, "Loading deck...",
    with open(args.deck_file) as f:
        for line in f:
            line = line.strip().split(' ', 1)
            if len(line) > 1 and line[0][1] == 'x':
                for i in xrange(int(line[0][0])):
                    deck.append(asciify(line[1]).strip().lower())
    #deck = ['cell portal', 'edge of world', 'whirlpool', 'braintrust', 'bullfrog', 'braintrust', 'popup window', 'pad campaign', 'edge of world', 'fetal ai', 'popup window', 'nisei mkii', 'pad campaign', 'neural katana', 'snare', 'hunter', 'edge of world', 'private security force', 'snare', 'private security force', 'whirlpool', 'cell portal', 'project junebug', 'pad campaign', 'fetal ai', 'hokusai grid', 'hunter', 'nisei mkii', 'neural katana', 'braintrust', 'project junebug', 'chum', 'marked accounts', 'project junebug', 'hokusai grid', 'bullfrog', 'chum', 'neural katana', 'akitaro watanabe', 'hunter', 'fetal ai', 'whirlpool', 'akitaro watanabe', 'bullfrog', 'marked accounts', 'chum', 'marked accounts', 'popup window', 'snare']
    print >>stderr, "OK"

    print >>stderr, "Parsing card expression...",
    expression = expression_parser.parse(args.cards_expression)
    print >>stderr, expression,
    keywords = set(flatten(expression))
    keywords -= set([t_OR, t_AND])
    for k in keywords:
        if k not in deck:
            print >>stderr, k, "not in deck! Aborting."
            return 1
    print >>stderr, "OK"
    
    """
    result = matchesExpression(deck, expression)
    try:
        results[result] += 1
    except KeyError:
        results[result] = 1
    """
    for iteration in xrange(args.count):
        shuffle(deck)
        result = matchesExpression(deck, expression)
        try:
            results[result] += 1
        except KeyError:
            results[result] = 1
    
    keys = results.keys()
    keys.sort()
    total = 0
    for k in keys:
        total += results[k]
        print k, float(total)/args.count

if __name__ == '__main__':
    main()
