#!/bin/bash -e

VERSION=$1
GOOS=("linux" "darwin" "windows")
GOARCH=("amd64" "386" "arm")
MGOOS=`go env GOOS`
MGORCH=`go env GOARCH`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
echo "--------"
ls -la conf/devices

if [ "$VERSION" = "" ]; then
    VERSION="DEV"
fi

if [ -d "$DIR/target" ]; then
    rm -rf "$DIR/target/*"
else
    mkdir -p "$DIR/target"
fi

# get the code
#git clone https://linksmart.eu/redmine/linksmart-opensource/linksmart-local-connect/lslc-core.git 
#PROJECT_DIR="${DIR}/lslc-core"
PROJECT_DIR="${DIR}"
echo "PROJECT DIR: $PROJECT_DIR"
cd "${PROJECT_DIR}"

# grab newest flex4grid configuration artifact
MAVEN_METADATA=maven-metadata.xml
ARTIFACT_NAME="LSLC-Configuration"
ARTIFACT_VERSION="0.2.1-SNAPSHOT"
REPO_URL="https://linksmart.eu/repo/content/repositories/public/eu/linksmart/lc/flex4grid/LSLC-Configuration/$ARTIFACT_VERSION/"
echo "maven metadata file : $MAVEN_METADATA"
echo "repo url : $REPO_URL"
# retrieve maven metadata to get latest distribution artifact
wget $REPO_URL$MAVEN_METADATA
# extract latest version over xpath (SNAPSHOT only, won't work with release)
export LSGC_BUILD=$(xmllint --xpath "string(//metadata/versioning/snapshotVersions/snapshotVersion[2]/value)" $MAVEN_METADATA)
#export LSGC_BUILD="0.2.0"
echo "current flex4grid configuration artifact: $LSGC_BUILD"
echo "----------"
ls -la conf/devices
# grab latest binary distribution from artifact server
wget $REPO_URL$ARTIFACT_NAME-$LSGC_BUILD-bin.tar.gz
export LSGC_CONFIG_FILE=$ARTIFACT_NAME-$LSGC_BUILD-bin.tar.gz
echo "-------"
ls -la conf/devices
tar xvfz $LSGC_CONFIG_FILE
echo "-------"
ls -la conf/devices
chmod -R a+w templates/
chmod -R a+w conf/
chmod -R a+w agents/
# remove downloaded configuration artifact
rm maven-metadata.xml
rm $LSGC_CONFIG_FILE

for os in "${GOOS[@]}"
do
    for arch in "${GOARCH[@]}"
    do
        # skip irrelevant combinations
        # darwin: no 386 or arm
        if [ ${os} == "darwin" ]; then
            if [ ${arch} == "386" ] || [ ${arch} == "arm" ]; then
                continue
            fi
        fi
        # windows: no arm
        if [ ${os} == "windows" ] && [ ${arch} == "arm" ]; then
            continue
        fi

        suffix=`echo "${os}/${arch}" | tr / _`
        p="lslc-${VERSION}_${suffix}"
        d="${DIR}/target/${p}"
        mkdir -p "$d"

        # compile
        # pushd "$d"
        pushd "${PROJECT_DIR}"
        if [ ${MGOOS} == ${os} ] && [ ${MGORCH} == ${arch} ]; then
            # native build
            echo "native build for ${os}/${arch}..."
            gb build all

            # move
            mv bin/device-gateway "${d}"
            mv bin/resource-catalog "${d}"
            mv bin/service-catalog "${d}"
            mv bin/service-registrator "${d}"
        else
            # cross-compile
            echo "cross build for ${os}/${arch}..."
            env GOOS=${os} GOARCH=${arch} gb build all

            # move
            if [ ${os} == "windows" ]; then
                # windowzz
                mv bin/device-gateway-${os}-${arch}.exe "${d}/device-gateway.exe"
                mv bin/resource-catalog-${os}-${arch}.exe "${d}/resource-catalog.exe"
                mv bin/service-catalog-${os}-${arch}.exe "${d}/service-catalog.exe"
                mv bin/service-registrator-${os}-${arch}.exe "${d}/service-registrator.exe"
            else
                mv bin/device-gateway-${os}-${arch} "${d}/device-gateway"
                mv bin/resource-catalog-${os}-${arch} "${d}/resource-catalog"
                mv bin/service-catalog-${os}-${arch} "${d}/service-catalog"
                mv bin/service-registrator-${os}-${arch} "${d}/service-registrator"
            fi
        fi
        popd
	echo "creating directiories..."
        # Copy configuration
        mkdir -p "$d/conf/devices"
        mkdir -p "$d/agents"
	mkdir -p "$d/templates"
#        mkdir -p "$d/conf/services"
	echo "copying files..."
        cp -v "$DIR"/ZwaveMultiplexer.py "$d/"
        cp -v "$DIR"/registerHousehold.sh "$d/"
        cp -Rvp "$DIR"/conf/*.* "$d/conf/"
        cp -Rv "$DIR"/conf/devices/*.json "$d/conf/devices/"
        #cp -Rv "$DIR"/conf/services/*.json "$d/conf/services/"
	cp -v "$DIR"/README.md "$d/"
	echo "[OK] configuration files copied."

        # Copy examples of agents
        #mkdir "$d/agent-examples"
        cp -Rv "$DIR"/agents/* "$d/agents"
	echo "[OK] agents copied."

        # Copy templates
	cp -Rv "$DIR"/templates/* "$d/templates"
	echo "[OK] templates copied."

        # Copy static
        mkdir -p "$d/static/"
        cp -Rv "$DIR"/static/ctx "$d/static/"

        # Copy dashboard
        mkdir -p "$d/static/dashboard/css"
        cp -Rv "$DIR"/static/dashboard/css/freeboard.min.css "$d/static/dashboard/css/"
        mkdir -p "$d/static/dashboard/img"
        cp -Rv "$DIR"/static/dashboard/img/dropdown-arrow.png "$d/static/dashboard/img/"
        cp -Rv "$DIR"/static/dashboard/img/glyphicons-halflings-white.png "$d/static/dashboard/img/"
        cp -Rv "$DIR"/static/dashboard/img/glyphicons-halflings.png "$d/static/dashboard/img/"
        cp -Rv "$DIR"/static/dashboard/index.html "$d/static/dashboard/"
        mkdir -p "$d/static/dashboard/js"
        cp -Rv "$DIR"/static/dashboard/js/freeboard+plugins.min.js "$d/static/dashboard/js/"
        cp -Rv "$DIR"/static/dashboard/js/freeboard+plugins.min.js.map "$d/static/dashboard/js/"
        cp -Rv "$DIR"/static/dashboard/js/freeboard.min.js "$d/static/dashboard/js/"
        cp -Rv "$DIR"/static/dashboard/js/freeboard.min.js.map "$d/static/dashboard/js/"
        cp -Rv "$DIR"/static/dashboard/js/freeboard.plugins.min.js "$d/static/dashboard/js/"
        cp -Rv "$DIR"/static/dashboard/js/freeboard.plugins.min.js.map "$d/static/dashboard/js/"
        cp -Rv "$DIR"/static/dashboard/js/freeboard.thirdparty.min.js "$d/static/dashboard/js/"
        mkdir -p "$d/static/dashboard/plugins/freeboard"
        mkdir -p "$d/static/dashboard/plugins/thirdparty"
        cp -Rv "$DIR"/static/dashboard/plugins/freeboard/freeboard.datasources.js "$d/static/dashboard/plugins/freeboard/"
        cp -Rv "$DIR"/static/dashboard/plugins/freeboard/freeboard.widgets.js "$d/static/dashboard/plugins/freeboard/"
        cp -Rv "$DIR"/static/dashboard/plugins/thirdparty/jquery.sparkline.min.js "$d/static/dashboard/plugins/thirdparty/"
        cp -Rv "$DIR"/static/dashboard/plugins/thirdparty/justgage.1.0.1.js "$d/static/dashboard/plugins/thirdparty/"
        cp -Rv "$DIR"/static/dashboard/plugins/thirdparty/raphael.2.1.0.min.js "$d/static/dashboard/plugins/thirdparty/"

        # Copy docs
        #cp -R ${DIR}/docs $d/
        #cp wiki.pdf $d/

        # remove mac crap
        find "$d/" -type f -name "._*" -exec rm -f {} \;

        cd "$DIR/target" && zip -9 -r "${p}.zip" "$p"
        cd "$DIR/target" && tar -zcvf "${p}.tar.gz" "$p"
        rm -rf "$d"
    done
done

# remove the code
echo "SKIPPING rm -rf of $PROJECT_DIR"
#rm -rf ${PROJECT_DIR}/

echo "DONE!"
exit 0
