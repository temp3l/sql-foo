#!/bin/bash

mkdir -p schemas
echo -n "" > cmds.list
echo -n "" > pumps.list
headz=$(cat database/tableNames.txt)

for _file in $(ls tables/*.csv | sed 's/^tables\///'); do
  OUT="schemas/${_file}.sql"
  IN="tables/${_file}"

  if test -f "$OUT"; then
    echo -n ""    #echo "skipped: $IN"
  else
    res=$(eval "head -n 1 $IN | sed 's/,*$//g' | sed 's/\"//g'")
    table=$(eval "grep \"###${res}\" database/tableNames.txt")
    tableName=$(eval "echo \"$table\" | head -n1 | sed 's/##.*//g' ") # subtr before###

    echo $IN
    if [ "$tableName" == "" ]; then
      echo "no table for file: $IN   $res   ${tableName}"
      now=$(date +%s)
      tableName="none_${now}"
    fi
    # CMD="\"xsv sample 100000 ${IN} | csvsql --dialect mysql --snifflimit 100000 -z 9261072 --tables $tableName > schemas/${tableName}.sql"\"
    # csvsql --overwrite --snifflimit 1000 -z 9261072 --tables BANK --db mysql+mysqlconnector://box:xxx@localhost:3306/cb --insert tables/table_1-166.csv

CMD=$(cat <<EOF
"xsv sample 100000 ${IN} | csvsql --dialect mysql --snifflimit 100000 -z 9261072 --tables $tableName > schemas/${tableName}.sql"
EOF
)

TRANS=$(cat <<EOF
"cp ${IN} trans/${tableName}.csv"
EOF
)
PUMP=$(cat <<EOF
"echo ${tableName} ; csvsql --overwrite --tables ${tableName} --db mysql+mysqlconnector://box:xxx@localhost:3306/cb --insert ${IN}"
EOF
)
    echo $TRANS >> trans.list
    echo $CMD >> cmds.list
    echo $PUMP >> pumps.list
    #echo $tableName
    #echo $cmd >> cmds.list
    ret=$?
    if [ $ret -eq 0 ]; then
      echo -n ""
    else
      echo  "\tTerror!! $ret $res"
      #rm $OUT
      exit
    fi
  fi
done;
#find schemas -empty -iname "*.sql" -exec rm {} \;
#find schemas -empty -iname "*.sql"
# for file in $(ls schemas/*.sql); do
#   sed -i 's/`ID` DECIMAL(38, 0) NOT NULL,/`ID` BIGINT NOT NULL AUTO_INCREMENT,/g' schemas/$file;
#   sed -i 's///g' schemas/file;
# done


echo "cat cmds.list | xargs -I{} -n 1 -P 6 ./exec_eval.sh {}"
echo "cat pumps.list | xargs -I{} -n 1 -P 6 ./exec_eval.sh {}"

