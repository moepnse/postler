
if [ -n "$1" ]; then
    if [ $1 = "all" ]; then
        TARGET_ARCHS="32 64"
    else
        TARGET_ARCHS=$1
    fi
else
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == "x86_64" ]; then
        TARGET_ARCHS=64
    else
        TARGET_ARCHS=32
    fi
fi

ZIP_FILES="postler log.so config/__init__.py config/tps.so config/lua.so doc/postler_dokumentation.pdf test/*.mail test/README etc/postler/config.tps"
VERSION=1.2.0.0
for TARGET_ARCH in $TARGET_ARCHS; do
    export TARGET_ARCH=$TARGET_ARCH
    #export CFLAGS="-m$TARGET_ARCH -O2"

    echo "building modules..."
    python setup.py build_ext --inplace

    echo "cythonizing postler..."
    cython --embed -o postler.c postler.pyx

    echo "compiling postler..."
    gcc -m$TARGET_ARCH -Os -I /usr/include/python2.7 -o postler postler.c -lpython2.7 -lpthread -lm -lutil -ldl

    echo "creating zip..."
    PACKAGE_NAME=postler-${VERSION}_${TARGET_ARCH}bit
    zip postler-${PACKAGE_NAME}.zip $ZIP_FILES
    echo "creating debian package..."
    rm -R deb/${PACKAGE_NAME}
    #mkdir -p deb/${PACKAGE_NAME}
    cp -R deb/templates/postler deb/${PACKAGE_NAME}
    #cp {test/*.mail,test/README} deb/${PACKAGE_NAME}/opt/postler/test/
    #cp etc/postler/config.{tps,lua} deb/${PACKAGE_NAME}/etc/postler/
    INSTALLED_SIZE=$(du -s deb/${PACKAGE_NAME}/opt/postler | cut -d$'\t' -f 1)
    if [ ${TARGET_ARCH} == "32" ]; then
        BIN_PATH=bin
        DEB_ARCH=i386
    else
        #mv deb/${PACKAGE_NAME}/opt/postler deb/${PACKAGE_NAME}/opt/postler64
        BIN_PATH=bin64
        DEB_ARCH=amd64
    fi
    cp {postler,log.so} deb/${PACKAGE_NAME}/opt/postler/${BIN_PATH}
    cp {config/__init__.py,config/tps.so,config/lua.so} deb/${PACKAGE_NAME}/opt/postler/${BIN_PATH}/config/
    echo "s/\$ARCH/${DEB_ARCH}/g; s/\$INSTALLED_SIZE/${INSTALLED_SIZE}/g;"
    sed -i "s/\$ARCH/${DEB_ARCH}/g; s/\$INSTALLED_SIZE/${INSTALLED_SIZE}/g;" deb/$PACKAGE_NAME/DEBIAN/control
    cat deb/$PACKAGE_NAME/DEBIAN/control
    dpkg -b deb/$PACKAGE_NAME deb/${PACKAGE_NAME}.deb
done

echo "creating documentation debian package..."
rm -R deb/postler-doc
cp -R deb/templates/postler-doc deb/postler-doc
cp doc/postler_dokumentation.pdf deb/postler-doc/opt/postler/doc/
INSTALLED_SIZE=$(du -s deb/postler-doc/opt/postler | cut -d$'\t' -f 1)
sed -i "s/\$INSTALLED_SIZE/${INSTALLED_SIZE}/g;" deb/postler-doc/DEBIAN/control
dpkg -b deb/postler-doc deb/postler-doc.deb

echo "creating test-data debian package..."
rm -R deb/postler-test-data
cp -R deb/templates/postler-test-data deb/postler-test-data
cp {test/*.mail,test/README} deb/postler-test-data/opt/postler/test/
INSTALLED_SIZE=$(du -s deb/postler-test-data/opt/postler | cut -d$'\t' -f 1)
sed -i "s/\$INSTALLED_SIZE/${INSTALLED_SIZE}/g;" deb/postler-test-data/DEBIAN/control
dpkg -b deb/postler-test-data deb/postler-test-data.deb

echo "creating config debian package..."
rm -R deb/postler-config
cp -R deb/templates/postler-config deb/postler-config
cp etc/postler/config.{tps,lua} deb/postler-config/etc/postler/
INSTALLED_SIZE=$(du -s deb/postler-config/etc/postler | cut -d$'\t' -f 1)
sed -i "s/\$INSTALLED_SIZE/${INSTALLED_SIZE}/g;" deb/postler-config/DEBIAN/control
dpkg -b deb/postler-config deb/postler-config.deb
