#!/bin/bash

### SET THIS VARIABLE ###
#example: DVRFolder=/volume1/ShareFolders/Media/ChannelsDVR
#DVRFolder=<enter your ChannelsDVR folder>
DVRFolder=/Volumes/ShareFolders/Media/ChannelsDVR

### Don't run more than one at a time ###
if [[ -f /tmp/ChannelsEDL ]]; then
  echo "The /tmp/ChannelsEDL file exists."
  exit
else
  touch /tmp/ChannelsEDL
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
  ### In case it's a remotely mounted source
  VIDEO=$(echo ${VIDEO} | sed "s,${DVRFolder},${VIDEO},")
  FULLPATH=$(dirname "${file}")
  FILENAME=$(basename "${file}")
  EDL="${VIDEO%.*}"
  if [ -f "${VIDEO}" ]; then
    if [ ! -f "${EDL}".edl ]; then
      cp "${FULLPATH}"/video.edl "${EDL}".edl
      if [[ $(uname -a) == *Darwin* ]]; then
        sed -i "" "s,0$,3," "${EDL}".edl
      else
        sed -i "s,0$,3," "${EDL}".edl
      fi
    fi
  fi
done

### Remove the lock file ###
rm /tmp/ChannelsEDL
