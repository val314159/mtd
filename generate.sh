#!/bin/sh
set -eu
DBURL=${DBURL:-postgresql+psycopg2://$PGUSER@$PGHOST/$PGDATABASE}
TABLES=`echo $* | tr ' ' ','`
apk add py3-virtualenv
virtualenv .ve
.ve/bin/pip install sqlacodegen psycopg2-binary inflect
.ve/bin/sqlacodegen --option use_inflect --tables $TABLES $DBURL
