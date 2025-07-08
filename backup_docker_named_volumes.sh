#!/bin/bash

VOLUMES_INFO_DIR=./volumes_info
VOLUMES_DIR=./volumes
volumes=$(docker volume ls --quiet)
running_containers=$(docker ps --format "{{.Names}}")

echo "Backup date: $(date)" > backup_details.txt
echo "Host: $(hostname)" >> backup_details.txt
echo "Running containers: $(docker ps --quiet | wc -l)" >> backup_details.txt
echo "Volume count: $(docker volume ls --quiet | wc -l)" >> backup_details.txt

mkdir -p ${VOLUMES_INFO_DIR} ${VOLUMES_DIR}

echo ${running_containers} | sed 's/ /\n/g' > running_containers.txt

docker stop ${running_containers}

for volume in ${volumes};do
    docker volume inspect ${volume} > ${VOLUMES_INFO_DIR}/${volume}.json
    docker run --rm --name backup-volume_${volume} \
	    -v ${volume}:/dir2bkp \
	    -v ${VOLUMES_DIR}:/bkpdst \
            docker.io/ubuntu:noble \
	    tar -cvzf /bkpdst/${volume}.tar.gz -C /dir2bkp .
done

tar -cvf named_volumes_bkp.tar ${VOLUMES_INFO_DIR} ${VOLUMES_DIR} running_containers.txt backup_details.txt && \
rm -rf ${VOLUMES_INFO_DIR} ${VOLUMES_DIR} running_containers.txt backup_details.txt

docker start ${running_containers}
