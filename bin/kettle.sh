#!/bin/bash
# 
# Copyright 2020 Martin Goellnitz
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
KETTLE=192.168.0.1
PORT=2000
EXITVALUE=0
TEMPERATURE=
SWITCH=
WARM=
if [ -d /var/lib/openhab2 ] ; then
  LOG="/var/log/openhab2/kettle.log"
  LOCK="/var/lib/openhab2/tmp/kettle.lock"
  STATUS="/var/lib/openhab2/tmp/kettle.status"
else
  LOG="/tmp/kettle.log"
  LOCK="/tmp/kettle.lock"
  STATUS="/tmp/kettle.status"
fi

function usage {
   echo "Usage: $MYNAME [-f] [-k kettle] [-t temperature] [-s] [-w]" 1>&2
   echo "" 1>&2
   echo "  -f              fetch temperature" 1>&2
   echo "  -h              this message" 1>&2
   echo "  -k kettle       set name or ip for kettle to use" 1>&2
   echo "  -s              switch kettel on" 1>&2
   echo "  -t temperature  set temperature" 1>&2
   echo "  -w              keep warm" 1>&2
   echo "" 1>&2
   echo "The default without parameters is to output the results of the previous command without any further action." 1>&2
   echo "" 1>&2
   exit 1
}

while getopts "fhk:st:w" opt ; do
  case "${opt}" in
    f)
      FETCH="fetch"
      ;;
    h)
      usage
      ;;
    k)
      KETTLE=$OPTARG
      ;;
    s)
      SWITCH="switch"
      ;;
    t)
      TEMPERATURE=$OPTARG
      ;;
    w)
      WARM="warm"
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))


if [ -f $LOG ] ; then
  echo "$(date) - $0 START" >> $LOG
fi
for INTERVAL in 0 1 2 4 8 16 ; do
  if [ -f $LOCK ] ; then
    echo  "$(date) - $0: Sleeping $INTERVAL seconds." >> $LOG
    sleep $INTERVAL
  fi
done
if [ -f $LOCK ] ; then
  RESULT="ERROR"
  EXITVALUE=1
else
  EXITVALUE=0
  touch $LOCK
  RESULT="Error"
  if [ -z "$SWITCH" ] ; then
    if [ -z "$FETCH" ] ; then
      EXITVALUE=$(cat "$STATUS")
    else
      EXITVALUE=$(echo "ee11010d"|xxd -r -p|nc $KETTLE $PORT|hexdump -n 1 -s 2 -e '2/1 "%d\n"')
    fi
    RESULT="$EXITVALUE°C"
  else
    echo "ee01010d"|xxd -r -p|nc -w 2 $KETTLE $PORT
    RESULT="Switching"
  fi
  if [ ! -z "$TEMPERATURE" ] ; then
    # Setting the temperature can only be done after switching on
    sleep 1
    echo "TEMP"
    if [ "$TEMPERATURE" = "100" ] ; then
      echo "ee01200d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      RESULT="100°C"
    fi
    if [ "$TEMPERATURE" = "95" ] ; then
      echo "ee01100d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      RESULT="95°C"
    fi
    if [ "$TEMPERATURE" = "80" ] ; then
      echo "ee01080d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      sleep 1
      echo "ee02080d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      sleep 1
      echo "ee11080d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      RESULT="80°C"
    fi
    if [ "$TEMPERATURE" = "65" ] ; then
      echo "ee01040d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      sleep 1
      echo "ee02040d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      sleep 1
      echo "ee11040d"|xxd -r -p|nc -w 1 $KETTLE $PORT
      RESULT="65°C"
    fi
  fi
  if [ ! -z "$WARM" ] ; then
    # Keeping the temperature is a flag which must be set when the kettle switched on
    sleep 1
    echo "ee01020d"|xxd -r -p|nc -w 1 $KETTLE $PORT
    RESULT+=" and keeping warm."
  fi
  rm -f $LOCK
fi
if [ -f $LOG ] ; then
  echo "$(date) - $0: $RESULT" >> $LOG
fi
echo $RESULT
echo $EXITVALUE > $STATUS
exit $EXITVALUE
