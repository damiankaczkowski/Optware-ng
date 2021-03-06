#!/bin/sh
BSDIR="/home/.optware/ipkg-bootstrap"

echo "Creating temporary ipkg repository..."
rm -rf $BSDIR
mkdir -p $BSDIR
ln -s $BSDIR /tmp/ipkg
cat >>$BSDIR/ipkg.conf <<EOF
dest root /
lists_dir ext $BSDIR/ipkg
EOF

export IPKG_CONF_DIR=$BSDIR 
export IPKG_DIR_PREFIX=$BSDIR 

echo "Installing FSG-3 bootstrap package..."
mkdir -p /usr/lib/ipkg/info/
sh ./ipkg.sh install bootstrap.ipk

echo "Installing ipkg..."
sh ./ipkg.sh install ipkg.ipk

echo "Removing temporary ipkg repository..."
rm -rf $BSDIR
rm /tmp/ipkg
rm -rf /usr/lib/ipkg

echo "Installing OpenSSL..."
%OPTWARE_TARGET_PREFIX%/bin/ipkg install openssl.ipk || exit 1

echo "Installing wget..."
%OPTWARE_TARGET_PREFIX%/bin/ipkg install wget-ssl.ipk || exit 1

[ ! -d %OPTWARE_TARGET_PREFIX%/etc/ipkg ] && mkdir -p %OPTWARE_TARGET_PREFIX%/etc/ipkg
if [ ! -e %OPTWARE_TARGET_PREFIX%/etc/ipkg/cross-feed.conf ]
then
	echo "Creating %OPTWARE_TARGET_PREFIX%/etc/ipkg/cross-feed.conf..."
	echo "src/gz cross http://ipkg.nslu2-linux.org/feeds/optware/fsg3/cross/stable" >%OPTWARE_TARGET_PREFIX%/etc/ipkg/cross-feed.conf
fi

echo "Setup complete."
