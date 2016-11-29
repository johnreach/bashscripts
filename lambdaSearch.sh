#!/bin/bash

git log --after="2014-3-18" --reverse -p --date=short --pretty=format:"awkDelimHere:%n%cd" --pickaxe-regex -S".*\(([^\()]*)\)\s*\->" -- *.java | awk -F"awkDelimHere:" '
BEGIN {
  date=0;
  type=0;
}
 # Check for new date
/awkDelimHere:/ {
  getline;
  date=$0;
  next
}

# Skip non added or deleted matches (duplicates)
/^[^\+\-]/ { next }

# Grab type (+ or -)
/[^\+\-]/ { type=substr($1,1,1) }

# Skip commented matches
/.*\/\/.*.*\(([^\()]*)\)\s*\->/ { next }
/[ \t]*\*/ { next }

# Output match
/.*\(([^\()]*)\)\s*\->/ {

  gsub(/^[+-][ \t]*/, "", $1);
  gsub(/[\n\t]/, " ", $1);

  c++;

  #print c,"\t", date, "\t", $1

  if(type == "+")
    type=1
  else
    type=-1

  printf("%-10s %-15s %-5s %-7s %s\n", c, date, type, total, $1);
}' > lambda.log
