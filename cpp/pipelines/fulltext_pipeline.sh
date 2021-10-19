#!/bin/bash
# c.f. https://askubuntu.com/questions/623179/remove-array-of-entries-from-another-array/623220#623220 (211019) for the array difference in ConvertNewMohrData
set -o errexit -o nounset

source pipeline_functions.sh

readonly FULLTEXT_LOCAL_ROOT="/usr/local/publisher_fulltexts"
readonly FULLTEXT_EXCHANGE_ROOT="/mnt/ZE020150/FID-Entwicklung/fulltext/publisher_files"

TMP_NULL="/tmp/null"
function CreateTemporaryNullDevice {
    if [ ! -c ${TMP_NULL} ]; then
        mknod ${TMP_NULL} c 1 3
        chmod 666 ${TMP_NULL}
    fi
}


function GetNetPublisherFulltexts {
    rsync --archive --verbose --recursive ${FULLTEXT_EXCHANGE_ROOT} ${FULLTEXT_LOCAL_ROOT}
}


function ConvertNewMohrData {
    local readonly MOHR_EXTRACTED="/usr/local/publisher_fulltexts/mohr/"
    local readonly MOHR_ARCHIVE_DIR="${FULLTEXT_LOCAL_ROOT}/publisher_files/mohr"
    mapfile -t < <(find ${MOHR_EXTRACTED} -type f -name '*.txt' -exec sh -c 'printf "%s\n" $(basename "${0%.*}")' {} ';') present_fulltexts
    mapfile -t < <(find ${MOHR_ARCHIVE_DIR} -name '*.zip' -exec sh -c 'printf "%s\n" $(basename "${0%.*}")' {} ';') new_fulltexts
    readonly new_to_import=( $(printf "%s\n" "${present_fulltexts[@]}" "${new_fulltexts[@]}" | sort | uniq --unique) )
    for item in ${new_to_import[@]}; do
        echo "Extracting item ${item} to ${MOHR_EXTRACTED}/${item}"
        unzip -o ${MOHR_ARCHIVE_DIR}/${item}.zip -d ${MOHR_EXTRACTED}/${item}
        echo "Converting item ${item}"
        marcxml_metadata_processor ${MOHR_EXTRACTED}/${item}/catalogue_md.xml \
            ${MOHR_EXTRACTED}/${item}/content/${item}.pdf ${MOHR_EXTRACTED}/${item}.txt
    done;
}


if [ $# != 1 ]; then
    echo "usage: $0 GesamtTiteldaten-YYMMDD.mrc"
    exit 1
fi

if [[ ! "$1" =~ GesamtTiteldaten-[0-9][0-9][0-9][0-9][0-9][0-9].mrc ]]; then
    echo 'Die Gesamttiteldatendatei entspricht nicht dem Muster GesamtTiteldaten-[0-9][0-9][0-9][0-9][0-9][0-9].mrc!'
    exit 1
fi

# Determines the embedded date of the files we're processing:
date=$(DetermineDateFromFilename $1)

# Sets up the log file:
logdir=/usr/local/var/log/tuefind
log="${logdir}/fulltext_pipeline.log"
rm -f "${log}"

CleanUp
CreateTemporaryNullDevice

OVERALL_START=$(date +%s.%N)


StartPhase "Get New Publisher Fulltexts from Network Drive"
(GetNetPublisherFulltexts >> "${log}" 2>&1 && \
EndPhase || Abort) &
wait


StartPhase "Create Match DB"
(create_match_db GesamtTiteldaten-"${date}".mrc
    >> "${log}" 2>&1 && \
EndPhase || Abort) &
wait


StartPhase "Convert Mohr Data"
(ConvertNewMohrData >> "${log}" 2>&1 && \
EndPhase || Abort) &
wait


StartPhase "Import Mohr Data"
(find /usr/local/publisher_fulltexts/mohr/ -maxdepth 1 -name '*.txt' | xargs -n 50 store_in_elasticsearch --set-publisher-provided \
    >> "${log}" 2>&1 && \
EndPhase || Abort) &


StartPhase "Import Brill Data"
(find /usr/local/publisher_fulltexts/brill/ -maxdepth 1 -name '*.txt' | xargs -n 50 store_in_elasticsearch --set-publisher-provided \
    >> "${log}" 2>&1 && \
EndPhase || Abort) &


StartPhase "Import Aschendorff Data"
(find /usr/local/publisher_fulltexts/aschendorff/ -maxdepth 1 -name '*.txt' | xargs -n 50 store_in_elasticsearch --set-publisher-provided \
    >> "${log}" 2>&1 && \
EndPhase || Abort) &


StartPhase "Harvest Title Data Fulltext"
(create_full_text_db --store-pdfs-as-html --use-separate-entries-per-url --include-all-tocs \
    --include-list-of-references --only-pdf-fulltexts GesamtTiteldaten-"${date}".mrc ${TMP_NULL} \
    >> "${log}" 2>&1 && \
        EndPhase || Abort) &
wait


echo -e "\n\nPipeline done after $(CalculateTimeDifference $OVERALL_START $(date +%s.%N)) minutes." | tee --append "${log}"
echo "*** FULL TEXT PIPELINE DONE - $(date) ***" | tee --append "${log}"




