#!/bin/bash

set -Exeuo pipefail

VOLUME_ID=$1
MOUNT_PATH=$2
FILE_SYSTEM_TYPE=$3
COMMA_SEPARATED_MOUNT_PARAMS=$4
OWNER=$5
GROUP=$6

# echo list of devices
lsblk --raw --paths --noheadings --nodeps --output NAME | grep "nvme"
blkid

DEVICE_PATH=""
while
  for NVME_DEVICE_PATH in $(lsblk --raw --paths --noheadings --nodeps --output NAME | grep "nvme"); do
    VOLUME_ID_OF_DEVICE=$(/sbin/ebsnvme-id "${NVME_DEVICE_PATH}" | grep 'Volume ID' | awk '{print $3}')
    if [[ "${VOLUME_ID}" == "${VOLUME_ID_OF_DEVICE}" ]]; then
      DEVICE_PATH="${NVME_DEVICE_PATH}"
      break
    fi
  done
  [[ -z ${DEVICE_PATH} ]]
do sleep 1; done

if ! blkid -o value -s TYPE "${DEVICE_PATH}" || [ -z "$(blkid -o value -s TYPE "${DEVICE_PATH}")" ]
then
  echo "Filesystem not found with blkid, confirming with lsblk. "
  if [ -z "$(lsblk -f --paths | grep "${DEVICE_PATH}" | awk '{print $2}')" ]
  then
    echo "Filesystem not found with lsblk as well, formatting the disk... "
    if [ "$FILE_SYSTEM_TYPE" == "xfs" ]
    then
      yum -y install xfsprogs
    fi

    mkfs -t "$FILE_SYSTEM_TYPE" "$DEVICE_PATH"
  else
    echo "Disk seems to be already formatted, skipping the formatting"
  fi
else
  echo "Disk already formatted no need to format."
fi

# echo list of devices
lsblk -f
blkid

mkdir -p "${MOUNT_PATH}"

while
  DEVICE_DETAILS="$(lsblk --raw --paths --noheadings --nodeps -f --output NAME,FSTYPE,UUID | grep "$DEVICE_PATH")"
  echo "Device details : ${DEVICE_DETAILS}"
  FS_TYPE="$(echo -n "${DEVICE_DETAILS}" | awk '{print $2}')"
  DEVICE_UUID="$(echo -n "${DEVICE_DETAILS}" | awk '{print $3}')"
  [[ -z ${DEVICE_UUID} ]]  || [[ -z ${FS_TYPE} ]]
do sleep 1; done

cp /etc/fstab /etc/fstab.orig

if ! grep -qF "${DEVICE_UUID}" /etc/fstab
then
  fstab_entry="UUID=${DEVICE_UUID} ${MOUNT_PATH} $FILE_SYSTEM_TYPE defaults,nofail,$COMMA_SEPARATED_MOUNT_PARAMS 0 2"
  echo "creating fstab entry '$fstab_entry'"
  echo "$fstab_entry" | tee -a /etc/fstab
else
  echo "no need to add fstab entry"
fi

cat /etc/fstab

mount -a

while
  DEVICE_DETAILS="$(lsblk --raw --paths --noheadings --nodeps --output NAME,UUID,MOUNTPOINT | grep "${DEVICE_PATH}")"
  echo "Device details : ${DEVICE_DETAILS}"
  DEVICE_UUID="$(echo -n "${DEVICE_DETAILS}" | awk '{print $2}')"
  DEVICE_MOUNTPOINT="$(echo -n "${DEVICE_DETAILS}" | awk '{print $3}')"
  [[ -z ${DEVICE_UUID} ]]  || [[ -z ${DEVICE_MOUNTPOINT} ]]
do sleep 1; done

# echo list of devices
lsblk -f
blkid

EXISTING_OWNER=$(stat -c "%U" "${MOUNT_PATH}")
EXISTING_GROUP=$(stat -c "%G" "${MOUNT_PATH}")

if [[ "${EXISTING_OWNER}" != "${OWNER}" ]] || [[ "${EXISTING_GROUP}" != "${GROUP}" ]]; then
  echo "changing ownership of ${MOUNT_PATH} to ${OWNER}:${GROUP}"
  chown -R "${OWNER}:${GROUP}" "${MOUNT_PATH}" || /bin/true
else
  echo "no need to change ownership"
fi