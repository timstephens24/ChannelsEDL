#!/bin/bash

#############################
### SETUP THE ENVIRONMENT ###
#############################
IFS=$'\n' # make newlines the only separator
CHANNELSFOLDER=/opt/ChannelsDVR
FFMPEG_PATH=/opt/channels-dvr/latest/ffmpeg
WORKINGFOLDER=${CHANNELSFOLDER}/.working
BACKUPFOLDER=${CHANNELSFOLDER}/.trash

##### ----- Shouldn't need to change anything below here ----- #####

########################
### MORE ENVIRONMENT ###
########################
IFS=$'\n' # make newlines the only separator
WORKINGFOLDER=${CHANNELSFOLDER}/.working
if [ ! -d "${WORKINGFOLDER}" ]; then
  mkdir "${WORKINGFOLDER}"
fi
BACKUPFOLDER=${CHANNELSFOLDER}/.trash
if [ ! -d "${BACKUPFOLDER}" ]; then
  mkdir "${BACKUPFOLDER}"
fi

#################################
### ADD CHAPTERS TO MPG FILES ###
#################################
for file in $(find "${CHANNELSFOLDER}" -type f | egrep -v "video.mpg|.working|.trash" | egrep -i ".mpg"); do
  FILE=$(basename ${file})
  echo;echo "Working on: ${FILE}"
  FOLDER=$(dirname ${file})
  EDL_FILE="${file%.*}.edl"
  META_FILE="${file%.*}.ffmeta"
  XML_FILE="${file%.*}.xml"
  CCYES_FILE="${file%.*}.ccyes"
  LOG_FILE="${file%.*}.log"
  OUTPUT_FILE="${WORKINGFOLDER}/${FILE%.*}.mkv"
  OUTPUT_EXTENSION="${OUTPUT_FILE##*.}"
  cd "${FOLDER}"
  if [ ! -f "${EDL_FILE}" ]; then
    echo "No EDL to process for: ${FILE}"
    continue
  fi
  start=0
  i=0
  echo ";FFMETADATA1" > "${META_FILE}"
  while IFS=$'\t' read -r -a line; do
    ((i++))
    end=$(awk -vp="${line[0]}" 'BEGIN{printf "%.0f" ,p*1000}')
    startnext=$(awk -vp="${line[1]}" 'BEGIN{printf "%.0f" ,p*1000}')
    hascommercials=true
    echo [CHAPTER] >> "${META_FILE}"
    echo TIMEBASE=1/1000 >> "${META_FILE}"
    echo START="${start}" >> "${META_FILE}"
    echo END="${end}" >> "${META_FILE}"
    echo "title=Chapter $i" >> "${META_FILE}"
    echo [CHAPTER] >> "${META_FILE}"
    echo TIMEBASE=1/1000 >> "${META_FILE}"
    echo START="${end}" >> "${META_FILE}"
    echo END="${startnext}" >> "${META_FILE}"
    echo "title=Commercial $i" >> "${META_FILE}"
    start="${startnext}"
  done < "${EDL_FILE}"
  if ${hascommercials}; then
    ((i++))
    echo [CHAPTER] >> "${META_FILE}"
    echo TIMEBASE=1/1000 >> "${META_FILE}"
    echo START="${start}" >> "${META_FILE}"
    echo END=$(${FFMPEG_PATH} -i "${file}" 2>&1 | grep Duration | awk '{print $2}' | tr -d , | awk -F: '{ print ($1*3600)+($2*60)+$3 }'| awk '{printf "%.0f",$1*1000}') >> "${META_FILE}"
    echo "title=Chapter $i" >> "${META_FILE}"
    echo "Now running ffmpeg on: ${FILE}"
  fi
  "${FFMPEG_PATH}" -loglevel error -hide_banner -nostdin -i "${file}" -i "${META_FILE}" -map_metadata 1 -codec copy -y "${OUTPUT_FILE}"
  echo "Saved to: ${OUTPUT_FILE}"
  rm "${META_FILE}"
  mv "${EDL_FILE}" "${BACKUPFOLDER}"
  mv "${file}" "${BACKUPFOLDER}"
  mv "${OUTPUT_FILE}" "${file}"
done
