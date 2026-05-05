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
#for arg in "$@"; do
#    echo "arg: $arg"
#done

echo "from mixins import *" >_models.py
.v/bin/sqlacodegen --option use_inflect --tables $TABLES $DBURL >> _models.py
sed -E 's/class ([[:alnum:]_]+)\(Base\):/class \1(\1Mixin, Base):/' _models.py >models.py
rm -f _models.py
