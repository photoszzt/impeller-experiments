#!/bin/bash
set -x
HELPER_SCRIPT=$(realpath $SCRIPT_DIR/../../scripts/exp_helper)
$HELPER_SCRIPT start-machines

TPS=(10 50 100)
DURATION=180
WARM_DURATION=0
WARM_EVENTS=0
payload=16Kb

for ((iter = 0; iter < 5; ++iter)); do
	for ((idx = 0; idx < ${#TPS[@]}; ++idx)); do
		EVENTS=$(expr $DURATION \* ${TPS[idx]})
		echo ${TPS[idx]}, ${payload}, ${EVENTS}, ${WARM_EVENTS}
		./produce_bench.sh --exp_dir 180s_0swarm/1p_1t_1par_${TPS[idx]}tps/$iter/${payload} \
			--ncon 1 --nprod 1 --duration $DURATION \
			--events_num ${EVENTS} --num_par 1 --payload payload-${payload}.data \
			--tps ${TPS[idx]} --warm_duration $WARM_DURATION --warm_events ${WARM_EVENTS}
	done
done

$HELPER_SCRIPT stop-machines
