#!/bin/bash

if [ -f $HOME/.config/user-dirs.dirs ];
then
    source $HOME/.config/user-dirs.dirs
fi

m3ufile=$HOME/Escritorio/arenavision.m3u

guidetemp='/tmp/arenaguide.tmp'
guidetxt='/tmp/arenaguide.txt'
guidefile=$HOME/Escritorio/arenavision-guia.txt

curl -s --cookie "beget=begetok" -o $guidetemp http://arenavision.in/guide 
cat $guidetemp | html2text -width 100  > $guidetxt

LNSTART=$(grep -n "active-trail active" $guidetemp | cut -d ":" -f 1)
LNEND=$(grep -n "DOWNLOAD ACESTREAM PLUGIN" $guidetemp | cut -d ":" -f 1)

CHLIST=$(awk -v start="$LNSTART" -v end="$LNEND" 'NR > start && NR < end' $guidetemp | grep leaf | sed 's/href/\nhref/g' | grep href | grep -v menu | grep -v active-trail | cut -d "\"" -f 2)

echo > $m3ufile
progress=0
channel=1
(
for i in $CHLIST;
do
   arenalink=$(curl -s --cookie "beget=begetok"  http://arenavision.in/$i | grep acestream:// | sed 's/\ /\n/g'| grep acestream | cut -d "=" -f 2 | sed 's/\"//g')
   echo \#EXTINF:-1,Arenavision $channel >> $m3ufile
   echo $arenalink >> $m3ufile
   progress=$(($progress + 3))
   channel=$(($channel + 1))
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


LNSTART=$(grep -n "EVENTS GUIDE" $guidetxt | cut -d ":" -f 1)
LNEND=$(grep -n "Last update" $guidetxt | cut -d ":" -f 1)
awk -v start="$LNSTART" -v end="$LNEND" 'NR >= start && NR <= end' $guidetxt > $guidefile
yad --width=900 --height=800 --text-info --filename=$guidefile &

acestreamplayer $m3ufile
