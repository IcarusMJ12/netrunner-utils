#!/usr/bin/env python

"""
Generates o8c files from OCTGN card set metadata and card images.
"""

from json import load as json_load
from os import listdir, mkdir, unlink, walk
from os.path import join, splitext
from zipfile import ZipFile

class CardSetGenerator(object):
    def __init__(self, image_path, cardset_prefix='ANR_'):
        self._image_path = image_path
        self._image_map = dict([(splitext(image)[0], image) for image in listdir(self._image_path)])
        self._prefix = cardset_prefix

    def generateSet(self, set_data, out_path):
        path = join(set_data[0]['game_id'], 'Sets', set_data[0]['set_id'], 'Cards')
        o8c_path = join(out_path, self._prefix + '_'.join(set_data[0]['set_name'].split(' ')) + '.o8c')
        try:
            unlink(o8c_path)
        except OSError as e:
            if e.errno != 2: #2 is no such file/directory
                raise
        with ZipFile(o8c_path, 'w') as f:
            for card in set_data:
                card_id = card['card_id']
                image_src = self._image_map[card_id]
                ext = splitext(image_src)[-1]
                f.write(join(self._image_path, image_src), join(path, card['id'] + ext))

def main():
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cards_path', help='Path to the card metadata generated with fetch_cards.py.')
    parser.add_argument('out', help='Path where to save card sets.')
    args = parser.parse_args()

    try:
        mkdir(args.out)
    except OSError as e:
        if e.errno != 17: #17 is file exists
            raise

    with open(join(args.cards_path, 'cards.json'), 'r') as f:
        cards_info = json_load(f)
    cards = cards_info['cards']
    cards = [card for card in cards if 'set_id' in card]
    sets = set([card['set_id'] for card in cards])

    gen = CardSetGenerator(args.cards_path)
    for s in sets:
        gen.generateSet([card for card in cards if card['set_id'] == s], args.out)

if __name__ == '__main__':
    main()
