#!/bin/bash

m3ufile=$HOME/Escritorio/arenavision.m3u
fronturl='https://arenavision.live'
acebinary='/usr/bin/acestreamplayer'

echo > $m3ufile
progress=0

links=$(links -source $fronturl | gzip -cd | grep -o '\<a href.*\>' | sed 's/\<a\ href/\n\<a\ href/g' | grep ArenaVision)
(
    IFS='
'
    for line in $links;
    do
	arenaurl=$(echo "$line" | cut -d '"' -f 2)
	arenatitle=$(echo "$line" | cut -d '>' -f 2 | cut -d '<' -f 1)
	arenalink=$(links -source ${fronturl}${arenaurl} | gzip -cd | grep jQuery | grep manifest | sed 's/\,/\n/g'| grep id | cut -d "\"" -f 2)
	echo \#EXTINF:-1,"$arenatitle" >> $m3ufile
	echo "acestream://$arenalink" >> $m3ufile
	progress=$(($progress + 3))
	echo $progress
done
echo 100
) | yad --center \
  --progress \
  --title="Descargando" \
  --text="Descargando canales de Arenavision" \
  --percentage=0 \
  --auto-close \
  --auto-kill


today=$(LANG=C date "+%A")
guidetemp='/tmp/arenaguide.tmp'
guidefile=$HOME/Escritorio/arenavision-guia.txt
guidepath=$(links -source $fronturl | gzip -cd | grep -o '\<a href.*\>' | sed 's/\<a\ href/\n\<a\ href/g' | grep $today | cut -d '"' -f 2)
echo $guidepath | grep -q http && guideurl=$guidepath || guideurl="$fronturl$guidepath"

links -http.referer 1 -dump -width 120 $guideurl > $guidetemp
LNSTART=$(grep -n "Events Guide List" $guidetemp | cut -d ":" -f 1)
LNEND=$(grep -n "Terms of Use" $guidetemp | cut -d ":" -f 1)
awk -v start="$LNSTART" -v end="$LNEND" 'NR >= start && NR <= end' $guidetemp > $guidefile
yad --width=1100 --height=800 --text-info --filename=$guidefile &

$acebinary $m3ufile
