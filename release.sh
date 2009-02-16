#!/bin/bash

VERSION=0.2
PREV_REV=119

REV=`svn info | awk '/^Revision: / { print $2 }'`
URL=`svn info | awk '/^URL: / { print $2 }'`

mkdir -p dist
svn export -r ${REV} ${URL} dist/escape-${VERSION}-${REV}
svn2cl.sh --break-before-msg --reparagraph -r ${PREV_REV}:HEAD -o dist/escape-${VERSION}-${REV}/ChangeLog.txt
(cd dist && zip -r -9 escape-${VERSION}-${REV}.zip escape-${VERSION}-${REV}/*)

