#! /bin/bash
# csvsql --dialect mysql --snifflimit 1000  --quoting 0 -z 9261072 test.csv > test.sql
# Row 165 has 11 values, but Table only has 3 columns.
# cat worldcitiespop.csv | sed -n '1,166p' > tables/abgabeart.csv
# xsv headers test.csv
# xsv stats test.csv --everything | xsv table
# xsv frequency test.csv --limit 5

#rm tables/*.csv; time ./import.sh

# xsv search -s Population '[0-9]' worldcitiespop.csv \
#   | xsv select Country,AccentCity,Population \
#   | xsv sample 10 \
#   | xsv table

echo -n "" > cmds.list
echo -n "" > errors.log
echo -n "" > worker.log

#FILE=gpp.csv
FILE=worldcitiespop.csv
HEADERLINES=$(cat ${FILE} | egrep -ne '(^"[A-Z].*",|^"BIC"|^"SSO_TEILNEHMER_NUMMER")' |  grep -v "00:00:00"| sed 's/:.*//g' )
COUNTER=1
COUNTER2=2
let array
let errors
mkdir -p tables

for LINE in $HEADERLINES; do
  array[$COUNTER]=$LINE
  COUNTER=$(($COUNTER+1))
done;

echo "Will create: ${#array[@]}"

COUNTER=1
for FROM in "${array[@]}"; do
  TO=${array[COUNTER2]}
  TO=$(($TO-1))

  if [[ "$TO" == "-1"  ]]; then
    TO=`wc -l ${FILE} | awk -F ' ' '{print $1}'`;
  fi;
  OUT="tables/table_${FROM}-${TO}.csv"
  #echo "fromTO: $FROM $TO"
  if test -f "$OUT1"; then
    echo -n "." # skip this
  else
    echo "cutting: ${OUT} ${FROM} ${TO}"
CMD=$(cat <<EOF
"sed -n ${FROM}','${TO}'p' ${FILE} > ${OUT}_tmp ; xsv fixlengths ${OUT}_tmp > ${OUT} ; xsv index ${OUT}"
EOF
)
  echo $CMD >> cmds.list
  fi

  COUNTER=$(($COUNTER+1))
  COUNTER2=$(($COUNTER2+1))
done

#echo "\"rm tables/*.csv_tmp\"" >> cmds.list

# Analyze fix
for _file in $(ls tables/*.csv | grep table_ ); do #| sed 's/.* table_//g'
  file="${_file}"
  bak="${_file}.bak"
  echo $file
  res=$(xsv count $file)
  if [ $? -eq 0 ]; then
    echo -n ""
  else
    echo -en "Terror!! ${file} $ret"
    errors+=($file)
    mv $file ${bak}
    xsv fixlengths $bak > $file
  fi
done

echo "cat cmds.list | xargs -I{} -n 1 -P 6 ./exec_eval.sh {}"
# echo ${errors[@]}

