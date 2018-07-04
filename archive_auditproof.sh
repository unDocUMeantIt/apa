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

ARCHIVEVERSION=1

HAVEFILEDIR=false
TIMESTAMP=false
RMTMPDIR=true
MANUALTEMPDIR=false

DATECHECKSUMS="$(date --rfc-3339 seconds)"
DATEARCHIVE="$(date +%Y-%m-%d_%H-%M-%S)"

OLDWD="$(pwd)"

# poor man's configuration
USERNAME=$(whoami)
USERHOME="${HOME}"
CONFIGDIR="${USERHOME}/.config/bash_scripts_${USERNAME}"
CONFIGFILE="${CONFIGDIR}/archive_auditproof.conf"
if ! [ -f "${CONFIGFILE}" ] ; then
mkmissingdir "${CONFIGDIR}"
touch "${CONFIGFILE}"
fi

appendconfig "${CONFIGFILE}" "^ARCHIVEDIR=" "ARCHIVEDIR=\"/tmp\"" "config"
appendconfig "${CONFIGFILE}" "^PGPKEYID=" "PGPKEYID=\"0000000000000000\"" "config"
appendconfig "${CONFIGFILE}" "^PGPCERTDIGESTALGO" "PGPCERTDIGESTALGO=\"SHA256\"" "config"
appendconfig "${CONFIGFILE}" "^PGPDIGESTALGO" "PGPDIGESTALGO=\"SHA256\"" "config"
appendconfig "${CONFIGFILE}" "^TSASERVERS" "TSASERVERS=\"02\"" "config"
appendconfig "${CONFIGFILE}" "^ARCHIVEDESC" "ARCHIVEDESC=\"some archive\"" "config"
appendconfig "${CONFIGFILE}" "^ARCHIVEPREFIX" "ARCHIVEPREFIX=\"files\"" "config"
appendconfig "${CONFIGFILE}" "^COMPRESSION" "COMPRESSION=\"none\"" "config"

. "${CONFIGFILE}"

if [[ $1 == "" ]] ; then
  echo -e "
Creates a compressed archive of all files in a given directory with checksums,
OpenPGP signature, and optionally an enclosed TSA timestamp
 
Usage:
  ${TXT_BOLD}archive_auditproof.sh${OFF} ${TXT_DGRAY}${TXT_ITALIC}[OPTIONS]${OFF}

  ${TXT_UNDERSCORE}OPTIONS${OFF}:
    ${TXT_BOLD}-i${OFF} ${TXT_RED}${TXT_ITALIC}<path>${OFF}   directory to archive
    ${TXT_BOLD}-d${OFF} ${TXT_RED}${TXT_ITALIC}<text>${OFF}   a short description of the archive
                default: ${TXT_BLUE}${ARCHIVEDESC}${OFF}
    ${TXT_BOLD}-f${OFF} ${TXT_RED}${TXT_ITALIC}<text>${OFF}   filename prefix for resulting archive
                default: ${TXT_BLUE}${ARCHIVEPREFIX}${OFF}

    ${TXT_BOLD}-o${OFF} ${TXT_RED}${TXT_ITALIC}<path>${OFF}   target directory for the archive
                default: ${TXT_BLUE}${ARCHIVEDIR}${OFF}

    ${TXT_BOLD}-c${OFF} ${TXT_RED}${TXT_ITALIC}<type>${OFF}   type of compression for the archive (\"none\" or \"xz\")
                also determines the file extension (*.apa.tar or *.apa.txz)
                default: ${TXT_BLUE}${COMPRESSION}${OFF}

    ${TXT_BOLD}-t${OFF}          timestamp hashed and signed archive
    ${TXT_BOLD}-s${OFF} ${TXT_RED}${TXT_ITALIC}<TSA>${OFF}    TSA servers for timestamps
                default: ${TXT_BLUE}${TSASERVERS}${OFF}

    ${TXT_BOLD}-k${OFF} ${TXT_RED}${TXT_ITALIC}<key ID>${OFF} OpenPGP key ID for signature
                default: ${TXT_BLUE}${PGPKEYID}${OFF}

    ${TXT_BOLD}-T${OFF} ${TXT_RED}${TXT_ITALIC}<path>${OFF}   set the temporary directory manually
                default: ${TXT_BLUE}\$(mktemp -d)${OFF}

  ${TXT_DGRAY}you can change/set the defaults by editing the config file for this script:${OFF}
  ${TXT_BLUE}${CONFIGFILE}${OFF}
"

  exit 0
fi

# get the options
while getopts ":i:d:f:o:c:ts:T:k:" OPT; do
  case $OPT in
    i) HAVEFILEDIR=true >&2
       FILEDIR=$OPTARG >&2
       ;;
    d) ARCHIVEDESC=$OPTARG >&2
       ;;
    f) ARCHIVEPREFIX=$OPTARG >&2
       ;;
    o) ARCHIVEDIR=$OPTARG >&2
       ;;
    c) COMPRESSION=$OPTARG >&2
       ;;
    t) TIMESTAMP=true >&2
       ;;
    s) TSASERVERS=$OPTARG >&2
       ;;
    T) MANUALTEMPDIR=true >&2
       RMTMPDIR=false >&2
       REVTMPDIR=$OPTARG >&2
       ;;
    k) PGPKEYID=$OPTARG >&2
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

if ! ${HAVEFILEDIR} ; then
  error "you *must* set '-i'!"
fi

if ! ${MANUALTEMPDIR} ; then
  REVTMPDIR="$(mktemp -d)"
fi
TMPARCHIVE="${REVTMPDIR}/archive"
TEMPSHA256="$(tempfile --directory "${REVTMPDIR}" --prefix "checksums_SHA256")"
TEMPSHA512="$(tempfile --directory "${REVTMPDIR}" --prefix "checksums_SHA512")"
TEMPCHECKSUMS="$(tempfile --directory "${REVTMPDIR}" --prefix "checksums")"
CHECKSUMSFILE="${TMPARCHIVE}/checksums"
TARCHIVE="${TMPARCHIVE}/data.tar"

mkmissingdir "${ARCHIVEDIR}"
mkmissingdir "${TMPARCHIVE}"

# pack the files and do the checksums
checksums "${FILEDIR}" "${TARCHIVE}" "${TEMPSHA256}" "${TEMPSHA512}"

echo -e "Date: ${DATECHECKSUMS}\nDescription: ${ARCHIVEDESC}\nVersion: ${ARCHIVEVERSION}\nSHA256:" > "${TEMPCHECKSUMS}"
cat "${TEMPSHA256}" | while read line; do echo " $line" >> "${TEMPCHECKSUMS}" ; done
echo "SHA512:" >> "${TEMPCHECKSUMS}"
cat "${TEMPSHA512}" | while read line; do echo " $line" >> "${TEMPCHECKSUMS}" ; done

# add OpenPGP signature to checksum file
OpenPGP_sign_file "${TEMPCHECKSUMS}" "${CHECKSUMSFILE}" "${PGPKEYID}" "${PGPCERTDIGESTALGO}" "${PGPDIGESTALGO}"

if ${TIMESTAMP} ; then
  # now that we have the archive with checksums, timestamp the latter
  check_tool "archive_timestamp.sh" "$(which archive_timestamp.sh)"
  archive_timestamp.sh -f "${CHECKSUMSFILE}" "-${TSASERVERS}"
fi

# pack it all in the final archive
compress_archive "${TMPARCHIVE}" "${ARCHIVEDIR}/${ARCHIVEPREFIX}_${DATEARCHIVE}" "${COMPRESSION}"

if ${RMTMPDIR} ; then
  if [ -d "${TMPARCHIVE}" ] ; then
    echo -en "removing temporary directory ${TXT_BLUE}${REVTMPDIR}${OFF}..."
    rm -rf "${REVTMPDIR}" || error "failed!"
    alldone
  fi
fi

# back to the directory where we started
cd "${OLDWD}"

exit 0
