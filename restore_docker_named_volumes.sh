#! /bin/bash

BACKUP_FILE=./named_volumes_bkp.tar
VOLUMES_INFO_DIR="./volumes_info"
VOLUMES_DIR="./volumes"

tar -xvf named_volumes_bkp.tar

for file in "$VOLUMES_INFO_DIR"/*.json; do
    echo "Processing: $file"
    
    # Parse the first object in the JSON array
    volume_json=$(jq '.[0]' "$file")
    
    name=$(echo "$volume_json" | jq -r '.Name')
    driver=$(echo "$volume_json" | jq -r '.Driver')

    # Build options and labels (safely handles if empty)
    opts=$(echo "$volume_json" | jq -r '.Options // {} | to_entries[] | "--opt \(.key)=\(.value)"')
    labels=$(echo "$volume_json" | jq -r '.Labels // {} | to_entries[] | "--label \(.key)=\(.value)"')

    # Check if volume already exists
    if docker volume inspect "$name" &>/dev/null; then
        echo "  → Volume '$name' already exists. Skipping."
        continue
    fi

    # Create volume
    echo "  → Creating volume: $name"
    docker volume create --driver "$driver" $opts $labels "$name"

    # Add restore volume data from backup
    docker run --rm --name backup-volume_${volume} \
	    -v ${name}:/dir2rst \
	    -v ${VOLUMES_DIR}:/bkpsrc \
            docker.io/ubuntu:noble \
	    tar -xvzf /bkpsrc/${name}.tar.gz -C /dir2rst
done

