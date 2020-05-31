#!/bin/bash

echo "`date`===== START from $$ for ====" >> worker.log
echo "$1" >> worker.log
res=$(eval "$1")
echo "$res" >> worker.log
#echo "`date` ===== STOP from $$ for ====" >> worker.log
