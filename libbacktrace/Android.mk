#
# Copyright (C) 2014 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH:= $(call my-dir)

common_cflags := \
	-Wall \
	-Werror \

common_conlyflags := \
	-std=gnu99 \

common_cppflags := \
	-std=gnu++11 \

build_host := false
ifeq ($(HOST_OS),linux)
ifeq ($(HOST_ARCH),$(filter $(HOST_ARCH),x86 x86_64))
build_host := true
endif
endif

#-------------------------------------------------------------------------
# The libbacktrace library.
#-------------------------------------------------------------------------
libbacktrace_src_files := \
	BacktraceImpl.cpp \
	BacktraceMap.cpp \
	BacktraceThread.cpp \
	thread_utils.c \

libbacktrace_shared_libraries_target := \
	libcutils \
	libgccdemangle \

# To enable using libunwind on each arch, add it to this list.
libunwind_architectures := arm arm64 x86 x86_64

ifeq ($(TARGET_ARCH),$(filter $(TARGET_ARCH),$(libunwind_architectures)))
libbacktrace_src_files += \
	UnwindCurrent.cpp \
	UnwindMap.cpp \
	UnwindPtrace.cpp \

libbacktrace_c_includes := \
	external/libunwind/include \

libbacktrace_shared_libraries := \
	libunwind \
	libunwind-ptrace \

libbacktrace_shared_libraries_host := \
	liblog \

libbacktrace_static_libraries_host := \
	libcutils \

else
libbacktrace_src_files += \
	Corkscrew.cpp \

libbacktrace_c_includes := \
	system/core/libcorkscrew \

libbacktrace_shared_libraries := \
	libcorkscrew \

libbacktrace_shared_libraries_target += \
	libdl \

libbacktrace_ldlibs_host := \
	-ldl \

endif

module := libbacktrace
module_tag := optional
build_type := target
build_target := SHARED_LIBRARY
include $(LOCAL_PATH)/Android.build.mk
build_type := host
include $(LOCAL_PATH)/Android.build.mk

#-------------------------------------------------------------------------
# The libbacktrace_test library needed by backtrace_test.
#-------------------------------------------------------------------------
libbacktrace_test_cflags := \
	-O0 \

libbacktrace_test_src_files := \
	backtrace_testlib.c \

module := libbacktrace_test
module_tag := debug
build_type := target
build_target := SHARED_LIBRARY
include $(LOCAL_PATH)/Android.build.mk
build_type := host
include $(LOCAL_PATH)/Android.build.mk

#-------------------------------------------------------------------------
# The backtrace_test executable.
#-------------------------------------------------------------------------
backtrace_test_cflags := \
	-fno-builtin \
	-O0 \
	-g \
	-DGTEST_HAS_STD_STRING \

ifneq ($(TARGET_ARCH),arm64)
backtrace_test_cflags += -fstack-protector-all
else
  $(info TODO: $(LOCAL_PATH)/Android.mk -fstack-protector not yet available for the AArch64 toolchain)
  common_cflags += -fno-stack-protector
endif # arm64

backtrace_test_cflags_target := \
	-DGTEST_OS_LINUX_ANDROID \

backtrace_test_src_files := \
	backtrace_test.cpp \
	thread_utils.c \

backtrace_test_ldlibs := \
	-lpthread \

backtrace_test_ldlibs_host := \
	-lrt \

backtrace_test_shared_libraries := \
	libbacktrace_test \
	libbacktrace \

backtrace_test_shared_libraries_target := \
	libcutils \

module := backtrace_test
module_tag := debug
build_type := target
build_target := NATIVE_TEST
include $(LOCAL_PATH)/Android.build.mk
build_type := host
include $(LOCAL_PATH)/Android.build.mk

#----------------------------------------------------------------------------
# Special truncated libbacktrace library for mac.
#----------------------------------------------------------------------------
ifeq ($(HOST_OS),darwin)

include $(CLEAR_VARS)

LOCAL_MODULE := libbacktrace
LOCAL_MODULE_TAGS := optional

LOCAL_SRC_FILES := \
	BacktraceMap.cpp \

include $(BUILD_HOST_SHARED_LIBRARY)

endif # HOST_OS-darwin
