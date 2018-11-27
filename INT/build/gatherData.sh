#!/bin/bash
METHOD=$1
NOM_CAPACITY=$2
NUM_VIDEOS=$3

PINGDATA_FILE=".pingdata"
CPLAYERDATA_FILE=".cplayer0"
CAPESTD_FILE=".capestd"

LOSS=$(head -n 1 $PINGDATA_FILE | cut -d ',' -f3 | cut -d '%' -f1 | tr -d ' ')
LATENCY=$(tail -n 1 $PINGDATA_FILE | cut -d '=' -f2 | cut -d '/' -f2)
JITTER=$(tail -n 1 $PINGDATA_FILE | cut -d '=' -f2 | cut -d '/' -f4 | cut -d ' ' -f1)

MEASURED_CAPACITY=$(tail -n 1 $CAPESTD_FILE | cut -d ',' -f3 | cut -d ' ' -f3)
MEASURED_ABW=$(tail -n 1 $CAPESTD_FILE | cut -d ',' -f2 | cut -d ' ' -f3)


START_TIME=$(tail -n 1 $CPLAYERDATA_FILE | cut -d ';' -f3)
STALL_LENGTH=$(tail -n 1 $CPLAYERDATA_FILE | cut -d ';' -f4)
STALL_COUNT=$(tail -n 1 $CPLAYERDATA_FILE | cut -d ';' -f5)

echo "$METHOD,$NOM_CAPACITY,$NUM_VIDEOS,$MEASURED_CAPACITY,$MEASURED_ABW,$LATENCY,$JITTER,$LOSS,$START_TIME,$STALL_LENGTH,$STALL_COUNT" >> Results.dat
