#!/bin/bash

# Parses Mysql/Oracle/Mariadb sql files  (Data and Schema-Dumps)
DICTIONARY_FILE=translationTable.json
# SQL_FILE=SQL_FULL_EXPORT.sql
# SQL_FILE=SQL_STAGING_SCHEMA.sql
# SQL_FILE=SQL_SMALL_EXPORT.sql
SQL_FILE=SQL_SCHEMA_EXPORT_CB.sql
SQLOUTFILE=.trash/translated.sql
JSONOUTFILE=.trash/propMap.json


let TABLE
let NEWLINE
declare -A TRANSLATIONS=()
declare -A TABLES=()
JSONSTRING="{\n"

echo "-- start: $(date)" > $SQLOUTFILE
echo -n "" > $JSONOUTFILE


## READ THE DICTIONARY
while IFS= read -r line
do
  row=${line//\"} # removed all '"'
  row=${row//,}   # removed all ','
  row=${row//\ }  # removed all whitespace
  key=${row%:*}
  value=${row#*:} # echo "$key => $value"
  [ ! -z "${key}" ] && TRANSLATIONS[$key]=$value # echo "${TRANSLATIONS[zaehler]}"
done < $DICTIONARY_FILE

## READ THE SQL SCHEMA
while IFS= read -r line
do
  chrlen=${#line}
  HEAD=${line:0:100}

  if [[ $HEAD =~ \` && ! $HEAD =~ \-\- ]]; then # Just Check the First 100 Chars of each ROW
    FIELD_ORIG=${HEAD#*\`}          # using # strips from the start of $var up to pattern
    FIELD_ORIG=${FIELD_ORIG%\`*}    # using % strips from end of $var, up to pattern
    FIELD_ORIG=${FIELD_ORIG//*\`/}
    [ -z "${FIELD_ORIG}" ] && exit 1
    FIELD_CAMEL=${FIELD_ORIG,,}       # all toLowerCase
    FIELD_CAMEL=(${FIELD_CAMEL//_/ }) # remove dashes
    printf -v FIELD_CAMEL %s "${FIELD_CAMEL[@]^}" # convert starts-UP
    FIELD_CAMEL=${FIELD_CAMEL,}       # fist char toLower
    FIELD_NEW=${TRANSLATIONS[$FIELD_CAMEL]} # find translation
    # echo -e "$FIELD_ORIG \t\t ${FIELD_CAMEL} \t\t ${FIELD_NEW}"
    [ -z "${FIELD_NEW}" ] && FIELD_NEW=${FIELD_CAMEL}  # fallBack to ORIG or CAML?

    if [[ $HEAD =~ CREATE\ TABLE && $HEAD =~ \`${FIELD_ORIG}\` ]]; then
      echo "## $FIELD_NEW ##"
      if [ ! -z "${TABLE}" ]; then
        JSONSTRING+="},\n"
      fi
      JSONSTRING+="'$FIELD_NEW': {\n"
      TABLES[$FIELD_ORIG]=$FIELD_NEW
      TABLE=$FIELD_ORIG
    fi

    if [[ ! $HEAD =~ CREATE\ TABLE && ! $HEAD =~ DROP\ TABLE && ! $HEAD =~ INSERT\ INTO && ! $HEAD =~ LOCK\ TABLES && ! $HEAD =~ ALTER\ TABLE ]]; then
      NEWLINE=${HEAD/$FIELD_ORIG/$FIELD_NEW}  # match and replace just 100 chars!
      FOOT=${line:100:$chrlen}                # append remaining chars untouched
      echo "${NEWLINE}${FOOT}" >> $SQLOUTFILE # dumpit

      if [[ ! $HEAD =~ \ \`$FIELD_NEW\`\ && ! $HEAD =~ PRIMARY\ KEY ]]; then
        echo -e "\t$FIELD_NEW, "
        JSONSTRING+="\t'$FIELD_NEW': '$FIELD_ORIG',\n"
      fi
    else
      echo ${line} >> $SQLOUTFILE
    fi
  else
    echo ${line} >> $SQLOUTFILE
  fi
done < $SQL_FILE


echo -e "\n\n"

# echo "### tablelle: ${#TABLES[@]} "
JSONSTRING+="},\n'__tables': { "
for KEY in "${!TABLES[@]}"; do
  JSONSTRING+="'${TABLES[$KEY]}': '$KEY',"
done

JSONSTRING+="}"
JSONSTRING+='\n}'
echo -e $JSONSTRING | sed "s/'/\"/g" | sed 's/,}/}/g' | sed ':begin;$!N;s/\",\n},/\"\n},/;tbegin;P;D' > ${JSONOUTFILE}

echo "mysql -ubox -p ste < ${SQLOUTFILE}"
echo "mysqladmin -ubox -p drop ste"
echo "mysqladmin -ubox -p create ste"


# firstString="I love Suzi and Marry";
# secondString="Sara"
# echo "${firstString/Suzi/$secondString}"     # I love Sara and Marry

# orig='from=someuser@somedomain.com, <some text>'
# one=${orig#*from=}
# two=${one%,*}
# echo
# echo "$orig" # from=someuser@somedomain.com, <some text>
# echo "$one"  # someuser@somedomain.com, <some text>
# echo "$two"  # someuser@somedomain.com
# ${var#*pattern} using # strips from the start of $var up to pattern
# ${var%pattern*} using % strips from end of $var, up to pattern

# echo "US/Central - 10:26 PM (CST)" | sed -n "s/^.*-\s*\(\S*\).*$/\1/p"
# -n      suppress printing
# s       substitute
# ^.*     anything at the beginning
# -       up until the dash
# \s*     any space characters (any whitespace character)
# \(      start capture group
# \S*     any non-space characters
# \)      end capture group
# .*$     anything at the end
# \1      substitute 1st capture group for everything on line
# p       print it


# sed ':begin;$!N;s/\n//;tbegin'                   # deletes all newlines except the last; see also tr -d '\n'
# sed ':begin;$!N;s/\n/ /;tbegin'                  # same as before, but replaces newlines with spaces; see also tr '\n' ' '
# sed ':begin;$!N;s/\(PATTERN\)\n/\1/;tbegin;P;D'  # if the line ends in PATTERN, join it with the next line
# sed ':begin;$!N;/PATTERN\n/s/\n//;tbegin;P;D'    # same as above
# sed ':begin;$!N;s/FOO\nBAR/FOOBAR/;tbegin;P;D'   # if a line ends in FOO and the next starts with BAR, join them


# line="abcdefgh"
# chrlen=${#line}
# HEAD=${line:0:3}
# FOOT=${line:3:$chrlen}
# echo "$HEAD${FOOT}"
# exit 0

