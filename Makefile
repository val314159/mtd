D=--name mtd -w`pwd` -v`pwd`:`pwd`

dev:
	docker build -t mtd .
	docker run --rm -it $D mtd

sh:
	docker build -t mtd .
	docker run --rm -it $D mtd sh --login

all:
	python core.py

clean:
	rm *.log
	find . -name  \*~ | xargs rm -fr
	find . -name .\*~ | xargs rm -fr
	find . -name __pycache__ | xargs rm -fr
	tree -I .git -I .kelvin -a
