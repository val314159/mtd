.PHONY: docker sh exec kill all gen clean realclean

D=--name mtd -v`pwd`:`pwd` -v `pwd`/mtd-pgdata:/var/lib/postgresql/data

docker: .docker-build-mtd.stamp
	docker run  -it --rm $D mtd || rm -fr mtd-pgdata

sh: .docker-build-mtd.stamp
	docker run  -it --rm $D -w`pwd` mtd sh --login

.docker-build-mtd.stamp: Dockerfile src
	rm -fr mtd-pgdata
	docker build -t mtd .
	touch $@

exec:
	docker exec -it -w`pwd` mtd sh --login

kill:
	docker exec -it mtd killall -9 supervisord

all:
	PYTHONPATH=src python -m mtd.core

gen: models.py

models.py:
	sh generate.sh workflows,tasks,jobs >$@

clean:
	rm -fr *.log
	find . -name    \*~  | xargs rm -fr
	find . -name   .\*~  | xargs rm -fr
	find . -name  \#\*\# | xargs rm -fr
	find . -name .\#\*   | xargs rm -fr

realclean: clean
	rm -fr .docker-build-mtd.stamp
	rm -fr mtd-pgdata uv.lock models.py
	find . -name __pycache__ | xargs rm -fr
	find . -name .v\*        | xargs rm -fr
	tree -I .git -I .kelvin -asF
