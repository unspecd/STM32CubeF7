#!/bin/sh -e

if [ -z $O ]; then
   export O=build
fi

export DEBUG=y

common="-mcpu=cortex-m7 -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb"
export AS="ccache arm-none-eabi-as ${common}"
export CC="ccache arm-none-eabi-gcc ${common} -mno-thumb-interwork -fno-pie -fno-pic"
export CXX="ccache arm-none-eabi-g++ ${common} -mno-thumb-interwork -fno-pie -fno-pic"

export PROJECT=$1
shift

case "$1" in
	clean)
		[ -d $O ] && rm -r $O
		shift
		;;
esac

make -r generate-project
make -r -j$(nproc) $@
