#!/usr/bin/env python

"""
Finds similar filenames between two directories and outputs closest matches.
"""

from os import listdir
from sys import stderr
from Levenshtein import ratio

def findCommonSuffix(strings):
    offset = -1
    length = abs(offset)
    while True:
        match = strings[0][offset]
        for s in strings[1:]:
            if len(s) == length or s[offset] != match:
                return s[offset+1:]
        offset -= 1
        length += 1

def findBestMatch(needle, haystack):
    return max(haystack, key=lambda x: ratio(needle, x))

def main():
    from argparse import ArgumentParser

    parser = ArgumentParser(description=__doc__)
    parser.add_argument('source')
    parser.add_argument('destination')
    #parser.add_argument('-d', '--dry-run', default=False, action="store_true", help="Only print what would be replaced.")
    args = parser.parse_args()

    source_files = listdir(args.source)
    if len(source_files) == 0:
        print >> stderr, "Empty source directory.   Aborting."
        return 1
    destination_files = listdir(args.destination)
    if len(destination_files) == 0:
        print >> stderr, "Empty destination directory.  Aborting."
        return 1

    common_suffix = findCommonSuffix(destination_files)
    print >> stderr, "found common suffix: ", common_suffix
    common_suffix_len = len(common_suffix)

    for f in destination_files:
        match = findBestMatch(f[:-common_suffix_len], source_files)
        print >> stderr, ratio(f[:-common_suffix_len], match)
        print match, f

if __name__ == '__main__':
    main()
