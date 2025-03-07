#!/bin/bash
set -x
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DIR="$SCRIPT_DIR/q1"

cd "$DIR"
HELPER_SCRIPT=$(realpath $SCRIPT_DIR/../scripts/exp_helper)
$HELPER_SCRIPT start-machines
./setup_machine.sh
cd "$SCRIPT_DIR"

TPS_PER_WORKER=(4000)
NUM_WORKER=4
DURATION=60
WARM_DURATION=0
APP=q1
FLUSH_MS=100
COMM_EVERY_MS=100
SRC_FLUSH_MS=10
SNAPSHOT_S=0
modes=(epoch)

cd ${DIR}
for ((idx = 0; idx < ${#TPS_PER_WORKER[@]}; ++idx)); do
	TPS=$(expr ${TPS_PER_WORKER[idx]} \* ${NUM_WORKER})
	EVENTS=$(expr $TPS \* $DURATION)
	echo ${APP}, ${DIR}, ${EVENTS} events, ${TPS} tps
	subdir=${DURATION}s_${WARM_DURATION}swarm_${FLUSH_MS}ms_src${SRC_FLUSH_MS}ms
	for mode in ${modes[@]}; do
		for ((iter = 0; iter < 1; ++iter)); do
			./run_once.sh --app ${APP} \
				--exp_dir ./${NUM_WORKER}src_quick/${subdir}/${iter}/${TPS_PER_WORKER[idx]}tps_${mode}/ \
				--gua $mode --duration $DURATION --events_num ${EVENTS} --nworker ${NUM_WORKER} \
				--tps ${TPS} --warm_duration ${WARM_DURATION} --flushms $FLUSH_MS --src_flushms $SRC_FLUSH_MS \
				--snapshot_s ${SNAPSHOT_S} --comm_everyMs ${COMM_EVERY_MS}
		done
	done
done
cd -

cd "$DIR"
$HELPER_SCRIPT stop-machines
cd "$SCRIPT_DIR"
