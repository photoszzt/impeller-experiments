#!/bin/bash
set -x
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

BASE_DIR=$(realpath $(dirname $0))
WORKSPACE_DIR=$(realpath $SCRIPT_DIR/../../)
HELPER_SCRIPT=$(realpath $SCRIPT_DIR/../scripts/exp_helper)
ALL_HOSTS=$($HELPER_SCRIPT get-all-server-hosts --base-dir=$BASE_DIR)
MANAGER_HOST=$($HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR)
DOCKER_VER=$(ssh -q $MANAGER_HOST -oStrictHostKeyChecking=no -- 'docker version -f "{{.Server.Version}}"')
DOCKER_VER_MAJOR=$(echo "$DOCKER_VER" | cut -d'.' -f 1)

i=0
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	$SSH_CMD -- "sudo sysctl vm.overcommit_memory=1"
	$SSH_CMD -- "[ -d /home/ubuntu/impeller-artifact ] || git clone --recurse-submodules -j8 https://github.com/ut-osa/impeller-artifact.git /home/ubuntu/impeller-artifact" &
	pids[$i]=$!
	i=$((i + 1))
	$SSH_CMD -- "sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin jq" &
	pids[$i]=$!
	i=$((i + 1))
done
for pid in ${pids[*]}; do
	wait $pid
done
