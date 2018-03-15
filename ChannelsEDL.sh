#!/bin/bash

### SET THIS VARIABLE ###
#example: DVRFolder=/volume1/ShareFolders/Media/ChannelsDVR
DVRFolder=<enter your ChannelsDVR folder>

### Don't run more than one at a time ###
if [[ -f /tmp/ComSkipEDL ]]; then
  echo "The /tmp/ComSkipEDL file exists."
  exit
else
  touch /tmp/ComSkipEDL
fi

### Set variables ###
IFS=$'\n'
COMSKIP="${DVRFolder}"/Logs/comskip
TVFolder="${DVRFolder}"/TV
MovieFolder="${DVRFolder}"/Movies

### Remove all edl files ###
find "${MovieFolder}" -type f -name *.edl -delete 2> /dev/null
find "${TVFolder}" -type f -name *.edl -delete 2> /dev/null

### Get the EDL files and put then next to the video ###
for file in $(find "${COMSKIP}" -name video.log 2> /dev/null); do
  VIDEO=$(egrep "Mpeg:" "${file}" | egrep -v "video.mpg")
  VIDEO=${VIDEO:6}
  if [[ "${VIDEO}" == *${DVRFolder}* ]]; then
    FULLPATH=$(dirname "${file}")
    FILENAME=$(basename "${file}")
    EDL="${VIDEO%.*}"
    if [ -f "${VIDEO}" ]; then
      if [ ! -f "${EDL}".edl ]; then
        cp "${FULLPATH}"/video.edl "${EDL}".edl
        sed -i "s,0$,3," "${EDL}".edl
      fi
    fi
  fi
done

### Remove the lock file ###
rm /tmp/ComSkipEDL
