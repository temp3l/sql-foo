#!/bin/bash

# 1. index files
# 2. downgrade to mysql
# 3. fix lengths
# 4. regen headers
# 5. upload to mysql-server

# for file in $(ls schemas/*.sql); do
#   sed -i 's/`ID` DECIMAL(38, 0) NOT NULL,/`ID` BIGINT NOT NULL AUTO_INCREMENT,/g' $file; # fix IDs
#   sed -i 's/`DATUM_\(.*\).*VARCHAR.*/`DATUM_\1 DATETIME NOT NULL,/g' $file; # fix dates
# done
# echo "No-id:" # find schemas/  -type f -name "*.sql" -exec grep -HL 'ID' '{}' ';'

regen="false"

echo -n "" > pump_CB.list
echo -n "" > lazy_load.list

if [ "$regen" == "true" ]; then
  for file in $(ls trans/*.csv); do
    heads=$(head -n1 $file | grep -o ",[a-Z]" | wc -l)
    heads=$(($heads+1))
    fileName=${file/trans\//}
    fileName=${fileName/.csv/}

    echo "indexing file: $file  => shouldLengts: $heads"
    xsv index "$file"
    if [ $? -ne 0 ]; then
      echo "###### ERROR ! $file"
      xsv fixlengths -l $heads $file > foo.csv
      rm $file
      mv foo.csv $file
    fi
    #xsv fixlengths -l $heads $file > foo.csv
    xsv slice -l 200000 $file > shorted/${fileName}.csv
  done
  cp trans/INSTANT_PAYMENT_BIC.csv shorted/
  cp trans/GPP_REGIO.csv shorted/

  echo -e "\n\n#\t regenerating indexes"
  for i in $(ls shorted/*.csv); do
    echo $i
    xsv index $i;
  done
  exit 0
fi

for file in $(ls shorted/*.csv); do
  heads=$(head -n1 $file | grep -o ",[a-Z]" | wc -l)
  fileName=${file/shorted\//}
  fileName=${fileName/.csv/}
  echo "\"csvsql -I --snifflimit 0 -z 9261072 --no-create --db mysql+mysqlconnector://user:pass@host:3306/CB --insert $file\"" >> pump_CB.list
  echo "LOAD DATA LOCAL INFILE '/var/lib/mysql-files/${file}' INTO TABLE CB.${fileName} FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES;" >> lazy_load.list

  if [ "$?" -ne "0" ]; then
    echo $file $fileName
  fi
done

echo "time cat pump_CB.list | xargs -I{} -n 1 -P 4 ./exec_eval.sh {}"

# SET GLOBAL local_infile=1;
# mysql -ubox -p --local-infile=1
# mysql -ubox -p --local-infile=1 < lazy_load.list

echo "mysql -ubox -p --local-infile=1 < database/my2.sql"
echo "mysql -ubox -p --local-infile=1 < lazy_load.list"

# LOAD DATA LOCAL INFILE '/var/lib/mysql-files/AUSZUG.csv' INTO TABLE ${table} IGNORE 1 LINES;
# FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

