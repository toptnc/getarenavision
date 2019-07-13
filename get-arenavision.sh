
#!/bin/bash

m3ufile=$HOME/Escritorio/arenavision.m3u
fronturl='http://arenavision.us'
acebinary='/usr/bin/acestreamplayer'


echo > $m3ufile
progress=0

links=$(curl -s --cookie "beget=begetok" $fronturl | grep -o '\<a href.*\>' | sed 's/\<a\ href/\n\<a\ href/g' | grep ArenaVision)
(
    IFS='
'
    for line in $links;
    do
	arenaurl=$(echo "$line" | cut -d '"' -f 2)
	arenatitle=$(echo "$line" | cut -d '>' -f 2 | cut -d '<' -f 1)
	#arenalink=$(curl -s --cookie "beget=begetok" $arenaurl | grep acestream:// | sed 's/\ /\n/g'| grep acestream | cut -d "=" -f 2 | sed 's/\"//g')
	arenalink=$(curl -s --cookie "beget=begetok" $arenaurl | grep jQuery | grep manifest | sed 's/\,/\n/g'| grep id | cut -d "\"" -f 2)
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

guidetemp='/tmp/arenaguide.tmp'
guidefile=$HOME/Escritorio/arenavision-guia.txt
guidepath=$(curl -s --cookie "beget=begetok" $fronturl | grep -o '\<a href.*\>' | sed 's/\<a\ href/\n\<a\ href/g' | grep EVENTS | cut -d '"' -f 2)
echo $guidepath | grep -q http && guideurl=$guidepath || guideurl="$fronturl/$guidepath"

curl -s --cookie "beget=begetok"  $guideurl | html2text -width 100 > $guidetemp
LNSTART=$(grep -n "EVENTS GUIDE" $guidetemp | cut -d ":" -f 1)
LNEND=$(grep -n "Last update" $guidetemp | cut -d ":" -f 1)
awk -v start="$LNSTART" -v end="$LNEND" 'NR >= start && NR <= end' $guidetemp > $guidefile
yad --title="Programación de Eventos" --width=900 --height=800 --text-info --filename=$guidefile &

$acebinary $m3ufile
