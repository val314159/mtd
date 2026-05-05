#!/bin/sh
set -eu
DBURL=${DBURL:-postgresql+psycopg2://$PGUSER@$PGHOST/$PGDATABASE}
TABLES=`echo $* | tr ' ' ','`
if [ "$*" = "" ]; then
    echo Error: No tables specified
    exit 1
elif [ -e .v ]; then
    echo ".v exists!"
else
    virtualenv .v
    .v/bin/pip install sqlacodegen psycopg2-binary inflect
fi
echo generating tables $*
.v/bin/sqlacodegen --option use_inflect --tables $TABLES $DBURL
