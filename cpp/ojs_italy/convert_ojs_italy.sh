#!/bin/bash

function RemoveTempFiles {
   for tmpfile in ${tmpfiles[@]}; do
       rm ${tmpfile}
   done
}

trap RemoveTempFiles EXIT

tmpfiles=()
tmp_stdout="/tmp/stdout.xml"
ln --symbolic /dev/stdout ${tmp_stdout}
tmpfiles+=(${tmp_stdout})


STUDIA_PATAVINA_ORIG_IN="daten/Studia_Patavina_1959-62.xml"
RIVISTA_DI_SCIENCE_ORIG_IN='daten/sample_all.mrc'
date=$(date '+%y%m%d')
STUDIA_PATAVINA_OUT="daten/Studia_Patavina_59-62_ubtue_${date}.xml"
RIVISTA_DI_SCIENCE_OUT="daten/sample_all_converted_${date}.xml"
SAMPLE_LIMIT="5"
TEST_DB_SAMPLE_DIR="daten/test_db_sample"
SAMPLE_BASE_NAME="ixtheo_ojsitaly_sample"
STUDIA_PATAVINA_ASSOCIATED_AUTHORS="daten/studia_patavina_associated_authors.txt"
RIVISTA_DI_SCIENCE_ASSOCIATED_AUTHORS="daten/rivista_di_science_associated_authors.txt"


./convert_ojs_italy ${STUDIA_PATAVINA_ORIG_IN} studia_patavina_map.txt \
                    ${STUDIA_PATAVINA_OUT}
./convert_ojs_italy ${RIVISTA_DI_SCIENCE_ORIG_IN} rivista_di_science_map.txt \
                    ${RIVISTA_DI_SCIENCE_OUT}

#Some Cleanup
marc_filter ${RIVISTA_DI_SCIENCE_OUT} ${tmp_stdout} --globally-substitute '100d' '[.]$' '' | sponge  ${RIVISTA_DI_SCIENCE_OUT}


#Associate authors

if [ ! -f ${STUDIA_PATAVINA_ASSOCIATED_AUTHORS} ]; then
    marc_grep ${STUDIA_PATAVINA_OUT} '"100a"' no_label | \
        xargs -n 1 -I'{}' sh -c 'echo "$@" "'"|"'" $(./swb_author_lookup --sloppy-filter "$@")' _ '{}' \
        | sort | uniq > ${STUDIA_PATAVINA_ASSOCIATED_AUTHORS}
fi

if [ ! -f ${RIVISTA_DI_SCIENCE_ASSOCIATED_AUTHORS} ]; then
    marc_grep ${RIVISTA_DI_SCIENCE_OUT} '"100a"' no_label | \
        xargs -n 1 -I'{}' sh -c 'echo "$@" "'"|"'" $(./swb_author_lookup --sloppy-filter "$@")' _ '{}' \
        | sort | uniq > ${RIVISTA_DI_SCIENCE_ASSOCIATED_AUTHORS}
fi

./add_author_associations ${STUDIA_PATAVINA_OUT} /tmp/stdout.xml \
    <(cat ${STUDIA_PATAVINA_ASSOCIATED_AUTHORS}  | grep -P -v '[|]\s*$') \
    | sponge ${STUDIA_PATAVINA_OUT}
./add_author_associations  ${RIVISTA_DI_SCIENCE_OUT} /tmp/stdout.xml \
     <(cat ${RIVISTA_DI_SCIENCE_ASSOCIATED_AUTHORS} | grep -P -v '[|]\s*$') \
     | sponge ${RIVISTA_DI_SCIENCE_OUT}

marc_grep ${STUDIA_PATAVINA_OUT} 'if "001"==".*" extract *' traditional \
          > ${STUDIA_PATAVINA_OUT%.xml}.txt

marc_grep ${RIVISTA_DI_SCIENCE_OUT} 'if "001"==".*" extract *' traditional \
          > ${RIVISTA_DI_SCIENCE_OUT%.xml}.txt

#Generate Samples
marc_convert --limit ${SAMPLE_LIMIT} ${STUDIA_PATAVINA_OUT} ${TEST_DB_SAMPLE_DIR}/${SAMPLE_BASE_NAME}_${date}_001.xml
marc_convert --limit ${SAMPLE_LIMIT} ${RIVISTA_DI_SCIENCE_OUT} ${TEST_DB_SAMPLE_DIR}/${SAMPLE_BASE_NAME}_${date}_002.xml


