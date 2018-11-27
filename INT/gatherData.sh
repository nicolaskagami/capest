#!/bin/bash
METHOD=$1
NOM_CAPACITY=$2
NUM_VIDEOS=$3

PINGDATA_FILE=".pingdata"
CAPESTD_FILE=".capestd"

LOSS=$(head -n 1 $PINGDATA_FILE | cut -d ',' -f3 | cut -d '%' -f1 | tr -d ' ')
LATENCY=$(tail -n 1 $PINGDATA_FILE | cut -d '=' -f2 | cut -d '/' -f2)
JITTER=$(tail -n 1 $PINGDATA_FILE | cut -d '=' -f2 | cut -d '/' -f4 | cut -d ' ' -f1)

MEASURED_CAPACITY=$(tail -n 1 $CAPESTD_FILE | cut -d ',' -f3 | cut -d ' ' -f3)
MEASURED_UTIL=$(tail -n 1 $CAPESTD_FILE | cut -d ',' -f2 | cut -d ' ' -f3)
MEASURED_ABW=$(bc <<< "$MEASURED_CAPACITY-$MEASURED_UTIL")

START_TIME=0
STALL_LENGTH=0
STALL_COUNT=0
COUNT=0
for CPLAYERDATA_FILE in ./.cplayer*
do
    INSTANCE_START_TIME=$(tail -n 1 $CPLAYERDATA_FILE | cut -d ';' -f3)
    INSTANCE_STALL_LENGTH=$(tail -n 1 $CPLAYERDATA_FILE | cut -d ';' -f4)
    INSTANCE_STALL_COUNT=$(tail -n 1 $CPLAYERDATA_FILE | cut -d ';' -f5)
    let "COUNT = COUNT + 1"
    START_TIME=$(bc <<< "scale=6;$START_TIME + $INSTANCE_START_TIME")
    STALL_LENGTH=$(bc <<< "scale=6;$STALL_LENGTH + $INSTANCE_STALL_LENGTH")
    STALL_COUNT=$(bc <<< "scale=6;$STALL_COUNT + $INSTANCE_STALL_COUNT")
done
START_TIME=$(bc <<< "scale=6;$START_TIME / $COUNT")
STALL_LENGTH=$(bc <<< "scale=6;$STALL_LENGTH / $COUNT")
STALL_COUNT=$(bc <<< "scale=6;$STALL_COUNT / $COUNT")


echo "$METHOD,$NOM_CAPACITY,$NUM_VIDEOS,$MEASURED_CAPACITY,$MEASURED_ABW,$LATENCY,$JITTER,$LOSS,$START_TIME,$STALL_LENGTH,$STALL_COUNT" >> Results.dat
