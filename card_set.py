#!/usr/bin/env python
"""Converts an OCTGN card set to a dict."""

__all__ = ['octgnSetToDict']

# mac terminal unicode errors? export LC_ALL=en_US.UTF-8

from xml.dom import minidom

def octgnSetToDict(f):
    result = {}
    cards = {}
    result['cards'] = cards

    doc = minidom.parse(f)
    set_meta = dict(doc.getElementsByTagName('set')[0].attributes.items())
    for k, v in set_meta.items():
        result[k.lower()] = v

    for card in doc.getElementsByTagName('card'):
        attributes = dict(card.attributes.items())
        properties = dict([(prop.attributes['name'].value.lower(), prop.attributes['value'].value) for prop in card.getElementsByTagName('property')])
        cards[attributes['id']] = properties
        cards[attributes['id']]['name'] = attributes['name']
    
    return result

def main():
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('card_set', help='Path to an OCTN card set.')
    args = parser.parse_args()

    for k, v in octgnSetToDict(args.card_set).items():
        print k, v

if __name__ == '__main__':
    main()
