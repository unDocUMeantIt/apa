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

DOSTAMP=false
VERIFY=false
SHOW=false
USETSASERVER0=false
USETSASERVER1=false
USETSASERVER2=false
USETSASERVER3=false
USETSASERVER4=false
USETSASERVER5=false
USETSASERVER6=false
USETSASERVER7=false
USETSASERVER8=false
USETSASERVER9=false
USETSASERVERMANUAL=false
USETSASERVERDEFAULT=true
TSRFILE=""
DATE="$(date +%Y-%m-%d_%H-%M-%S)"

# poor man's configuration
USERNAME=$(whoami)
USERHOME="${HOME}"
CONFIGDIR="${USERHOME}/.config/bash_scripts_${USERNAME}"
CONFIGFILE="${CONFIGDIR}/archive_timestamp.conf"
if ! [ -f "${CONFIGFILE}" ] ; then
mkmissingdir "${CONFIGDIR}"
touch "${CONFIGFILE}"
fi
appendconfig "${CONFIGFILE}" "^TSASERVER0=" "TSASERVER0=\"http://time.certum.pl\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVFILE0=" "TSASRVFILE0=\"certum\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT0=" "TSASRVCOMMENT0=\"(default)\"" "config"
appendconfig "${CONFIGFILE}" "^TSASERVER1=" "TSASERVER1=\"https://tsa.safecreative.org\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVFILE1=" "TSASRVFILE1=\"safecreative\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT1=" "TSASRVCOMMENT1=\"(5 per day/IP free)\"" "config"
appendconfig "${CONFIGFILE}" "^TSASERVER2=" "TSASERVER2=\"https://freetsa.org/tsr\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVFILE2=" "TSASRVFILE2=\"freetsa\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT2=" "TSASRVCOMMENT2=\"\"" "config"
appendconfig "${CONFIGFILE}" "^TSASERVER3=" "TSASERVER3=\"http://sha256timestamp.ws.symantec.com/sha256/timestamp\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVFILE3=" "TSASRVFILE3=\"symantec\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT3=" "TSASRVCOMMENT3=\"\"" "config"
appendconfig "${CONFIGFILE}" "^TSASERVER4=" "TSASERVER4=\"http://timestamp.globalsign.com/scripts/timstamp.dll\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVFILE4=" "TSASRVFILE4=\"globalsign\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT4=" "TSASRVCOMMENT4=\"\"" "config"
appendconfig "${CONFIGFILE}" "^TSASERVER5=" "TSASERVER5=\"https://ca.signfiles.com/tsa/get.aspx\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVFILE5=" "TSASRVFILE5=\"trendmicro\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT5=" "TSASRVCOMMENT5=\"\"" "config"
appendconfig "${CONFIGFILE}" "^TSASERVER6=" "TSASERVER6=\"http://timestamp.comodoca.com/rfc3161\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVFILE6=" "TSASRVFILE6=\"comodo\"" "config"
appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT6=" "TSASRVCOMMENT6=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASERVER7=" "TSASERVER7=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASRVFILE7=" "TSASRVFILE7=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT7=" "TSASRVCOMMENT7=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASERVER8=" "TSASERVER8=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASRVFILE8=" "TSASRVFILE8=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT8=" "TSASRVCOMMENT8=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASERVER9=" "TSASERVER9=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASRVFILE9=" "TSASRVFILE9=\"\"" "config"
# appendconfig "${CONFIGFILE}" "^TSASRVCOMMENT9=" "TSASRVCOMMENT9=\"\"" "config"
. "${CONFIGFILE}"

TSASERVER="${TSASERVER0}"
TSASRVFILE="${TSASRVFILE0}"

if [[ $1 == "" ]] ; then
  echo -e "
Usage:
  ${TXT_BOLD}archive_timestamp.sh${OFF} ${TXT_DGRAY}${TXT_ITALIC}[OPTIONS]${OFF}

  ${TXT_UNDERSCORE}OPTIONS${OFF}:
    ${TXT_BOLD}-f${OFF} ${TXT_LRED}${TXT_ITALIC}<file>${OFF}      path to actual file

    if only -f is given, the file will be timestamped to ${TXT_BLUE}<file>_\$DATE_\$SERVER.tsr${OFF}

    ${TXT_BOLD}-t${OFF} ${TXT_LRED}${TXT_ITALIC}<tsr_file>${OFF}  path to tsr file for -v and -s
    ${TXT_BOLD}-v${OFF}             verify ${TXT_BLUE}<file>${OFF} by ${TXT_BLUE}<tsr_file>${OFF}
    ${TXT_BOLD}-s${OFF}             show ${TXT_BLUE}<tsr_file>${OFF} data

    available TSA servers:
    ${TXT_BOLD}-0${OFF}             ${TSASRVFILE0}: ${TXT_BLUE}${TSASERVER0}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT0}${OFF}
    ${TXT_BOLD}-1${OFF}             ${TSASRVFILE1}: ${TXT_BLUE}${TSASERVER1}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT1}${OFF}
    ${TXT_BOLD}-2${OFF}             ${TSASRVFILE2}: ${TXT_BLUE}${TSASERVER2}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT2}${OFF}
    ${TXT_BOLD}-3${OFF}             ${TSASRVFILE3}: ${TXT_BLUE}${TSASERVER3}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT3}${OFF}
    ${TXT_BOLD}-4${OFF}             ${TSASRVFILE4}: ${TXT_BLUE}${TSASERVER4}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT4}${OFF}
    ${TXT_BOLD}-5${OFF}             ${TSASRVFILE5}: ${TXT_BLUE}${TSASERVER5}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT5}${OFF}
    ${TXT_BOLD}-6${OFF}             ${TSASRVFILE6}: ${TXT_BLUE}${TSASERVER6}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT6}${OFF}
    ${TXT_BOLD}-T${OFF}             manual override

"
#     ${TXT_BOLD}-7${OFF}             ${TSASRVFILE7}: ${TXT_BLUE}${TSASERVER7}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT7}${OFF}
#     ${TXT_BOLD}-8${OFF}             ${TSASRVFILE8}: ${TXT_BLUE}${TSASERVER8}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT8}${OFF}
#     ${TXT_BOLD}-9${OFF}             ${TSASRVFILE9}: ${TXT_BLUE}${TSASERVER9}${OFF} ${TXT_DGRAY}${TSASRVCOMMENT9}${OFF}
  exit 0
fi

# get the options
while getopts ":f:t:T:vs0123456" OPT; do
  case $OPT in
    f) DOSTAMP=true >&2
       FILE=$OPTARG >&2
       ;;
    t) TSRFILE=$OPTARG >&2
       ;;
    T) TSASERVER=$OPTARG >&2
       TSASRVFILE="manual" >&2
       USETSASERVERMANUAL=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
    0) USETSASERVER0=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
    1) USETSASERVER1=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
    2) USETSASERVER2=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
    3) USETSASERVER3=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
    4) USETSASERVER4=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
    5) USETSASERVER5=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
    6) USETSASERVER6=true >&2
       USETSASERVERDEFAULT=false >&2
       ;;
#     7) USETSASERVER7=true >&2
#        USETSASERVERDEFAULT=false >&2
#        ;;
#     8) USETSASERVER8=true >&2
#        USETSASERVERDEFAULT=false >&2
#        ;;
#     9) USETSASERVER9=true >&2
#        USETSASERVERDEFAULT=false >&2
#        ;;
    v) DOSTAMP=false >&2
       VERIFY=true >&2
       ;;
    s) DOSTAMP=false >&2
       SHOW=true >&2
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

if ${VERIFY} || ${SHOW} ; then
  if [ "${TSRFILE}" == "" ] ; then
    error "<tsr_file> is missing!"
  elif [ ! -f "${TSRFILE}" ] ; then
    error "file not found: ${TXT_BLUE}${TSRFILE}${OFF}"
  fi
fi

if ${DOSTAMP} ; then
  if [ ! -f "${FILE}" ] ; then
    error "file not found: ${TXT_BLUE}${FILE}${OFF}"
  else
    if ${USETSASERVERDEFAULT} || ${USETSASERVERMANUAL} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE}" "${TSASERVER}"
    fi
    if ${USETSASERVER0} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE0}" "${TSASERVER0}"
    fi
    if ${USETSASERVER1} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE1}" "${TSASERVER1}"
    fi
    if ${USETSASERVER2} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE2}" "${TSASERVER2}"
    fi
    if ${USETSASERVER3} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE3}" "${TSASERVER3}"
    fi
    if ${USETSASERVER4} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE4}" "${TSASERVER4}"
    fi
    if ${USETSASERVER5} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE5}" "${TSASERVER5}"
    fi
    if ${USETSASERVER6} ; then
      timestamp "${FILE}" "${DATE}" "${TSASRVFILE6}" "${TSASERVER6}"
    fi
#     if ${USETSASERVER7} ; then
#       timestamp "${FILE}" "${DATE}" "${TSASRVFILE7}" "${TSASERVER7}"
#     fi
#     if ${USETSASERVER8} ; then
#       timestamp "${FILE}" "${DATE}" "${TSASRVFILE8}" "${TSASERVER8}"
#     fi
#     if ${USETSASERVER9} ; then
#       timestamp "${FILE}" "${DATE}" "${TSASRVFILE9}" "${TSASERVER9}"
#     fi
  fi
elif ${VERIFY} ; then
  timestamp_verify "${FILE}" "${TSRFILE}"
elif ${SHOW} ; then
  timestamp_show "${TSRFILE}"
else
  error "nothing to do!"
fi

exit 0
