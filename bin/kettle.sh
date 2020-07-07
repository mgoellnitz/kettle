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


if [ "$#" == "0" ]; then
  echo "W-LAN Kettle Command Line Tool - 'kettle.sh'"
  echo ""
  echo "$0 [-k kettle] [-t temperature] [-w] [-s]"
  echo ""
  echo "  -k ip-address or hostname of the kettle device"
  echo ""
  echo "  -t target temperature in degree C (65, 80, 95, or 100)"
  echo ""
  echo "  -w set keep warm flag"
  echo ""
  echo "  -s switch kettle on or off"
  echo ""
  exit 1
fi

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-k" ] ; then
    shift
    KETTLE="$1"
  fi
  if [ "$1" = "-t" ] ; then
    shift
    TEMPERATURE="$1"
  fi
  if [ "$1" = "-s" ] ; then
    shift
    SWITCH="1"
  fi
  if [ "$1" = "-w" ] ; then
    shift
    WARM="1"
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done


if [ -f $LOG ] ; then
  echo "$(date) - $0 START" >> $LOG
fi
for INTERVAL in 0 1 2 4 8 16 32 ; do
  if [ -f $LOCK ] ; then
    echo  "$(date) - $0: Sleeping $INTERVAL seconds." >> $LOG
    sleep $INTERVAL
  fi
done
if [ -f $LOCK ] ; then
  RESULT="ERROR"
else
  touch $LOCK
  RESULT="Error"
  if [ -z "$SWITCH" ] ; then
    RESULT=$(echo "ee11010d"|xxd -r -p|nc wasserkocher 2000|hexdump -n 1 -s 2 -e '2/1 "%d\n"')
    RESULT+="°C"
  else
    echo "ee01010d"|xxd -r -p|nc $KETTLE $PORT
    RESULT="Switching"
  fi
  if [ ! -z "$TEMPERATURE" ] ; then
    # Setting the temperature can only be done after switching on
    sleep 1
    echo "TEMP"
    if [ "$TEMPERATURE" = "100" ] ; then
      echo "ee01200d"|xxd -r -p|nc $KETTLE $PORT
      RESULT="100°C"
    fi
    if [ "$TEMPERATURE" = "95" ] ; then
      echo "ee01100d"|xxd -r -p|nc $KETTLE $PORT
      RESULT="95°C"
    fi
    if [ "$TEMPERATURE" = "80" ] ; then
      echo "ee01080d"|xxd -r -p|nc $KETTLE $PORT
      sleep 1
      echo "ee02080d"|xxd -r -p|nc $KETTLE $PORT
      sleep 1
      echo "ee11080d"|xxd -r -p|nc $KETTLE $PORT
      RESULT="80°C"
    fi
    if [ "$TEMPERATURE" = "65" ] ; then
      echo "ee01040d"|xxd -r -p|nc $KETTLE $PORT
      sleep 1
      echo "ee02040d"|xxd -r -p|nc $KETTLE $PORT
      sleep 1
      echo "ee11040d"|xxd -r -p|nc $KETTLE $PORT
      RESULT="65°C"
    fi
  fi
  if [ ! -z "$WARM" ] ; then
    # Keeping the temperature is a flag which must be set when the kettle switched on
    sleep 1
    echo "ee01020d"|xxd -r -p|nc $KETTLE $PORT
    RESULT+=" and keeping warm."
  fi
  rm -f $LOCK
fi
if [ -f $LOG ] ; then
  echo "$(date) - $0: $RESULT" >> $LOG
fi
echo $RESULT
