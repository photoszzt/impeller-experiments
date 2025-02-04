#!/bin/bash
set -x
HELPER_SCRIPT=$(realpath $SCRIPT_DIR/../../scripts/exp_helper)
$HELPER_SCRIPT start-machines --use-spot-instances

TPS=(10 50 100)
DURATION=180
WARM_DURATION=0
WARM_EVENTS=0
payload=16Kb

for ((iter = 0; iter < 5; iter++)); do
	for ((idx = 0; idx < ${#TPS[@]}; ++idx)); do
		EVENTS=$(expr $DURATION \* ${TPS[idx]})
		./run_once.sh --exp_dir ${DURATION}s_${WARM_DURATION}swarm/1prod_1t_1par_${TPS[idx]}/$iter/${payload} \
			--tps "${TPS[idx]}" --warm_duration $WARM_DURATION --warm_events ${WARM_EVENTS} \
			--duration $DURATION --events_num "${EVENTS}" \
			--npar 1 --nprod 1 --payload "payload-${payload}.data"
	done
done

$HELPER_SCRIPT stop-machines
