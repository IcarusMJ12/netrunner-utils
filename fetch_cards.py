#!/usr/bin/env python

"""
Fetch cards from netrunnercards.info and store them in a sqlite database.
"""

from json import load as json_load
from json import loads as json_loads
from json import dump as json_dump
from os import mkdir, walk
from os.path import exists, join, split
from time import time
from urllib2 import HTTPError, Request, urlopen
from wsgiref.handlers import format_date_time

from git.repo import Repo

from card_set import octgnSetToDict

NETRUNNERCARDS_BASE = 'http://netrunnerdb.com'
NETRUNNERCARDS_URL = 'http://netrunnerdb.com/api/search/d:r|c'

_keyname_transform_map = {
        "code": "card_id",
        "setname": "set_name",
        "title": "name",
        "text": "card_text",
        "quantity": "count",
        "uniqueness": "is_unique",
        "advancementcost": "advancement_cost",
        "agendapoints": "agenda_points",
        "trash": "trash_cost",
        "factioncost": "influence",
        "baselink": "base_link",
        "influencelimit": "influence_limit",
        "minimumdecksize": "min_deck_size",
        "memoryunits": "memory_cost"
        }

def renameCardKeys(card):
    for key in card.keys():
        if key in _keyname_transform_map.keys():
            card[_keyname_transform_map[key]] = card[key]
            del card[key]

def main():
    from argparse import ArgumentParser

    parser = ArgumentParser(description=__doc__)
    parser.add_argument('anr_repo', help='Path to the OCTN ANR plugin repository.')
    parser.add_argument('cards_path', help="Path to store cards metadata in.")
    args = parser.parse_args()

    try:
        mkdir(args.cards_path)
    except OSError as e:
        if e.errno != 17: #17 is file exists
            raise
    
    now = time()

    r = Repo(args.anr_repo)
    r.remotes.origin.pull()
    octgn_sha = r.head.commit.hexsha

    r = Request(NETRUNNERCARDS_URL)
    try:
        with open(join(args.cards_path, 'cards.json'), 'r') as f:
            data = json_load(f)
            if 'octgn_sha' in data and data['octgn_sha'] == octgn_sha:
                r.add_header("If-Modified-Since", format_date_time(json_load(f)['modified_since']))
    except IOError as e:
        if e.errno != 2:
            raise
    try:
        cards = json_loads(urlopen(r).read())
    except HTTPError as e:
        if e.code != 304:
            raise

    card_sets_path = join(args.anr_repo, 'o8g', 'Sets')
    card_octgn_data = {}
    for path in walk(card_sets_path):
        if len(path[-1]) > 0 and path[-1][0] == 'set.xml' and not path[0].endswith('Markers'):
            set_data = octgnSetToDict(join(card_sets_path, path[0], path[-1][0]))
            for card_id, card in set_data['cards'].items():
                card['set_id'] = set_data['id']
                card['game_id'] = set_data['gameid']
            card_octgn_data.update(set_data['cards'])

    for card in cards:
        renameCardKeys(card)
        print card['name'].encode('utf8')
        octgn_card = None
        try:
            octgn_card = card_octgn_data[card['card_id']]
        except KeyError as e:
            print '', card['set_name']
            continue
        card['set_id'] = octgn_card['set_id']
        card['game_id'] = octgn_card['game_id']
        card['id'] = octgn_card['id']
        card_image_path = join(args.cards_path, split(card['imagesrc'])[-1])
        if not exists(card_image_path):
            try:
                image_src = urlopen(NETRUNNERCARDS_BASE + card['imagesrc']) 
                with open(card_image_path, 'w') as f:
                    f.write(image_src.read())
            except HTTPError as e:
                print 'ERROR: image missing for card #', card['id']
    cards = {'modified_since': now, 'octgn_sha': octgn_sha, 'cards': cards}
    with open(join(args.cards_path, 'cards.json'), 'w') as f:
        json_dump(cards, f)

if __name__ == '__main__':
    main()
