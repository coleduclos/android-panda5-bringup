. bin/envsetup.sh

pushd pvrsrvkm
cd eurasia_km/eurasiacon/build/linux2/omap5430_android
make ARCH=arm TARGET_PRODUCT=omap5sevm BUILD=release PLATFORM_VERSION=4.0
popd


pushd omaplfb-wip/omaplfb_linux
make
popd

pushd sgx_2012-05-04_15-11-34
mkdir -p $DISCIMAGE
# rm $DISCIMAGE/*
# ./build_DDK.sh --build omap5 release clobber
# ./build_DDK.sh --build omap5 debug clobber
./build_DDK.sh --build omap5 debug
./build_DDK.sh --install omap5 debug
popd

cp -v pvrsrvkm/eurasia_km/eurasiacon/binary2_544_105_omap5430_android_release/target/kbuild/pvrsrvkm_sgx544_105.ko ${DISCIMAGE}/target/kbuild/pvrsrvkm_sgx544_105.ko

