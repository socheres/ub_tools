#!/bin/bash
set -o nounset

function IsResultSuspicouslyShort() {
    declare -r -i MIN_LINE_COUNT=10
    item_count=$(grep '^[^#]' "$1" | wc --lines)
    [ $item_count -le $MIN_LINE_COUNT ]
}

cd /usr/local/ub_tools/bsz_daten

error_message=""

wget https://labs.ddb.de/app/beagen/item/person/archive/latest -O archivportal-d.beacon.temp
if [ $? == 0 ]; then
    if IsResultSuspicouslyShort archivportal-d.beacon.temp; then
        error_message .= $'Obtained an empty or suspicously short file from Archivportal-d.\n'
    else
        mv archivportal-d.beacon.temp archivportal-d.beacon
    fi
else
    error_message .= $'Failed to download the Beacon file from Archivportal-D.\n'
fi

wget http://kalliope.staatsbibliothek-berlin.de/beacon/beacon.txt -O kalliope.staatsbibliothek-berlin.beacon.temp
if [ $? == 0 ]; then
    if IsResultSuspicouslyShort kalliope.staatsbibliothek-berlin.beacon.temp; then
        error_message .= $'"Obtained an empty or suspicously short file from Kalliope.\n'
    else
        mv kalliope.staatsbibliothek-berlin.beacon.temp kalliope.staatsbibliothek-berlin.beacon
        sed -i -e 's/#FORMAT: GND-BEACON/#FORMAT: BEACON/g' kalliope.staatsbibliothek-berlin.beacon
    fi
else
    error_message .= $'Failed to download the Beacon file from Kalliope.\n'
fi

if [[ ! -z "$error_message" ]]; then
    send_email --recipients="ixtheo-team@ub.uni-tuebingen.de" --subject="Beacon Download Error $(hostname)" \
               --message-body="$error_message"
fi
