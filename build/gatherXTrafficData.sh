#!/bin/bash
METHOD=$1
NOM_CAPACITY=$2
XTRAFFIC_TYPE=$3
XTRAFFIC_CAP=$4

PINGDATA_FILE=".pingdata"
CAPESTD_FILE=".capestd"

LOSS=$(head -n 1 $PINGDATA_FILE | cut -d ',' -f3 | cut -d '%' -f1 | tr -d ' ')
LATENCY=$(tail -n 1 $PINGDATA_FILE | cut -d '=' -f2 | cut -d '/' -f2)
JITTER=$(tail -n 1 $PINGDATA_FILE | cut -d '=' -f2 | cut -d '/' -f4 | cut -d ' ' -f1)

MEASURED_CAPACITY=$(tail -n 1 $CAPESTD_FILE | cut -d ',' -f3 | cut -d ' ' -f3)

CONVERGENCE_LOCALITY=10
ROUNDS_PER_MBPS=""
i=0
while read line
do
    C=$(echo $line | cut -d ',' -f3 | cut -d ' ' -f3)
    re='^[0-9]+$'
    if [[ $C =~ $re ]] ; then
        ROUNDS[$i]=$C
        let 'i = i+ 1'
    fi
done < .capestd
NUMBER_OF_ROUNDS=$i
i=0
while [ $(bc <<<"$i+$CONVERGENCE_LOCALITY+1 < $NUMBER_OF_ROUNDS") -eq 1 ]
do
    CONVERGED=1
    j=0
    SUM=0
    while [ $j -lt $CONVERGENCE_LOCALITY ]
    do
        SUM=$( bc <<< "$SUM + ${ROUNDS[$i+$j+1]}")
        let 'j = j+ 1'
    done
    AVERAGE=$( bc <<< "$SUM / $CONVERGENCE_LOCALITY")

    j=0
    while [ $j -lt $CONVERGENCE_LOCALITY ]
    do
        if [ $( bc <<< "($AVERAGE*0.9 > ${ROUNDS[$i+$j+1]})||($AVERAGE*1.1 < ${ROUNDS[$i+$j+1]})") -eq 1 ]
        then
            CONVERGED=0
        fi
        let 'j = j+ 1'
    done
    if [ $CONVERGED -eq 1 ]
    then
        break
    fi

    let 'i = i+ 1'
done
#+1 (pelo menos 1 round para convergir)
let 'i = i+ 1'
CONVERGENCE_ROUND=$i

rounds=$(printf ",%s" "${ROUNDS[@]}")
echo "$METHOD,$NOM_CAPACITY,$XTRAFFIC_TYPE,$XTRAFFIC_CAP,$MEASURED_CAPACITY,$CONVERGENCE_ROUND,$LATENCY,$JITTER,$LOSS$rounds" >> Factor_Results.dat
