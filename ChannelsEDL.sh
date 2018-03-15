#!/bin/bash
IFS=$'\n'
if [[ ${1} == "" ]]; then
    echo "You need to run this as following: "
    echo "bash ChannelsEDL.sh </full/path/to/ChannelsDVR>"
elif [[ ! -d ${1} ]]; then
    echo "Your input was not a directory."
elif [[ ! -d ${1}/Logs/comskip ]]; then
    echo "The comskip log folder was not found. Please check the path you input."
else
    DVRFolder="${1}"
fi

### Don't run more than one at a time ###
if [[ -f /tmp/ChannelsEDL ]]; then
  echo "The /tmp/ChannelsEDL file exists."
  exit
else
  touch /tmp/ChannelsEDL
fi

### Set variables ###
COMSKIP="${DVRFolder}"/Logs/comskip
TVFolder="${DVRFolder}"/TV
MovieFolder="${DVRFolder}"/Movies

### Get the EDL files and put then next to the video ###
for file in $(find "${COMSKIP}" -name video.log 2> /dev/null); do
  VIDEO=$(egrep "Mpeg:" "${file}" | egrep -v "video.mpg")
  VIDEO=${VIDEO:6}
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
