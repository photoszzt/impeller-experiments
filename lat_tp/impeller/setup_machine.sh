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
CLIENT_HOST=$($HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR)
MANAGER_HOST=$($HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR)
DOCKER_VER=$(ssh -q $MANAGER_HOST -oStrictHostKeyChecking=no -- 'docker version -f "{{.Server.Version}}"')
DOCKER_VER_MAJOR=$(echo "$DOCKER_VER" | cut -d'.' -f 1)

cat <<EOF > /tmp/chrony.conf 
# Welcome to the chrony configuration file. See chrony.conf(5) for more
# information about usuable directives.

server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4

# This will use (up to):
# - 4 sources from ntp.ubuntu.com which some are ipv6 enabled
# - 2 sources from 2.ubuntu.pool.ntp.org which is ipv6 enabled as well
# - 1 source from [01].ubuntu.pool.ntp.org each (ipv4 only atm)
# This means by default, up to 6 dual-stack and up to 2 additional IPv4-only
# sources will be used.
# At the same time it retains some protection against one of the entries being
# down (compare to just using one of the lines). See (LP: #1754358) for the
# discussion.
#
# About using servers from the NTP Pool Project in general see (LP: #104525).
# Approved by Ubuntu Technical Board on 2011-02-08.
# See http://www.pool.ntp.org/join.html for more information.
pool ntp.ubuntu.com        iburst maxsources 4
pool 0.ubuntu.pool.ntp.org iburst maxsources 1
pool 1.ubuntu.pool.ntp.org iburst maxsources 1
pool 2.ubuntu.pool.ntp.org iburst maxsources 2

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 100.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can’t be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1 3
EOF

pids=()
i=0
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	$SSH_CMD -- "sudo systemctl stop unattended-upgrades" &
	pids[$i]=$!
	i=$((i + 1))
done
for pid in ${pids[*]}; do
	wait $pid
done

pids=()
i=0
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	$SSH_CMD -- "sudo apt-get -y purge unattended-upgrades" &
	pids[$i]=$!
	i=$((i + 1))
done
for pid in ${pids[*]}; do
	wait $pid
done
ssh -q -oStrictHostKeyChecking=no $CLIENT_HOST -- "sudo systemctl stop unattended-upgrades"
ssh -q -oStrictHostKeyChecking=no $CLIENT_HOST -- "sudo apt-get -y purge unattended-upgrades"

pids=()
i=0
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	$SSH_CMD -- "sudo sysctl vm.overcommit_memory=1"
	$SSH_CMD -- "[ -d /home/ubuntu/impeller-artifact ] || git clone --recurse-submodules -j8 https://github.com/ut-osa/impeller-artifact.git /home/ubuntu/impeller-artifact" &
	pids[$i]=$!
	i=$((i + 1))
	$SSH_CMD -- "sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin jq chrony" &
	pids[$i]=$!
	i=$((i + 1))
done
for pid in ${pids[*]}; do
	wait $pid
done
ssh -q -oStrictHostKeyChecking=no $CLIENT_HOST -- "[ -d /home/ubuntu/impeller-artifact ] || git clone --recurse-submodules -j8 https://github.com/ut-osa/impeller-artifact.git /home/ubuntu/impeller-artifact"
ssh -q -oStrictHostKeyChecking=no $CLIENT_HOST -- "sudo apt-get -y install chrony"

for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	scp -oStrictHostKeyChecking=no /tmp/chrony.conf "$HOST:/home/ubuntu/chrony.conf"
        $SSH_CMD -- "sudo mv /home/ubuntu/chrony.conf /etc/chrony/chrony.conf"
	$SSH_CMD -- "sudo /etc/init.d/chrony restart"
done
sleep 20
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	$SSH_CMD -- "sudo systemctl status chrony"
	$SSH_CMD -- "chronyc sources -v"
	$SSH_CMD -- "chronyc tracking"
done

pids=()
i=0
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	$SSH_CMD -- mkdir -p /home/ubuntu/impeller-artifact/nexmark/nexmark-kafka-streams/build/libs
	scp -q -oStrictHostKeyChecking=no /home/ubuntu/impeller-artifact/nexmark/nexmark-kafka-streams/build/libs/nexmark-kafka-streams-0.2-SNAPSHOT-uber.jar $HOST:/home/ubuntu/impeller-artifact/nexmark/nexmark-kafka-streams/build/libs/nexmark-kafka-streams-0.2-SNAPSHOT-uber.jar &
	pids[$i]=$!
	i=$((i + 1))
done
for pid in ${pids[*]}; do
	wait $pid
done
ssh -q -oStrictHostKeyChecking=no $CLIENT_HOST -- "mkdir -p /home/ubuntu/impeller-artifact/nexmark/nexmark-kafka-streams/build/libs"
scp -q -oStrictHostKeyChecking=no /home/ubuntu/impeller-artifact/nexmark/nexmark-kafka-streams/build/libs/nexmark-kafka-streams-0.2-SNAPSHOT-uber.jar $CLIENT_HOST:/home/ubuntu/impeller-artifact/nexmark/nexmark-kafka-streams/build/libs/nexmark-kafka-streams-0.2-SNAPSHOT-uber.jar

pids=()
i=0
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	$SSH_CMD -- mkdir -p /home/ubuntu/impeller-artifact/boki/bin
	scp -r -q -oStrictHostKeyChecking=no /home/ubuntu/impeller-artifact/boki/bin/release $HOST:/home/ubuntu/impeller-artifact/boki/bin &
	pids[$i]=$!
	i=$((i + 1))
done
for pid in ${pids[*]}; do
	wait $pid
done
ssh -q -oStrictHostKeyChecking=no $CLIENT_HOST -- mkdir -p /home/ubuntu/impeller-artifact/boki/bin
scp -r -q -oStrictHostKeyChecking=no /home/ubuntu/impeller-artifact/boki/bin/release $CLIENT_HOST:/home/ubuntu/impeller-artifact/boki/bin

pids=()
i=0
for HOST in $ALL_HOSTS; do
	SSH_CMD="ssh -q $HOST -oStrictHostKeyChecking=no"
	scp -r -q -oStrictHostKeyChecking=no /home/ubuntu/impeller-artifact/impeller/bin $HOST:/home/ubuntu/impeller-artifact/impeller &
	pids[$i]=$!
	i=$((i + 1))
done
for pid in ${pids[*]}; do
	wait $pid
done
scp -r -q -oStrictHostKeyChecking=no /home/ubuntu/impeller-artifact/impeller/bin $CLIENT_HOST:/home/ubuntu/impeller-artifact/impeller
