# TWRP device tree: Benesse Challenge Touch 40S404 (i.MX6Q)

Unofficial TWRP recovery for the Benesse "Challenge Touch" / "Challenge Pad" tablet,
model **40S404(-01)** (Freescale/NXP i.MX6, board `bee01`, Android 4.2.2, kernel 3.0.35).

**日本語:** ベネッセ「チャレンジタッチ」(40S404)用の非公式 TWRP デバイスツリーです。
純正 kernel を流用し、ramdisk だけを TWRP に差し替える方式です。**kernel などのバイナリは
このリポジトリに含まれません**(下記「Kernel」参照)。書き込みは自己責任で、必ず先に
純正 recovery をバックアップしてください。姉妹機種 41EA04 は別リポジトリです。

> Not affiliated with Benesse, Panasonic or TeamWin. Provided as is, without warranty.
> Flashing a recovery can make a device unbootable.

## Status

Verified on one real unit (2026-09/10):

| Item | State |
|---|---|
| Boots into TWRP from the recovery partition | works |
| GUI, screen, brightness | works |
| Touch | works, **needs patch 0001** (see below) |
| `adb` in recovery | works |
| `/cache`, `/data` | mounted by TWRP at start-up |
| `/system`, `/device`, `/factory` | mounted read-only by hand, contents intact (not exercised through the TWRP UI) |
| Reboot to Android from TWRP | works |
| Backup / restore, flashing zips, MTP | **not tested** (MTP is excluded to save space) |

## Hardware / partition layout

| Block device | Use |
|---|---|
| `mmcblk0p1` | boot (8 MB) |
| `mmcblk0p2` | recovery (8 MB) |
| `mmcblk0p3` | **MBR extended-partition container** (type 0x05, LBA 49152, ~2 GB) |
| `mmcblk0p4` | data |
| `mmcblk0p5` | system (ext4, 504 MB) |
| `mmcblk0p6` | cache (ext4, 504 MB) |
| `mmcblk0p7` | `/device` (ext4, ~1 GB, vendor content) |
| `mmcblk0p8` | factory (ext4, 8 MB) |

Panel 1024x768, backlight `pwm-backlight.0` (max 248), resistive touch `rohm_bu21025`.

## Do not map `/misc`

`mmcblk0p3` is **not** a misc partition. It is the extended-partition container that holds
p5-p8 as logical partitions. When TWRP reboots to system it clears the bootloader control
block; if `/misc` points at p3 that write zeroes the start of the container (its EBR chain).
The kernel then no longer sees system/cache/device/factory (`mmcblk0: p1 p2 p3 < > p4`) and
Android cannot boot. The file systems themselves survive and the table can be rebuilt, but
it is easy to avoid: the stock `recovery.fstab` has no `/misc` entry and neither does this one.

## Kernel (not included)

`BoardConfig.mk` expects `prebuilt/zImage`. This repository does not ship it. The unit's
`boot.img` and `recovery.img` carry the same kernel, so extract it from your own device:

```sh
# from a rooted Android shell on the tablet
adb shell su -c 'dd if=/dev/block/mmcblk0p1 of=/sdcard/boot.img bs=4096'
adb pull /sdcard/boot.img
python3 tools/extract_zimage.py boot.img prebuilt/zImage
```

Expected kernel for firmware `02.05.000` (built 2018-03-14): 3,854,680 bytes,
md5 `f3b3de4f3651acf70a5e88988f83b05f`. A different md5 means a different firmware build;
it may still work, but is untested.

## Building

Tested with the TWRP minimal manifest `platform_manifest_twrp_omni`, branch `twrp-5.1`
(Android 5.1.1 base; `bootable/recovery` is TeamWin `android-9.0`, commit `90e5d95`),
inside an Ubuntu 14.04 userland with OpenJDK 7 and Python 2.

1. Sync the tree, then apply the patches from `patches/` inside `bootable/recovery`:
   ```sh
   cd bootable/recovery
   git apply /path/to/this/repo/patches/0001-minuitwrp-board-defined-touch-range.patch
   git apply /path/to/this/repo/patches/0002-partition-nullptr-to-NULL.patch
   ```
   - `0001` adds `TW_TOUCH_X_MIN/MAX` and `TW_TOUCH_Y_MIN/MAX`. **Required** for this device;
     without it those board flags are silently ignored and touch is offset.
   - `0002` replaces one `nullptr` with `NULL` so the tree compiles with the old toolchain.
2. Put this repository at `device/benesse/40S404` as a **real directory** (copy or bind mount).
   A symlink does not work: the product lookup does not follow it and falls through to a
   network fetch.
3. Add `prebuilt/zImage` (see above), then:
   ```sh
   source build/envsetup.sh
   lunch omni_40S404-eng
   ALLOW_MISSING_DEPENDENCIES=true mka recoveryimage
   ```

The result is about 8.26 MB for an 8,388,608-byte partition (roughly 130 KB spare), so
adding features means removing something else. `TW_EXCLUDE_*` flags in `BoardConfig.mk`
are already set for that reason.

## Flashing

Back up the current recovery first, then write only `mmcblk0p2`:

```sh
adb shell su -c 'dd if=/dev/block/mmcblk0p2 of=/sdcard/stock-recovery.img bs=4096'
adb pull /sdcard/stock-recovery.img
adb push recovery.img /sdcard/recovery.img
adb shell su -c 'dd if=/sdcard/recovery.img of=/dev/block/mmcblk0p2 bs=4096'
adb reboot recovery
```

Read the partition back and compare checksums before rebooting. If you ever rebuild with
changed mount points, boot the **new** recovery once (`adb reboot recovery`) before rebooting
to system, because an already-running old instance keeps its old `recovery.fstab`.
Holding Home while powering on from off also enters recovery.

## Known issue

On this kernel the boot-time partition scan sometimes fails to walk the extended-partition
chain (`mmcblk0: p1 p2 p3 < > p4` on the console), in both stock Android and TWRP. Android
then hangs on a black screen. It is not data loss; a forced power-off and another boot
usually works. It predates this port and was not fixed here.

## Sources and licensing

- The kernel is GPLv2 and is **not** redistributed here. A third-party mirror of the GPL
  source archives for the 40S404 (kernel 3.0.35, board `bee01`) is at
  <https://github.com/puhitaku/40s404-01-source-code>; it has not been verified to be
  byte-identical to the kernel in your firmware. Ask Benesse for the corresponding source if
  you need certainty.
- TWRP is licensed by TeamWin; AOSP components under their own licenses. The patches here
  are against TeamWin's `bootable/recovery`.
- No stock firmware, recovery images or kernel binaries are included.
