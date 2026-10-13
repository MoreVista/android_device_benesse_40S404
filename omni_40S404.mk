$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/omni/config/common.mk)

PRODUCT_COPY_FILES += \
    bionic/libc/zoneinfo/tzdata:recovery/root/system/usr/share/zoneinfo/tzdata

PRODUCT_DEVICE := 40S404
PRODUCT_NAME := omni_40S404
PRODUCT_BRAND := benesse
PRODUCT_MODEL := 40S404
PRODUCT_MANUFACTURER := PANASONIC
PRODUCT_RELEASE_NAME := 40S404

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.build.product=40S404 \
    ro.product.device=40S404
