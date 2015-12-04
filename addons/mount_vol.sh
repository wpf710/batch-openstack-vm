#!/bin/bash -ex

MARIA_DB_PATH="/data/mariadb"
VOL="/dev/vdb"

if [[ ! -d "$MARIA_DB_PATH" ]]; then
  echo "Creating $MARIA_DB_PATH"
  mkdir -p $MARIA_DB_PATH
fi

vol_attach=false

echo "Checking $VOL..."
for (( i=0; i<120; i++ )); do
  fdisk -l | grep "$VOL"
  if [[ $? -ne 0 ]]; then
    echo "$VOL does not exist"
    sleep 5
  else
    vol_attach=true
    break
  fi
done

if [[ $vol_attach != true ]]; then
  exit 1
fi

echo "Formating $VOL..."
mkfs -t ext4 $VOL
echo "Mounting $VOL..."
mount -t ext4 $VOL $MARIA_DB_PATH
