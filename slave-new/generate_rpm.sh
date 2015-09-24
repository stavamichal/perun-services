#!/bin/bash

echo "--------------------------------------------"
echo "           GENERATE SPEC FILE"
echo "--------------------------------------------"

TMPDIR="/tmp/perun-slave-rpm-build"
GENERATE_RPM_FOR_SERVICE=$@
PREFIX="perun-slave-"
VERSION_FILE="$GENERATE_RPM_FOR_SERVICE/version"
BIN_DIR="$GENERATE_RPM_FOR_SERVICE/bin/"
CONF_DIR="$GENERATE_RPM_FOR_SERVICE/conf/"
LIB_DIR="$GENERATE_RPM_FOR_SERVICE/lib"
DEPENDENCIES="$GENERATE_RPM_FOR_SERVICE/rpm.dependencies"

if [ ! $GENERATE_RPM_FOR_SERVICE ]; then
  echo "Missing SERVICE directory info, exit without any work!"
	exit 0;
fi

if [ ! -d "$GENERATE_RPM_FOR_SERVICE" ]; then
  echo "Missing directory $GENERATE_RPM_FOR_SERVICE, exit with error!"
	exit 1;
fi

if [ ! -f "$VERSION_FILE" ]; then
	echo "Missing version file for service dir $GENERATE_RPM_FOR_SERVICE, exit with error!"
	exit 2;
fi

WITH_CONF=0
if [ -d "$CONF_DIR" ]; then
	WITH_CONF=1
fi

WITH_LIB=0
if [ -d "$LIB_DIR" ]; then
	WITH_LIB=1
fi

#tar everything in directory of concrete perun-service


mkdir -p ${TMPDIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

tar -zcvf ${TMPDIR}/SOURCES/${GENERATE_RPM_FOR_SERVICE}.tgz ${GENERATE_RPM_FOR_SERVICE}

# prepare variables and constant for creating spec file
VERSION=`head -n 1 $VERSION_FILE`
RELEASE="0.0.88"
SUMMARY="Perun slave script $GENERATE_RPM_FOR_SERVICE"
LICENSE="Apache License"
GROUP="Applications/System"
SOURCE="${GENERATE_RPM_FOR_SERVICE}.tgz"
REQUIRES=""
BUILDROOT="%{_tmppath}/%{name}-%{version}-build"
DESCRIPTION="Perun slave script $GENERATE_RPM_FOR_SERVICE"

# load dependencies
if [ -f "$DEPENDENCIES" ]; then 
	REQUIRES=`sed -e '$ ! s/$/,/' $DEPENDENCIES | tr '\n' ' '`
	REQUIRES="Requires: ${REQUIRES}";
fi

CUSTOM_CONF=""
CUSTOM_FILE_DATA=""
# conf predefined settings
if [ $WITH_CONF == 1 ]; then
	CUSTOM_CONF="mkdir -p %{buildroot}/etc/perun/${GENERATE_RPM_FOR_SERVICE}.d
cp -r conf/* %{buildroot}/etc/perun/${GENERATE_RPM_FOR_SERVICE}.d"
	CUSTOM_FILE_DATA="/etc/perun/${GENERATE_RPM_FOR_SERVICE}.d"
fi
if [ $WITH_LIB == 1 ]; then
  CUSTOM_CONF="$CUSTOM_CONF
mkdir -p %{buildroot}/opt/perun/bin/lib/
cp -r lib/* %{buildroot}/opt/perun/bin/lib/"
  CUSTOM_FILE_DATA="$CUSTOM_FILE_DATA
/opt/perun/bin/lib/"
fi

# generate spec file
SPEC_FILE_NAME="${GENERATE_RPM_FOR_SERVICE}.spec"

if [ ${GENERATE_RPM_FOR_SERVICE} = 'meta' ]; then

cat > $SPEC_FILE_NAME <<EOF
Name: ${PREFIX}${GENERATE_RPM_FOR_SERVICE}
Version: ${VERSION}
Release: ${RELEASE}
Summary: ${SUMMARY}
License: ${LICENSE}
Group: ${GROUP}
BuildArch: noarch
Source: ${SOURCE}
BuildRoot: $BUILDROOT
$REQUIRES

%description
Perun slave scripts

%prep
%setup -q -n${GENERATE_RPM_FOR_SERVICE}

%build

%install

%files
EOF

else

cat > $SPEC_FILE_NAME <<EOF
Name: ${PREFIX}${GENERATE_RPM_FOR_SERVICE}
Version: ${VERSION}
Release: ${RELEASE}
Summary: ${SUMMARY}
License: ${LICENSE}
Group: ${GROUP}
BuildArch: noarch
Source: ${SOURCE}
BuildRoot: $BUILDROOT
$REQUIRES

%description
Perun slave scripts

%prep
%setup -q -n${GENERATE_RPM_FOR_SERVICE}

%build

%install
mkdir -p %{buildroot}/opt/perun/bin
cp -r bin/* %{buildroot}/opt/perun/bin
$CUSTOM_CONF

%files
/opt/perun/bin/*
$CUSTOM_FILE_DATA
EOF

fi

#generate RPM
rpmbuild --define "_topdir ${TMPDIR}" -ba ${SPEC_FILE_NAME}

cp ${TMPDIR}/RPMS/noarch/*.rpm ./
rm -rf ${TMPDIR}
rm ${SPEC_FILE_NAME}

exit 0
