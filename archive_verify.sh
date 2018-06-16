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

SCRIPTDIR=$(dirname ${BASH_SOURCE[0]})
SCRIPFUNCIONS="${SCRIPTDIR}/_archive_functions.sh"
. "${SCRIPFUNCIONS}"

HAVEFILE=false
TIMESTAMP=false
RMTMPDIR=true
MANUALTEMPDIR=false

VERIFYHASHES=false
VERIFYPGP=false
VERIFYTIMESTAMP=false
ARCHIVEHASCHECKSUM=false
ARCHIVEHASDATA=false
ARCHIVEHASTIMESTAMP=false

DATE="$(date +%Y-%m-%d_%H-%M-%S)"

OLDWD="$(pwd)"

if [[ $1 == "" ]] ; then
  echo -e "
Usage:
  ${TXT_BOLD}archive_verify.sh${OFF} ${TXT_DGRAY}${TXT_ITALIC}[OPTIONS]${OFF}

  ${TXT_UNDERSCORE}OPTIONS${OFF}:
    ${TXT_BOLD}-i${OFF} ${TXT_RED}${TXT_ITALIC}<path>${OFF}   file to verify

    ${TXT_BOLD}-a${OFF}          verify all (shortcut for ${TXT_BOLD}-hpt${OFF})
    ${TXT_BOLD}-h${OFF}          verify checksums
    ${TXT_BOLD}-p${OFF}          verify OpenPGP signature
    ${TXT_BOLD}-t${OFF}          verify timestamp

    ${TXT_BOLD}-T${OFF} ${TXT_RED}${TXT_ITALIC}<path>${OFF}   set the temporary directory manually
                default: ${TXT_BLUE}\$(mktemp -d)${OFF}

  ${TXT_DGRAY}you can change/set the defaults by editing the config file for this script:${OFF}
  ${TXT_BLUE}${CONFIGFILE}${OFF}
"

  exit 0
fi

# get the options
while getopts ":i:ahptT:" OPT; do
  case $OPT in
    i) HAVEFILE=true >&2
       ARCHIVE=$OPTARG >&2
       ;;
    a) VERIFYHASHES=true >&2
       VERIFYPGP=true >&2
       VERIFYTIMESTAMP=true >&2
       ;;
    h) VERIFYHASHES=true >&2
       ;;
    p) VERIFYPGP=true >&2
       ;;
    t) VERIFYTIMESTAMP=true >&2
       ;;
    T) MANUALTEMPDIR=true >&2
       RMTMPDIR=false >&2
       REVTMPDIR=$OPTARG >&2
       ;;
    \?)
       echo -e "${TXT_RED}Invalid option:${OFF} ${TXT_BOLD}-$OPTARG${OFF}" >&2
       exit 1
       ;;
    :)
       echo -e "${TXT_RED}Option${OFF} ${TXT_BOLD}-$OPTARG${OFF} ${TXT_RED}requires an argument.${OFF}" >&2
       exit 1
       ;;
  esac
done


if ! ${HAVEFILE} ; then
  error "you *must* set '-i'!"
fi
if ! [ -f "${ARCHIVE}" ] ; then
  error "file does not exist: ${TXT_BLUE}${ARCHIVE}${OFF}"
fi

# check contents of archive
echo -en "checking archive content:"
declare -a FILECONTENT=($(tar -tf "${ARCHIVE}"))
for i in "data.tar" "checksums" ; do
  if [[ " ${FILECONTENT[@]} " =~ " ${i} " ]] ; then
    echo -en " ${TXT_BLUE}${i}${OFF}"
  else
    echo -e " ${TXT_LRED}${i}${OFF}"
    error "archive doesn't contain ${i}!"
  fi
done
# only check for timestamps if they ought to be verified
if $VERIFYTIMESTAMP ; then
  declare -a ALLTIMESTAMPS
  for i in ${FILECONTENT[@]} ; do
    if $(echo "${i}" | grep -q ".tsr$") ; then
      ALLTIMESTAMPS+="${i}"
    fi
  done
  if [ ${#ALLTIMESTAMPS[@]} -gt 0 ] ; then
    echo -en " ${TXT_BLUE}timestamps${OFF}"
  else
    echo -e " ${TXT_LRED}timestamps${OFF}"
    error "archive doesn't contain timestamps!"
  fi
fi
unset FILECONTENT
alldone

if ! ${MANUALTEMPDIR} ; then
  REVTMPDIR="$(mktemp -d)"
fi
TMPARCHIVE="${REVTMPDIR}/archive"
CHECKSUMSFILE="${TMPARCHIVE}/checksums"
TARCHIVE="${TMPARCHIVE}/data.tar"

# unpack archive
mkmissingdir "${TMPARCHIVE}"
cd "${TMPARCHIVE}"
tar -xf "${ARCHIVE}" "checksums"

# verify OpenPGP signature
if $VERIFYPGP ; then
  verify_signature "checksums"
fi

if $VERIFYHASHES ; then
  verify_hashes "${ARCHIVE}" "checksums"
fi

if $VERIFYTIMESTAMP ; then
  verify_timestamps "${ARCHIVE}" "checksums" ${ALLTIMESTAMPS}
fi

if ${RMTMPDIR} ; then
  if [ -d "${TMPARCHIVE}" ] ; then
    echo -en "\nremoving temporary directory ${TXT_BLUE}${REVTMPDIR}${OFF}..."
    rm -rf "${REVTMPDIR}" || error "failed!"
    alldone
  fi
fi

# back to the directory where we started
cd "${OLDWD}"

exit 0

