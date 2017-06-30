PROJ=faust
PGPIDENT="Celery Security Team"
PYTHON=python3.6
PYTEST=py.test
PIP=pip
GIT=git
TOX=tox
NOSETESTS=nosetests
ICONV=iconv
FLAKE8=flake8
PYDOCSTYLE=pydocstyle
MYPY=mypy
SPHINX2RST=sphinx2rst
BUMPVERSION=bumpversion

TESTDIR=t
SPHINX_DIR=docs/
SPHINX_BUILDDIR="${SPHINX_DIR}/_build"
README=README.rst
README_SRC="docs/templates/readme.txt"
CONTRIBUTING=CONTRIBUTING.rst
CONTRIBUTING_SRC="docs/contributing.rst"
SPHINX_HTMLDIR="${SPHINX_BUILDDIR}/html"
DOCUMENTATION=Documentation

all: help

help:
	@echo "docs                 - Build documentation."
	@echo "test-all             - Run tests for all supported python versions."
	@echo "distcheck ---------- - Check distribution for problems."
	@echo "  test               - Run unittests using current python."
	@echo "  lint ------------  - Check codebase for problems."
	@echo "    apicheck         - Check API reference coverage."
	@echo "    configcheck      - Check configuration reference coverage."
	@echo "    readmecheck      - Check README.rst encoding."
	@echo "    contribcheck     - Check CONTRIBUTING.rst encoding"
	@echo "    flakes --------  - Check code for syntax and style errors."
	@echo "      typecheck      - Run the mypy type checker"
	@echo "      flakecheck     - Run flake8 on the source code."
	@echo "      pep257check    - Run pep257 on the source code."
	@echo "readme               - Regenerate README.rst file."
	@echo "contrib              - Regenerate CONTRIBUTING.rst file"
	@echo "clean-dist --------- - Clean all distribution build artifacts."
	@echo "  clean-git-force    - Remove all uncomitted files."
	@echo "  clean ------------ - Non-destructive clean"
	@echo "    clean-pyc        - Remove .pyc/__pycache__ files"
	@echo "    clean-docs       - Remove documentation build artifacts."
	@echo "    clean-build      - Remove setup artifacts."
	@echo "bump                 - Bump patch version number."
	@echo "bump-minor           - Bump minor version number."
	@echo "bump-major           - Bump major version number."
	@echo "release              - Make PyPI release."

clean: clean-docs clean-pyc clean-build

clean-dist: clean clean-git-force

bump:
	$(BUMPVERSION) patch

bump-minor:
	$(BUMPVERSION) minor

bump-major:
	$(BUMPVERSION) major

release:
	$(PYTHON) setup.py register sdist bdist_wheel upload --sign --identity="$(PGPIDENT)"

Documentation:
	$(PIP) install -r requirements/docs.txt
	(cd "$(SPHINX_DIR)"; $(MAKE) html)
	mv "$(SPHINX_HTMLDIR)" $(DOCUMENTATION)

docs: Documentation

clean-docs:
	-rm -rf "$(SPHINX_BUILDDIR)"

lint: flakecheck apicheck configcheck readmecheck

apicheck:
	(cd "$(SPHINX_DIR)"; $(MAKE) apicheck)

configcheck:
	(cd "$(SPHINX_DIR)"; $(MAKE) configcheck)

flakecheck:
	$(FLAKE8) "$(PROJ)" "$(TESTDIR)" examples/

pep257check:
	$(PYDOCSTYLE) "$(PROJ)"

flakediag:
	-$(MAKE) flakecheck

flakes: flakediag

clean-readme:
	-rm -f $(README)

readmecheck:
	$(ICONV) -f ascii -t ascii $(README) >/dev/null

$(README):
	$(SPHINX2RST) "$(README_SRC)" --ascii > $@

readme: clean-readme $(README) readmecheck

clean-contrib:
	-rm -f "$(CONTRIBUTING)"

$(CONTRIBUTING):
	$(SPHINX2RST) "$(CONTRIBUTING_SRC)" > $@

contrib: clean-contrib $(CONTRIBUTING)

clean-pyc:
	-find . -type f -a \( -name "*.pyc" -o -name "*$$py.class" \) | xargs rm
	-find . -type d -name "__pycache__" | xargs rm -r

removepyc: clean-pyc

clean-build:
	rm -rf build/ dist/ .eggs/ *.egg-info/ .tox/ .coverage cover/

clean-git:
	$(GIT) clean -xdn

clean-git-force:
	$(GIT) clean -xdf

test-all: clean-pyc
	$(TOX)

test:
	$(PYTHON) setup.py test

cov:
	$(PYTEST) -x --cov="$(PROJ)" --cov-report=html

build:
	$(PYTHON) setup.py sdist bdist_wheel

distcheck: lint test clean

dist: readme contrib clean-dist build

typecheck:
	$(PYTHON) -m $(MYPY) $(PROJ)

.PHONY: requirements
requirements:
	$(PIP) install --upgrade pip;\
	for f in `ls requirements/` ; do $(PIP) install -r requirements/$$f ; done

.PHONY: clean-requirements
clean-requirements:
	pip freeze | xargs pip uninstall -y
	$(MAKE) requirements
