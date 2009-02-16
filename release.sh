#!/bin/bash

VERSION=0.2
REV=`svn info | awk '/^Revision: / { print $2 }'`
URL=`svn info | awk '/^URL: / { print $2 }'`

mkdir -p dist
cd dist
svn export -r ${REV} ${URL} escape-${VERSION}-${REV}
zip -r -9 escape-${VERSION}-${REV}.zip escape-${VERSION}-${REV}/*

