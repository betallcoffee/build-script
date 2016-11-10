#!/bin/sh
# source : http://github.com/webmproject/libvpx
# version : 1.6.0

CONFIGURE_FLAGS="--enable-static --disable-shared --disable-examples"

#TARGETS="arm64-darwin-gcc armv7s-darwin-gcc x86_64-iphonesimulator-gcc x86-iphonesimulator-gcc armv7-darwin-gcc"
ARCHS="arm64 armv7s x86_64 x86 armv7"

# directories
SOURCE="../libvpx-1.6.0"
FAT="pili-libvpx"

SCRATCH="libvpx-scratch"
# must be an absolute path
THIN=`pwd`/"libvpx-thin"

COMPILE="y"
LIPO="y"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		if [ "$ARCH" = "x86" -o "$ARCH" = "x86_64" ]
		then
			CFLAGS="$CFLAGS -mios-simulator-version-min=6.0"
			TARGET=$ARCH"-iphonesimulator-gcc"
		else
			CFLAGS="$CFLAGS -mios-version-min=6.0 -fembed-bitcode"
		    TARGET=$ARCH"-darwin-gcc"
		fi

		echo $TARGET
		echo "** CFLAGS=${CFLAGS}"
		
		$CWD/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
			--target=$TARGET \
		    --extra-cflags="$CFLAGS" \
			--extra-cxxflags="$CFLAGS" \
		    --prefix="$THIN/$ARCH"

		make -j3 install || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi
