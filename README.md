# Impeller benchmark
This repository holds the benchmark for Impeller. 

### Experiment tool
- latency
```bash
cd ./latency && cargo build --release
```

### Experiments ###

#### Example command
- run query 1 for 60 seconds with 1 iterations
  ```bash
  cd ./impeller-experiments/nexmark_impeller/ && ./run_q1_quick.sh && cd -
  ```

#### Rerun experiments that produce figure 7
- experiments on Impeller 
  ```bash
  cd ./impeller-experiments/nexmark_impeller/
  # run ./run_q1.sh to ./run_q8.sh
  ```
- experiments on Kafka Streams
  ```bash
  cd ./impeller-experiments/nexmark_kafka-streams
  # run ./run_q1.sh to ./run_q8.sh
  ```
Serially execute these scripts are estimated to take 6300 mins. 

#### Rerun experiments that produce figure 8
  ```bash
  cd ./impeller-experiments/nexmark_impeller/
  # run ./run_q1_commit_interval.sh to ./run_q8_commit_interval.sh
  ```
Serially execute these scripts are estimated to take 1600 mins. 

#### Using latency command to collect the experiment result
For Kafka Stream results, query 1
```bash
latency scan --prefix q1_sink_ets --output $output_dir $q1_exp_dir # the exp dir is the dir that contains logs
```
For q2 to q8, change the prefix from q1_sink_ets to q2_sink_ets .. q8_sink_ets

For impeller experiments,
- query 1
```bash
latency scan --prefix query1 --suffix .json.gz --output $output_dir $q1_exp_dir
```
- query 2
```bash
latency scan --prefix query2 --suffix .json.gz --output $output_dir $q2_exp_dir
```
- query 3
```bash
latency scan --prefix q3JoinTable --suffix .json.gz --output $output_dir $q3_exp_dir
```
- query 4
```bash
latency scan --prefix q4Avg --suffix .json.gz --output $output_dir $q4_exp_dir
```
- query 5
```bash
latency scan --prefix q5maxbid --suffix .json.gz --output $output_dir $q5_exp_dir
```
- query 6
```bash
latency scan --prefix q6Avg --suffix .json.gz --output $output_dir $q6_exp_dir
```
- query 7
```bash
latency scan --prefix q7JoinMaxBid --suffix .json.gz --output $output_dir $q7_exp_dir
```
- query 8
```bash
latency scan --prefix q8JoinStream --suffix .json.gz --output $output_dir $q8_exp_dir
```

### Paper
Impeller: Stream Processing on Shared Logs

### License
Impeller benchmark follows the Apache License 2.0
