#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp_adzan"
RAW_DIR="${ROOT_DIR}/android/app/src/main/res/raw"

MAKKAH_WMV="https://archive.org/download/MakkahAzan/13thNov09FajrAzan.wmv"
MADINAH_WMV="https://archive.org/download/MakkahAzan/14thNov09MadinahFajrAzan.wmv"

mkdir -p "${TMP_DIR}" "${RAW_DIR}"

download() {
  local url="$1"
  local out="$2"
  if [ -f "${out}" ]; then
    return
  fi
  curl -L --retry 3 --retry-delay 2 -o "${out}" "${url}"
}

download "${MAKKAH_WMV}" "${TMP_DIR}/makkah.wmv"
download "${MADINAH_WMV}" "${TMP_DIR}/madinah.wmv"

rm -f "${RAW_DIR}/azan_makkah.mp3"
rm -f "${RAW_DIR}/azan_madinah.mp3"

ffmpeg -y -i "${TMP_DIR}/makkah.wmv" -vn -ac 1 -ar 44100 -c:a libvorbis "${RAW_DIR}/azan_makkah.ogg"
ffmpeg -y -i "${TMP_DIR}/madinah.wmv" -vn -ac 1 -ar 44100 -c:a libvorbis "${RAW_DIR}/azan_madinah.ogg"

rm -rf "${TMP_DIR}"
