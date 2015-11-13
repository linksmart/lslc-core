#!/bin/bash

export LANG=C
export LC_ALL=C

if [ "$#" -ne 2 ]
then
	echo "usage: $0 CURRENT_VERSION NEW_VERSION"
fi
CUR=$1
NEW=$2

echo "Bumping version from $CUR to $NEW..."
find pom.xml distribution-* -type f -print0 | xargs -0 sed -i '' 's|'${CUR}'|'${NEW}'|g'