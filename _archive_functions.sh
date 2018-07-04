#!/bin/bash

# Copyright 2018 Meik Michalke <meik.michalke@hhu.de>
#
# This file is part of the bash scripts collection apa.
#
# apa is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# apa is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with apa.  If not, see <http://www.gnu.org/licenses/>.

TXT_DGRAY="\033[1;30m"
TXT_LRED="\033[1;31m"
TXT_RED="\033[0;31m"
TXT_BLUE="\033[0;34m"
TXT_GREEN="\033[0;32m"
TXT_BOLD="\033[1m"
TXT_ITALIC="\033[3m"
TXT_UNDERSCORE="\033[4m"
# 48;5 for background, 38;5 for foreground, colors see ~/.post_install/bash/color_codes.png
TXT_ORANGE_ON_GREY="\033[48;5;240;38;5;202m"
OFF="\033[0m"

warning() {
  # $1: message to print
  echo -e "${TXT_ORANGE_ON_GREY}warning:${OFF} $1"
}

error() {
  # $1: message to print
  echo -e "${TXT_LRED}error:${OFF} $1"
  exit 1
}

verified() {
  echo -e "${TXT_GREEN}$1${OFF} successfully verified!\n"
}

alldone() {
  echo -e " ${TXT_GREEN}done! ${OFF}"
}

mkmissingdir() {
  # $1: path to check
  if [ ! -d "${1}" ] ; then
    echo -en "create missing directory ${TXT_BLUE}$1${OFF}..."
    mkdir -p "${1}" || error "failed!"
    alldone
  fi
}

check_tool() {
  # checks if the given tool is available
  # if there's only one parameter, "which" is called and the result returned
  # if there's two, the functions exits silently if there are no errors
  # $1: name of tool to look up
  # $2: path to tool
  if [ "$2" != "" ] ; then
    TOOL="$2"
  else
    TOOL="$(which $1)"
  fi
  if [ -x "$TOOL" ] ; then
    if [ "$2" == "" ] ; then
      echo "\"$TOOL\""
    fi
  else
    error "can't find $1, please check your configuration!"
  fi
}

appendconfig () {
  # appends given text as a new line to given file
  # $1: file name, full path
  # $2: stuff to grep for in $1 to check whether the entry is already there
  # $3: full line to add to $1 otherwise
  # $4: the key word "sudo" if sudo is needed for the operation, "config" to silence skips
  check_tool "grep" "$(which grep)"
  check_tool "tee" "$(which tee)"
  if ! [[ $(grep "$2" "$1") ]] ; then
    echo -en "appending ${TXT_BLUE}$2${OFF} to ${TXT_BLUE}$1${OFF}..."
    if [[ $4 == "sudo" ]] ; then
      echo -e "$3" | sudo tee --append "$1" > /dev/null || error "failed!"
    else
      echo -e "$3" >> "$1" || error "failed!"
    fi
    alldone
  elif ! [[ $4 == "config" ]] ; then
    echo -e "exists, ${TXT_BOLD}skip${OFF} appending to ${TXT_BLUE}$1${OFF} (${TXT_BLUE}$2${OFF})"
  fi
}

checksums() {
  # generates an uncompressed tar archive and two checksum files of its content (SHA256 and SHA512)
  # $1: directory to archive
  # $2: target tar file
  # $3: SHA256 checksum file
  # $4: SHA512 checksum file
  check_tool "tar" "$(which tar)"
  check_tool "tee" "$(which tee)"
  check_tool "test" "$(which test)"
  check_tool "xargs" "$(which xargs)"
  check_tool "sha256sum" "$(which sha256sum)"
  check_tool "sha512sum" "$(which sha512sum)"
  OLDDIR="$(pwd)"
  cd "$1"
  tar cvpf "$2" . | \
    tee >(xargs -I '{}' sh -c "test -f '{}' && sha256sum '{}'" > "$3") | \
    xargs -I '{}' sh -c "test -f '{}' && sha512sum '{}'" > "$4"
  cd "${OLDDIR}"
}

OpenPGP_sign_file() {
  # clearsings a given file with a given PGP key
  # $1: input file to sign
  # $2: output file
  # $3: OpenPGP key ID
  # $4: cert-digest-algo
  # $5: digest-algo
  check_tool "gpg2" "$(which gpg2)"
  gpg2 \
    --cert-digest-algo "$4" \
    --digest-algo "$5" \
    --no-tty \
    --yes \
    --default-key "$3" \
    --sign \
    --armor \
    --clearsign \
    -o "$2" \
    "$1" || error "failed signing file!"
}

compress_archive() {
  # $1: directory to archive
  # $2: target tar file without name extension
  # $3: compression, either "none" or "xz"
  check_tool "tar" "$(which tar)"
  case "$3" in
    none)
      TARGETFILE="$2.apa.tar"
      ;;
    xz)
      check_tool "pxz" "$(which pxz)"
      TARGETFILE="$2.apa.txz"
      ;;
    *)
      error "invalid type of compression: \"$3\""
      ;;
  esac

  OLDDIR="$(pwd)"
  cd "$1"
  echo -en "writing archive ${TXT_BLUE}${TARGETFILE}${OFF}..."
  if [ "$3" == "xz" ] ; then
    tar cpO * | pxz --stdout - > "${TARGETFILE}" || error "failed compressing archive!"
  else
    tar cpOf "$TARGETFILE" * || error "failed writing archive!"
  fi
  cd "${OLDDIR}"
  alldone
}

timestamp() {
  # $1: ${FILE}
  # $2: ${DATE}
  # $3: ${TSASRVFILE}
  # $4: ${TSASERVER}
  check_tool "openssl" "$(which openssl)"
  check_tool "curl" "$(which curl)"
  TSRFILE="$1_$2_$3.tsr"
  echo -en "generating timestamp: ${TXT_BLUE}${TSRFILE}${OFF} ..."
  openssl ts -query -data "$1" -no_nonce -sha512 -cert | curl --silent --show-error --header "Content-Type: application/timestamp-query" --data-binary @- "$4" > "${TSRFILE}" || exit 1
  alldone
}

timestamp_verify() {
  # $1: ${FILE}
  # $2: ${TSRFILE}
  check_tool "openssl" "$(which openssl)"
  check_tool "curl" "$(which curl)"
  check_tool "grep" "$(which grep)"
  openssl ts -reply -in "$2" -text | grep "Time stamp:"
  openssl ts -verify -data "$1" -in "$2" -CApath "$(openssl version -d | cut -d '"' -f 2)/certs/"
}

timestamp_show() {
  # $1: ${TSRFILE}
  check_tool "openssl" "$(which openssl)"
  openssl ts -reply -in "$1" -text
}

verify_signature() {
  # $1: clearsigned file
  check_tool "gpg2" "$(which gpg2)"
  echo -e "\n${TXT_ORANGE_ON_GREY}OpenPGP signature:${OFF}"
  gpg2 --verify "$1" || error "verification failed!"
  verified "OpenPGP signature"
}

verify_hashes() {
  # $1: tar archive
  # $2: file with hashes
  check_tool "tar" "$(which tar)"
  check_tool "sha256sum" "$(which sha256sum)"
  check_tool "sha512sum" "$(which sha512sum)"
  echo -e "\n${TXT_ORANGE_ON_GREY}checksums:${OFF}"
  tar -xOf "$1" "data.tar" | tar -xf -
  sha256sum -c "$2" --status || sha256sum -c "$2" --quiet || error "verification failed!"
  verified "checksums (SHA256)"
  sha512sum -c "$2" --status || sha512sum -c "$2" --quiet || error "verification failed!"
  verified "checksums (SHA512)"
}

verify_timestamps() {
  # $1: tar archive
  # $2: stamped file
  # $3: array with timestamp files
  check_tool "tar" "$(which tar)"
  echo -e "\n${TXT_ORANGE_ON_GREY}timestamps:${OFF}"
  for i in $3 ; do
    echo -e "checking ${TXT_BLUE}${i}${OFF}..."
    tar -xf "$1" "${i}" || error "couldn't extract timestamp file!"
    timestamp_verify "$2" "${i}"
  done
}
