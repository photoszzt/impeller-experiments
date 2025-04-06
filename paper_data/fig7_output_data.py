import subprocess
import csv
from fig_const import headers

kafkas = [
    "./fig7_data/kafka/q1-kafka-180s-0swarm-100ms-src10ms",
    "./fig7_data/kafka/q2-kafka-180s-0swarm-100ms-src10ms",
    "./fig7_data/kafka/q3-kafka-180s-0swarm-100ms-src100ms",
    "./fig7_data/kafka/q4-kafka-180s-0swarm-100ms-src100ms",
    "./fig7_data/kafka/q5-kafka-180s-0swarm-100ms-src100ms",
    "./fig7_data/kafka/q6-kafka-180s-0swarm-100ms-src100ms",
    "./fig7_data/kafka/q7-kafka-180s-0swarm-100ms-src100ms",
    "./fig7_data/kafka/q8-kafka-180s-0swarm-100ms-src100ms",
]

syss = [
    "./fig7_data/impeller/q1-180s-0swarm-100ms-src10ms2",
    "./fig7_data/impeller/q2-180s-0swarm-100ms-src10ms2",
    "./fig7_data/impeller/q3-180s-0swarm-100ms-src100ms",
    "./fig7_data/impeller/q4-180s-0swarm-100ms-src100ms",
    "./fig7_data/impeller/q5-180s-0swarm-100ms-src100ms",
    "./fig7_data/impeller/q6-180s-0swarm-100ms-src100ms",
    "./fig7_data/impeller/q7-180s-0swarm-100ms-src100ms",
    "./fig7_data/impeller/q8-180s-0swarm-100ms-src100ms",
]

alignchkpts = [
    "./fig7_data/align_chkpt_kvrocks/q1-180s-0swarm-100ms-src10ms",
    "./fig7_data/align_chkpt_kvrocks/q2-180s-0swarm-100ms-src10ms",
    "./fig7_data/align_chkpt_kvrocks/q3-180s-0swarm-100ms-src100ms",
    "./fig7_data/align_chkpt_kvrocks/q4-180s-0swarm-100ms-src100ms",
    "./fig7_data/align_chkpt_kvrocks/q5-180s-0swarm-100ms-src100ms",
    "./fig7_data/align_chkpt_kvrocks/q6-180s-0swarm-100ms-src100ms",
    "./fig7_data/align_chkpt_kvrocks/q7-180s-0swarm-100ms-src100ms",
    "./fig7_data/align_chkpt_kvrocks/q8-180s-0swarm-100ms-src100ms",
]

remote_2pc = [
    "./fig7_data/remote_2pc/q1-180s-0swarm-100ms-src10ms",
    "./fig7_data/remote_2pc/q2-180s-0swarm-100ms-src10ms",
    "./fig7_data/remote_2pc/q3-180s-0swarm-100ms-src100ms",
    "./fig7_data/remote_2pc/q4-180s-0swarm-100ms-src100ms",
    "./fig7_data/remote_2pc/q5-180s-0swarm-100ms-src100ms",
    "./fig7_data/remote_2pc/q6-180s-0swarm-100ms-src100ms",
    "./fig7_data/remote_2pc/q7-180s-0swarm-100ms-src100ms",
    "./fig7_data/remote_2pc/q8-180s-0swarm-100ms-src100ms",
]

throughputs = [
    [4000, 16000, 32000, 48000, 64000, 80000, 88000],
    [4000, 16000, 32000, 48000, 64000, 80000, 88000],
    [8000, 16000, 32000, 48000, 64000, 80000, 96000, 112000, 128000],
    [250, 500, 750, 1000, 1250, 1500],
    [1000, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000],
    [250, 500, 750, 1000, 1250, 1500],
    [4000, 8000, 12000, 16000, 20000, 24000, 28000, 32000, 36000, 40000],
    [4000, 8000, 12000, 16000, 20000, 24000, 28000, 32000, 36000],
]


def load(system, experiment):
    rows = subprocess.run(
        ["./latency", "query", system[experiment]], stdout=subprocess.PIPE
    )
    rows = rows.stdout.decode("utf-8").strip().split("\n")
    rows = [
        row
        for row in csv.DictReader(rows, fieldnames=headers)
        if (
            row["del"] == "eo"
            or row["del"] == "2pc"
            or row["del"] == "align_chkpt"
            or row["del"] == "remote_2pc"
        )
        and int(row["tps"]) in throughputs[experiment]
    ]
    rows.sort(key=lambda row: int(row["tps"]))
    return rows


if __name__ == "__main__":
    experiment = 7
    kafka = load(kafkas, experiment)
    sys = load(syss, experiment)
    ackpt = load(alignchkpts, experiment)
    r2pc = load(remote_2pc, experiment)

    sys_in_per_worker_tp = [int(row["tps"]) for row in sys]
    kafka_in_per_worker_tp = [int(row["tps"]) for row in kafka]
    ackpt_in_per_worker_tp = [int(row["tps"]) for row in ackpt]
    remote2pc_in_per_worker_tp = [int(row["tps"]) for row in r2pc]

    kafka_in_tp = [i * 4 for i in kafka_in_per_worker_tp]
    sys_in_tp = [i * 4 for i in sys_in_per_worker_tp]
    ackpt_in_tp = [i * 4 for i in ackpt_in_per_worker_tp]
    r2pc_in_tp = [i * 4 for i in remote2pc_in_per_worker_tp]

    sys_p50 = [int(row["p50"]) for row in sys]
    sys_p99 = [int(row["p99"]) for row in sys]
    ackpt_p50 = [int(row["p50"]) for row in ackpt]
    ackpt_p99 = [int(row["p99"]) for row in ackpt]
    kafka_p50 = [int(row["p50"]) for row in kafka]
    kafka_p99 = [int(row["p99"]) for row in kafka]

    r2pc_p50 = [int(row["p50"]) for row in r2pc]
    r2pc_p99 = [int(row["p99"]) for row in r2pc]

    with open(f"q{experiment+1}.csv", "w") as f:
        csv_writer = csv.writer(f)
        csv_writer.writerow(sys_in_tp)
        csv_writer.writerow(sys_p50)
        csv_writer.writerow(sys_p99)
        csv_writer.writerow(kafka_in_tp)
        csv_writer.writerow(kafka_p50)
        csv_writer.writerow(kafka_p99)
        csv_writer.writerow(ackpt_in_tp)
        csv_writer.writerow(ackpt_p50)
        csv_writer.writerow(ackpt_p99)
        csv_writer.writerow(r2pc_in_tp)
        csv_writer.writerow(r2pc_p50)
        csv_writer.writerow(r2pc_p99)
