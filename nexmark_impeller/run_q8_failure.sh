#!/bin/bash
set -x
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
WORKSPACE_DIR=$(realpath $SCRIPT_DIR/../../)
DIR=q8/mem

cd $DIR
HELPER_SCRIPT=$(realpath $SCRIPT_DIR/../scripts/exp_helper)
$HELPER_SCRIPT start-machines
./setup_machine.sh
cd ../..

TPS_PER_WORKER=(20000 24000 28000)
NUM_WORKER=4
DURATION=330
WARM_DURATION=0
APP=q8
FLUSH_MS=100
SRC_FLUSH_MS=100
SNAPSHOT_S=0
COMM_EVERY_MS=100

cd ${DIR}
for ((i = 0; i < 1; ++i)); do
	for ((idx = 0; idx < ${#TPS_PER_WORKER[@]}; ++idx)); do
		TPS=$(expr ${TPS_PER_WORKER[idx]} \* ${NUM_WORKER})
		EVENTS=$(expr $TPS \* $DURATION)
		echo ${APP}, ${DIR}, ${EVENTS} events, ${TPS} tps
		subdir=${DURATION}s_${WARM_DURATION}swarm_${FLUSH_MS}ms_src${SRC_FLUSH_MS}ms

		./run_once.sh --app ${APP} \
			--exp_dir ./${NUM_WORKER}src_nosnap_300/$subdir/$i/${TPS_PER_WORKER[idx]}tps_epoch/ \
			--gua epoch --duration $DURATION --events_num ${EVENTS} --nworker ${NUM_WORKER} \
			--tps ${TPS} --warm_duration ${WARM_DURATION} --flushms $FLUSH_MS \
			--src_flushms $SRC_FLUSH_MS --fail true --snapshot_s ${SNAPSHOT_S} \
			--comm_everyMs ${COMM_EVERY_MS}
	done
done
cd -

cd $DIR
$HELPER_SCRIPT stop-machines
cd ../..
