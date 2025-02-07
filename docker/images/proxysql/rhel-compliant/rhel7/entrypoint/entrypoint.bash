#!/bin/bash
set -eu

echo "==> Build environment:"
env

ARCH=$PROXYSQL_BUILD_ARCH
echo "==> $ARCH architecture detected for package"

echo "==> Cleaning"
# Delete package if exists
rm -f /opt/proxysql/binaries/proxysql-${CURVER}-1-${PKG_RELEASE}.$ARCH.rpm || true
# Cleanup relic directories from a previously failed build
rm -fr /root/.pki /root/rpmbuild/{BUILDROOT,RPMS,SRPMS,BUILD,SOURCES,tmp} /opt/proxysql/proxysql /opt/proxysql/proxysql-${CURVER} || true

# Clean and build dependancies and source
echo "==> Building"
cd /opt/proxysql
if [[ -z ${PROXYSQL_BUILD_TYPE:-} ]] ; then
	deps_target="build_deps"
	build_target=""
else
	deps_target="build_deps_$PROXYSQL_BUILD_TYPE"
	build_target="$PROXYSQL_BUILD_TYPE"
fi
${MAKE} cleanbuild
${MAKE} ${MAKEOPT} "${deps_target}"

if [[ -z ${build_target} ]] ; then
	${MAKE} ${MAKEOPT}
else
	${MAKE} ${MAKEOPT} "${build_target}"
fi
touch /opt/proxysql/src/proxysql

# Prepare package files and build RPM
echo "==> Packaging"
mkdir -p proxysql/usr/bin proxysql/etc
cp src/proxysql proxysql/usr/bin/
cp -a systemd proxysql/etc/
cp -a etc/proxysql.cnf proxysql/etc/
cp -a etc/logrotate.d proxysql/etc/
mkdir -p proxysql/usr/share/proxysql/tools
cp -a tools/proxysql_galera_checker.sh tools/proxysql_galera_writer.pl proxysql/usr/share/proxysql/tools
mv proxysql "proxysql-${CURVER}"
tar czvf "proxysql-${CURVER}.tar.gz" proxysql-${CURVER}
mkdir -p /root/rpmbuild/{RPMS,SRPMS,BUILD,SOURCES,SPECS,tmp}
mv "/opt/proxysql/proxysql-${CURVER}.tar.gz" /root/rpmbuild/SOURCES
cd /root/rpmbuild && rpmbuild -ba SPECS/proxysql.spec --define "version ${CURVER}"
mv "/root/rpmbuild/RPMS/$ARCH/proxysql-${CURVER}-1.$ARCH.rpm" "/opt/proxysql/binaries/proxysql-${CURVER}-1-${PKG_RELEASE}.$ARCH.rpm"
cp "/opt/proxysql/src/proxysql.sha1" "/opt/proxysql/binaries/proxysql-${CURVER}-1-${PKG_RELEASE}.$ARCH.id-hash"
# Cleanup current build
rm -fr /root/.pki /root/rpmbuild/{BUILDROOT,RPMS,SRPMS,BUILD,SOURCES,tmp} /opt/proxysql/proxysql "/opt/proxysql/proxysql-${CURVER}"
