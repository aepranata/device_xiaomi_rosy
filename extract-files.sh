#!/bin/bash
#
# Copyright (C) 2018-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=rosy
VENDOR=xiaomi

DEVICE_BRINGUP_YEAR=2018

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )
            CLEAN_VENDOR=false
            ;;
        -k | --kang )
            KANG="--kang"
            ;;
        -s | --section )
            shift
            SECTION=$1
            CLEAN_VENDOR=false
            ;;
        * )
            SRC=$1
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC=adb
fi

function blob_fixup() {
    case "${1}" in
        vendor/lib64/libwvhidl.so)
            "${PATCHELF}" --replace-needed "libcrypto.so" "libcrypto-v34.so" "${2}"
        ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
    "${KANG}" --section "${SECTION}"

DEVICE_BLOB_ROOT="${ANDROID_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary"

"${MY_DIR}/setup-makefiles.sh"
