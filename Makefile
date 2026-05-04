all:
	python core.py

clean:
	find . -name  \*~ | xargs rm -fr
	find . -name .\*~ | xargs rm -fr
	find . -name __pycache__ | xargs rm -fr
	tree -I .git -a

