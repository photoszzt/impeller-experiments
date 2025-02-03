#!/bin/bash
set -x
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
WORKSPACE_DIR=$(realpath $SCRIPT_DIR/../../)
$WORKSPACE_DIR/research-helper-scripts/microservice_helper start-machines --use-spot-instances

TPS_PER_WORKER=(1000 8000 16000 24000 32000 40000 48000 56000 64000)
DURATION=180
WARM_DURATION=0
APP=q5
FLUSH_MS=100
NUM_INS=4
SRC_FLUSH_MS=100

cd $SCRIPT_DIR
for ((iter = 0; iter < 5; iter++)); do
	for ((idx = 0; idx < ${#TPS_PER_WORKER[@]}; ++idx)); do
		TPS=$(expr ${TPS_PER_WORKER[idx]} \* ${NUM_INS})
		EVENTS=$(expr ${TPS} \* $DURATION)
		echo ${APP}, ${EVENTS} events, ${TPS} tps
		subdir=${DURATION}s_${WARM_DURATION}swarm_${FLUSH_MS}ms_src${SRC_FLUSH_MS}ms
		./nexmark.sh --app ${APP} \
			--exp_dir "./${APP}/${NUM_INS}src/$subdir/$iter/${TPS_PER_WORKER[idx]}tps_eo/" \
			--nins ${NUM_INS} --nsrc ${NUM_INS} --serde msgp --duration $DURATION --nevents ${EVENTS} \
			--tps ${TPS} --warm_duration ${WARM_DURATION} --flushms $FLUSH_MS --src_flushms ${SRC_FLUSH_MS} --gua eo
	done
done
cd -

$WORKSPACE_DIR/research-helper-scripts/microservice_helper stop-machines
