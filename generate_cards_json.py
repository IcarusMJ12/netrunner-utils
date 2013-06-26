#!/usr/bin/env python

"""
Assigns the raw card data json to a variable for use with javascript.
"""

RAW_CARD_DATA_VAR = 'raw_card_data'

if __name__ == '__main__':
    from argparse import ArgumentParser
    from os.path import join

    parser = ArgumentParser(description=__doc__)
    parser.add_argument('cards_path', help="Path where card metadata resides.")
    parser.add_argument('javascript_path', help="Path to the javascript file.")
    parser.add_argument('variable_name', default=RAW_CARD_DATA_VAR, nargs='?', help="Name of the javascript variable (defaults to '" + RAW_CARD_DATA_VAR + "').")
    args = parser.parse_args()

    with open(join(args.cards_path, 'cards.json'), 'r') as fr:
        with open(args.javascript_path, 'w') as fw:
            fw.write('var ' + args.variable_name + ' = ' + fr.read())
