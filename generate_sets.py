#!/usr/bin/env python

"""
Generates o8c files from OCTGN card set metadata and card images.
"""

from ast import literal_eval
from os import listdir, mkdir, unlink, walk
from os.path import join, splitext
from urllib2 import urlopen
from zipfile import ZipFile

from git.repo import Repo

from card_set import octgnSetToDict

NETRUNNERCARDS_BASE = 'http://netrunnercards.info'
NETRUNNERCARDS_URL = 'http://netrunnercards.info/api/search/d:r|c'

class CardSetGenerator(object):
    def __init__(self, cardset_prefix, netrunnercards_info):
        self._cards_info = dict([(card['indexkey'], card) for card in netrunnercards_info])
        self._prefix = cardset_prefix

    def generateSet(self, set_data, out_path):
        path = join(set_data['gameid'], 'Sets', set_data['id'], 'Cards')
        o8c_path = join(out_path, self._prefix + '_'.join(set_data['name'].split(' ')) + '.o8c')
        try:
            unlink(o8c_path)
        except OSError as e:
            if e.errno != 2: #2 is no such file/directory
                raise
        with ZipFile(o8c_path, 'w') as f:
            for card_id, card in set_data['cards'].items():
                match = self._cards_info[card_id[-5:]]
                image_src = match['imagesrc'].replace('\\', '')
                ext = splitext(image_src)[-1]
                f.writestr(join(path, card_id + ext), urlopen(NETRUNNERCARDS_BASE + image_src).read())

def main():
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('anr_repo', help='Path to the OCTN ANR plugin repository.')
    parser.add_argument('out', help='Path where to save card sets.')
    args = parser.parse_args()

    card_sets = join(args.anr_repo, 'o8g', 'Sets')

    try:
        mkdir(args.out)
    except OSError as e:
        if e.errno != 17: #17 is file exists
            raise

    r = Repo(args.anr_repo)
    r.remotes.origin.pull()

    cards_info = literal_eval(urlopen(NETRUNNERCARDS_URL).read())

    gen = CardSetGenerator('ANR_', cards_info)
    for path in walk(card_sets):
        if len(path[-1]) > 0 and path[-1][0] == 'set.xml' and not path[0].endswith('Markers'):
            gen.generateSet(octgnSetToDict(join(card_sets, path[0], path[-1][0])), args.out)

if __name__ == '__main__':
    main()
