#!/bin/bash

# create random JSON samples from CSV files

for file in $(ls shorted/*.csv); do
  fileName=${file/shorted\//}
  fileName=${fileName/\.csv/\.json}
  dest=jsons/$fileName

  xsv sample 5 $file | csvjson -i 4 > ${dest}
  # echo $dest
done

# mysqldump --databases X --tables Y --where="1 limit 1000000"
