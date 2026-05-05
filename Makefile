.PHONY: dev sh exec kill all gen clean realclean

D=--name mtd -v`pwd`:`pwd` -v `pwd`/mtd-pgdata:/var/lib/postgresql/data

dev: .docker-build-mtd.stamp
	docker run  -it --rm $D mtd

sh: .docker-build-mtd.stamp
	docker run  -it --rm $D -w`pwd` mtd sh --login

.docker-build-mtd.stamp: Dockerfile
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
	find . -name .ve -o -name .venv | xargs rm -fr
	tree -I .git -I .kelvin -asF
