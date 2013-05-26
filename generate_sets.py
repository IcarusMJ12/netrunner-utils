#!/usr/bin/env python

"""
Generates o8c files from OCTGN card set metadata and card images.
"""

from os import listdir, mkdir, unlink, walk
from os.path import join, splitext
from tempfile import mkdtemp
from zipfile import ZipFile

from git.repo import Repo
from Levenshtein import ratio

from card_set import octgnSetToDict
from match import findBestMatch

class CardSetGenerator(object):
    def __init__(self, cardset_prefix, image_path):
        self._image_path = image_path
        self._prefix = cardset_prefix
        self._haystack = dict([(unicode(splitext(straw)[0]), straw) for straw in listdir(image_path)])
        self._haystack_keys = self._haystack.keys()

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
                card_name = '-'.join(card['name'].lower().split(' '))
                if len(card['subtitle']):
                    card_name += '-' + '-'.join(card['subtitle'].lower().split(' '))
                match = findBestMatch(card_name, self._haystack_keys)
                r = ratio(card_name, match)
                if r < 0.95:
                    print card_name, match, r
                assert(r > 0.8)
                match = self._haystack[match]
                ext = splitext(match)[-1]
                f.write(join(self._image_path, match), join(path, card_id + ext))

def main():
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('anr_repo', help='Path to the OCTN ANR plugin repository.')
    parser.add_argument('card_images', help='Path to card images.  Images should be named after card names.')
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

    gen = CardSetGenerator('ANR_', args.card_images)
    for path in walk(card_sets):
        if len(path[-1]) > 0 and path[-1][0] == 'set.xml' and not path[0].endswith('Markers'):
            gen.generateSet(octgnSetToDict(join(card_sets, path[0], path[-1][0])), args.out)

if __name__ == '__main__':
    main()
