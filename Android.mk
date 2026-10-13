LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),40S404)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
