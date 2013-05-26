#!/usr/bin/env python
"""Dumps OCTGN card sets into a csv."""

import csv, codecs, cStringIO

from card_set import octgnSetToDict

# filched from http://docs.python.org/2/library/csv.html
# made new-style, just because
class UnicodeWriter(object):
    """
    A CSV writer which will write rows to CSV file "f",
    which is encoded in the given encoding.
    """

    def __init__(self, f, dialect=csv.excel, encoding="utf-8", **kwds):
        # Redirect output to a queue
        self.queue = cStringIO.StringIO()
        self.writer = csv.writer(self.queue, dialect=dialect, **kwds)
        self.stream = f
        self.encoder = codecs.getincrementalencoder(encoding)()

    def writerow(self, row):
        self.writer.writerow([s.encode("utf-8") for s in row])
        # Fetch UTF-8 output from the queue ...
        data = self.queue.getvalue()
        data = data.decode("utf-8")
        # ... and reencode it into the target encoding
        data = self.encoder.encode(data)
        # write to the target stream
        self.stream.write(data)
        # empty queue
        self.queue.truncate(0)

    def writerows(self, rows):
        for row in rows:
            self.writerow(row)

def main():
    import argparse
    from os import walk
    from os.path import join
    
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('out_csv', help='Result will be stored here.')
    parser.add_argument('card_sets', help='Path to OCTN card sets.')
    args = parser.parse_args()

    result = {}
    for path in walk(args.card_sets):
        if len(path[-1]) > 0 and path[-1][0] == 'set.xml' and not path[0].endswith('Markers'):
            print "Parsing", path
            result.update(octgnSetToDict(join(args.card_sets, path[0], path[-1][0]))['cards'])
    fields = set()
    for card in result.values():
        fields |= set(card.keys())
    fields = list(fields)
    # we don't care about autoscripts, etc.
    fields = [f for f in fields if not f.startswith('Auto')]
    fields.sort()
    card_names = result.keys()
    card_names.sort()

    with open(args.out_csv, 'w') as f:
        csv_writer = UnicodeWriter(f)
        csv_writer.writerow(['Name'] + fields)
        csv_writer.writerows([[card_name] + [result[card_name][f] for f in fields] for card_name in card_names])

if __name__ == '__main__':
    main()
