DEVICE_PATH := device/benesse/40S404

# Platform
TARGET_BOOTLOADER_BOARD_NAME := SABRESD
TARGET_BOARD_PLATFORM := imx6
TARGET_NO_BOOTLOADER := true

# Architecture (i.MX6Q, quad Cortex-A9, 32-bit only)
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
TARGET_CPU_SMP := true
ARCH_ARM_HAVE_TLS_REGISTER := true

# Kernel: reused verbatim from the stock device (kernel 3.0.35, Freescale
# Android BSP). boot.img and recovery.img on the real unit ship the exact
# same kernel blob (md5 f3b3de4f3651acf70a5e88988f83b05f for both), so this
# zImage is proven to boot on this hardware -- no kernel rebuild needed for
# a ramdisk-only TWRP port.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/zImage
BOARD_KERNEL_CMDLINE := console=ttymxc0,115200 init=/init video=mxcfb0:dev=ldb,bpp=32 video=mxcfb1:off video=mxcfb2:off fbmem=10M fb0base=0x27b00000 vmalloc=400M androidboot.console=ttymxc0 androidboot.hardware=freescale androidboot.selinux=permissive
# Header fields derived directly from the extracted stock boot.img:
#   kernel_addr=0x10808000 ramdisk_addr=0x11800000 tags_addr=0x10800100
#   => base=0x10800000, ramdisk_offset=0x01000000, tags_offset=0x00000100
BOARD_KERNEL_BASE := 0x10800000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x01000000 --tags_offset 0x00000100

# Partitions (live values read from the real unit via `adb shell cat
# /proc/partitions` + `su -c cat /fstab.freescale`, 2026-09-27).
# mmcblk0: p1=boot p2=recovery p3=misc p4=data p5=system p6=cache p7=device p8=factory
BOARD_BOOTIMAGE_PARTITION_SIZE     := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 8388608
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 528482304
BOARD_USERDATAIMAGE_PARTITION_SIZE := 13539213312
BOARD_CACHEIMAGE_PARTITION_SIZE    := 528482304
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE  := ext4
BOARD_FLASH_BLOCK_SIZE := 131072
TARGET_USERIMAGES_USE_EXT4 := true

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_SUPPRESS_SECURE_ERASE := true
# No physical /sdcard partition in normal operation -- stock Android mounts
# only system/data/cache/device (see /fstab.freescale on-device);
# "internal storage" is FUSE-emulated from /data/media, same as any Android
# 4.2-era device without a separate userdata/media split.
RECOVERY_SDCARD_ON_DATA := true

# TWRP UI. Panel is 1024x768 landscape, ~160dpi (adb shell dumpsys display).
DEVICE_RESOLUTION := 1024x768
TW_THEME := landscape_mdpi
# Backlight is a pwm-backlight sysfs class, NOT auto-driven by TWRP without
# an explicit path -- confirmed on-device 2026-09-27: brightness stayed 0
# (screen fully black, GUI still rendering to fb0 underneath) until this
# path was set and a value written. max_brightness reported by the kernel
# is 248, not 255 -- writing 255 is rejected with EINVAL.
TW_BRIGHTNESS_PATH := "/sys/class/backlight/pwm-backlight.0/brightness"
TW_MAX_BRIGHTNESS := 248
TW_DEFAULT_BRIGHTNESS := 200
TW_NO_SCREEN_BLANK := true
# Confirmed on-device 2026-09-27: after the inactivity timer fires, the
# backlight brightness drops to 0 and TWRP never restores it on touch/wake
# (manually re-writing the brightness sysfs node brings the screen straight
# back, so the panel itself is fine -- this is purely TWRP's blanktimer not
# un-dimming it). Never let the timer fire at all.
TW_NO_SCREEN_TIMEOUT := true

# Touch: rohm_bu21025 (single-touch, resistive, /proc/bus/input/devices).
# The kernel driver calibrates to the 1024x768 panel size (X_CALIB_MAX/Y_CALIB_MAX in rohm_bu21025.c) but
# its declared/actual ABS range doesn't reach the full 0..1024 / 0..768 --
# confirmed on-device 2026-09-27 via raw `dd if=/dev/input/event1 bs=16`
# capture while tapping the top-left and bottom-right corners:
#   top-left tap    -> X~40-54  Y~70-76
#   bottom-right tap -> X~933-936 Y~709-732
# Without correction minuitwrp's linear scale (which assumes the kernel's
# declared min/max already spans the full screen) reads as touches
# registering above/left of the actual finger position.
# REQUIRES patches/0001-minuitwrp-board-defined-touch-range.patch: stock TWRP
# has no TW_TOUCH_* flags, so without that patch these four values are
# silently ignored and the touch offset comes back.
TW_TOUCH_X_MIN := 40
TW_TOUCH_X_MAX := 936
TW_TOUCH_Y_MIN := 70
TW_TOUCH_Y_MAX := 732

# This kernel predates SELinux entirely (Android 4.2.2, no
# CONFIG_SECURITY_SELINUX) -- nothing else to disable here, TWRP's selinux
# calls are expected to just no-op against a kernel with no LSM hooks.

# Size budget is tight: 8MB recovery partition - ~3.77MB kernel leaves only
# ~4.3MB for the compressed ramdisk. Trim aggressively from the start.
TW_EXCLUDE_TWRPAPP := true
TW_EXCLUDE_SUPERSU := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_TZDATA := true
TW_NO_EXFAT_FUSE := true
TW_EXCLUDE_MTP := true
