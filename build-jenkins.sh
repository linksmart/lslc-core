#!/bin/bash -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir "$DIR/build"
cd "$DIR/build"

export GOPATH=`pwd`
echo "GOROOT: $GOROOT"

# Get the version from pom.xml
VERSION=$(xmllint --xpath "string(//project/version)" "$DIR/pom.xml")

echo "VERSION: $VERSION"

# setup environment
"$DIR/setup.sh"

# build
"$DIR/release.sh" "$VERSION"

# clean up
rm -rf "$DIR/build/"

echo "Latest build is available in ./target:"
ls -1 "$DIR/target"

exit 0
