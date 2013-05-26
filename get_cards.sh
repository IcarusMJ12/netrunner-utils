#!/usr/bin/env bash

if [ "x$1" == "x" ]
then
	echo "Usage: $0 <card_image_directory>"
	exit 1
fi
mkdir -p $1
for card_set in `curl -g -s netrunnercards.info | grep -o 'http://.*/set/[a-z]*'`
do
	echo "Fetching cards from $card_set..."
	for card in `curl -g -s $card_set | grep -o 'http://.*/card/[0-9]*'`
	do
		card_info=`curl -g -s $card`
		name=`echo $card_info | grep -o '<title>.*</title>' | sed 's/<\/*title>//g' | iconv -f utf-8 -t ascii//translit | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]*//g' | tr ' ' '-'`
		image_path=`echo $card_info | grep -oP '/assets/images/cards/.*?\.png'`
		if [ "x$image_path" != "x" -a "x$name" != "x" ]
		then
			if [ -e "$name.png" ]
			then
				continue
			else
				echo "	Fetching $name from $image_path..."
				curl -g -s "http://netrunnercards.info$image_path" > "$1/$name.png"
			fi
		else
			echo "Either name $name or image_path $image_path is invalid."
		fi
	done
done
exit 0
