#!/bin/bash
set -x
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
WORKSPACE_DIR=$(realpath $SCRIPT_DIR/../../)
DIR="$SCRIPT_DIR/q7/mem"

cd "$DIR"
$WORKSPACE_DIR/research-helper-scripts/microservice_helper start-machines --use-spot-instances
./update_docker.sh
cd "$SCRIPT_DIR"

TPS_PER_WORKER=(4000 8000 12000 16000 20000 24000 28000 32000 36000 40000)
NUM_WORKER=4
DURATION=180
WARM_DURATION=0
APP=q7
FLUSH_MS=100
SRC_FLUSH_MS=100
SNAPSHOT_S=10
COMM_EVERY_MS=5000
modes=(epoch 2pc align_chkpt)

cd ${DIR}
for ((idx = 0; idx < ${#TPS_PER_WORKER[@]}; ++idx)); do
	TPS=$(expr ${TPS_PER_WORKER[idx]} \* ${NUM_WORKER})
	EVENTS=$(expr $TPS \* $DURATION)
	echo ${APP}, ${DIR}, ${EVENTS} events, ${TPS} tps
	subdir=${DURATION}s_${WARM_DURATION}swarm_${FLUSH_MS}ms_src${SRC_FLUSH_MS}ms
	for mode in ${modes[@]}; do
		for ((iter = 0; iter < 5; ++iter)); do
			./run_once.sh --app ${APP} \
				--exp_dir ./${NUM_WORKER}src/${subdir}/${iter}/${TPS_PER_WORKER[idx]}tps_${mode}/ \
				--gua $mode --duration $DURATION --events_num ${EVENTS} --nworker ${NUM_WORKER} \
				--tps ${TPS} --warm_duration ${WARM_DURATION} --flushms $FLUSH_MS --src_flushms $SRC_FLUSH_MS \
				--snapshot_s ${SNAPSHOT_S} --comm_everyMs ${COMM_EVERY_MS}
		done
	done
done
cd -

cd "$DIR"
$WORKSPACE_DIR/research-helper-scripts/microservice_helper stop-machines
cd "$SCRIPT_DIR"
