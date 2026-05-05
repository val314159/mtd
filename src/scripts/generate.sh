#!/bin/sh
set -eu
DBURL=${DBURL:-postgresql+psycopg2://$PGUSER@$PGHOST/$PGDATABASE}
TABLES=`echo $* | tr ' ' ','`
if [ "$*" = "" ]; then
    echo Error: No tables specified
    exit 1
fi
apk add py3-virtualenv
echo QQQ
virtualenv .v
echo QQQ1
ll
echo QQ3
.v/bin/pip install sqlacodegen psycopg2-binary inflect
.v/bin/sqlacodegen --option use_inflect --tables $TABLES $DBURL
