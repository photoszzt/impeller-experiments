#!/bin/bash
set -x
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
HELPER_SCRIPT=$(realpath $SCRIPT_DIR/../scripts/exp_helper)
$HELPER_SCRIPT start-machines
$SCRIPT_DIR/setup_machine.sh

TPS_PER_WORKER=(4000)
DURATION=60
WARM_DURATION=0
APP=q1
FLUSH_MS=10
NUM_INS=4
SRC_FLUSH_MS=10

cd $SCRIPT_DIR
for ((iter = 0; iter < 1; iter++)); do
	for ((idx = 0; idx < ${#TPS_PER_WORKER[@]}; ++idx)); do
		TPS=$(expr ${TPS_PER_WORKER[idx]} \* ${NUM_INS})
		EVENTS=$(expr ${TPS} \* $DURATION)
		echo ${APP}, ${EVENTS} events, ${TPS} tps
		subdir=${DURATION}s_${WARM_DURATION}swarm_${FLUSH_MS}ms_src${SRC_FLUSH_MS}ms
		./nexmark.sh --app ${APP} \
			--exp_dir "./${APP}/${NUM_INS}src/$subdir/$iter/${TPS_PER_WORKER[idx]}tps_eo/" \
			--nins ${NUM_INS} --nsrc ${NUM_INS} --serde msgp --duration $DURATION --nevents ${EVENTS} \
			--tps ${TPS} --warm_duration ${WARM_DURATION} --flushms $FLUSH_MS --src_flushms $SRC_FLUSH_MS --gua eo
	done
done
cd -

$HELPER_SCRIPT stop-machines
