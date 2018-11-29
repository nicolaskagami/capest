#!/bin/bash

FILE=$1
SEGMENT_SIZE=$2
duration=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $FILE | cut -d'.' -f 1`
duration=`expr $duration + 1`
fbname=$(basename "$FILE" | cut -d. -f1)

echo "BASE Name: " $fbname
echo "Duration: " $duration
start=0
count=1
while [ $start -lt $duration ]
do
  ffmpeg -i $FILE -ss $start -t $SEGMENT_SIZE -vcodec copy -acodec copy $fbname"-seg"$count".mp4"
  start=`expr $start + $SEGMENT_SIZE`
  count=`expr $count + 1`
done
