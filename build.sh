#!/bin/bash

# 更新 KernelSU (默认稳定版分支)
read -p "是否更新 KernelSU？（默认为稳定版分支）(y/n): " choice
if [ "$choice" = "y" ]; then
  rm -rf KernelSU/
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
fi

# AnyKernel3 路径
ANYKERNEL3_DIR=$PWD/AnyKernel3/
# 编译完成后内核名字
FINAL_KERNEL_ZIP=perf_KernelSU_A13_dibin.zip
# 内核工作目录
export KERNEL_DIR=$(pwd)
# 内核 defconfig 文件
export KERNEL_DEFCONFIG=vendor/lmi_user_defconfig
# 编译临时目录，避免污染根目录
export OUT=out
# clang 绝对路径
export CLANG_PATH=/mnt/disk/tool/clang
export PATH=${CLANG_PATH}/bin:$PATH
# arch平台，这里时arm64
export ARCH=arm64
#export SUBARCH=arm64
export LLVM=1

# ./build.sh 4

#16为线程数，可以指定#
TH_COUNT=16
if [[ "" != "$1" ]]; then
        TH_NUM=$1
fi

export DEF_ARGS="O=${OUT} \
                                CC=clang \
                                ARCH=${ARCH} \
                                CROSS_COMPILE=${CLANG_PATH}/bin/aarch64-linux-gnu- \
        			NM=llvm-nm \
				AR=llvm-ar
        			OBJCOPY=llvm-objcopy \
        			OBJDUMP=llvm-objdump \
        			STRIP=llvm-strip \
				LD=ld.lld "

export BUILD_ARGS="-j${TH_COUNT} ${DEF_ARGS}"

echo -e "$yellow**** 开始编译内核 ****$nocol"
make ${DEF_ARGS} ${KERNEL_DEFCONFIG}
make ${BUILD_ARGS}

echo -e "$yellow**** 验证 Image.gz-dtb 和 dtbo.img****$nocol"
ls $PWD/out/arch/arm64/boot/dtbo.img
ls $PWD/out/arch/arm64/boot/Image.gz-dtb
echo -e "$yellow**** 进入 AnyKernel3 目录 ****$nocol"
ls $ANYKERNEL3_DIR
echo -e "$yellow**** 清理 AnyKernel3 目录 ****$nocol"
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
echo -e "$yellow**** 复制 Image.gz-dtb 和 dtbo.img 到 AnyKernel3 目录 ****$nocol"
cp $PWD/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/
echo -e "$yellow**** 正在打包内核为可刷入 Zip 文件 ****$nocol"
cd $ANYKERNEL3_DIR/
zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
echo -e "$yellow**** 复制打包好的 Zip 文件到指定的目录 ****$nocol"
cp $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP /mnt/disk/kernelout
echo -e "$yellow**** 清理目录 ****$nocol"
cd ..
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf out/
echo -e "$yellow**** 构建完成 ****$nocol"
