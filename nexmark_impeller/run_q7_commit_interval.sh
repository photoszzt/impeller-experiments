#!/bin/bash
set -x
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
WORKSPACE_DIR=$(realpath $SCRIPT_DIR/../../)
DIR="$SCRIPT_DIR/q7/mem"

cd $DIR
HELPER_SCRIPT=$(realpath $SCRIPT_DIR/../scripts/exp_helper)
$HELPER_SCRIPT start-machines --use-spot-instances
./setup_machine.sh
cd "$SCRIPT_DIR"

TPS_PER_WORKER=12000
NUM_WORKER=4
DURATION=180
WARM_DURATION=0
APP=q7
SRC_FLUSH_MS=(10 25 50 100)
SNAPSHOT_S=10
modes=(remote_2pc epoch)

cd ${DIR}
for ((s = 0; s < ${#SRC_FLUSH_MS[@]}; ++s)); do
	FLUSH_MS=${SRC_FLUSH_MS[$s]}
	COMM_EVERY_MS=${SRC_FLUSH_MS[$s]}
	TPS=$(expr ${TPS_PER_WORKER} \* ${NUM_WORKER})
	EVENTS=$(expr $TPS \* $DURATION)
	echo ${APP}, ${DIR}, ${EVENTS} events, ${TPS} tps, $FLUSH_MS flush_ms, ${SRC_FLUSH_MS[$s]} srcflush_ms, $COMM_EVERY_MS comm_ms
	subdir=${DURATION}s_${WARM_DURATION}swarm_${FLUSH_MS}ms_src${SRC_FLUSH_MS[$s]}ms
	for mode in ${modes[@]}; do
		for ((iter = 0; iter < 5; ++iter)); do
			./run_once.sh --app ${APP} \
				--exp_dir ./${NUM_WORKER}src_commit_interval/${subdir}/${iter}/${TPS_PER_WORKER}tps_${mode}/ \
				--gua $mode --duration $DURATION --events_num ${EVENTS} --nworker ${NUM_WORKER} \
				--tps ${TPS} --warm_duration ${WARM_DURATION} --flushms $FLUSH_MS --src_flushms ${SRC_FLUSH_MS[$s]} \
				--snapshot_s ${SNAPSHOT_S} --comm_everyMs ${COMM_EVERY_MS}
		done
	done
done
cd -

cd "$DIR"
$HELPER_SCRIPT stop-machines
cd "$SCRIPT_DIR"
