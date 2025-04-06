import csv
import subprocess
import os
import json
from fig_const import headers

markFreq = [10, 20, 40, 100]
markIntr = [100, 50, 25, 10]

throughputs = {
    1: "32000",
    2: "64000",
    3: "64000",
    4: "750",
    5: "32000",
    6: "500",
    7: "12000",
    8: "16000",
}

allow_throughputs = [
    [4000, 16000, 32000, 48000, 64000, 80000, 88000],
    [4000, 16000, 32000, 48000, 64000, 80000, 88000],
    [8000, 16000, 32000, 48000, 64000, 80000, 96000, 112000, 128000],
    [250, 500, 750, 1000, 1250, 1500],
    [1000, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000],
    [250, 500, 750, 1000, 1250, 1500],
    [4000, 8000, 12000, 16000, 20000, 24000, 28000, 32000, 36000, 40000],
    [4000, 8000, 12000, 16000, 20000, 24000, 28000, 32000, 36000],
]


def load(dpath, experiment):
    rows = subprocess.run(["./latency", "query", dpath], stdout=subprocess.PIPE)
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
        and int(row["tps"]) in allow_throughputs[experiment]
    ]
    rows.sort(key=lambda row: int(row["tps"]))
    return rows


def get_varflush(markIntr, query):
    top_dir = f"./fig8_data/q{query}"
    json_fname = f"q{query}.json"
    tp = throughputs[query]
    epoch_dir = f"{top_dir}/epoch"
    twopc_dir = f"{top_dir}/remote_2pc"
    epoch_p50 = []
    epoch_p99 = []
    twopc_p50 = []
    twopc_p99 = []
    for intr in markIntr:
        ep_fname = os.path.join(epoch_dir, f"{intr}ms", json_fname)
        if intr == 100:
            if query == 1 or query == 2:
                ep_dir = f"./fig7_data/impeller/q{query}-180s-0swarm-100ms-src10ms2"
            else:
                ep_dir = f"./fig7_data/impeller/q{query}-180s-0swarm-100ms-src100ms"
            epoch = load(ep_dir, query - 1)
            for row in epoch:
                if row["tps"] == tp:
                    epoch_p50.append(int(row["p50"]))
                    epoch_p99.append(int(row["p99"]))
        elif os.path.exists(ep_fname):
            with open(ep_fname, "r") as f:
                data = json.load(f)
            if tp in data:
                epoch_p50.append(data[tp]["p50"])
                epoch_p99.append(data[tp]["p99"])

        fname = os.path.join(twopc_dir, f"{intr}ms", json_fname)
        if intr == 100:
            if query == 1 or query == 2:
                r2pc_dir = f"./fig7_data/remote_2pc/q{query}-180s-0swarm-100ms-src10ms"
            else:
                r2pc_dir = f"./fig7_data/remote_2pc/q{query}-180s-0swarm-100ms-src100ms"
            r2pc = load(r2pc_dir, query - 1)
            for row in r2pc:
                if row["tps"] == tp:
                    twopc_p50.append(int(row["p50"]))
                    twopc_p99.append(int(row["p99"]))
        elif os.path.exists(fname):
            with open(fname, "r") as f:
                data = json.load(f)
            if tp in data:
                twopc_p50.append(data[tp]["p50"])
                twopc_p99.append(data[tp]["p99"])

    # print(f"mark intr: {markIntr}")
    # print(f"epoch p50: {epoch_p50}")
    # print(f"epoch p99: {epoch_p99}")
    # print(f"twopc p50: {twopc_p50}")
    # print(f"twopc p99: {twopc_p99}")
    return epoch_p50, epoch_p99, twopc_p50, twopc_p99


if __name__ == "__main__":
    q = 7
    mIntr = markIntr
    mFreq = markFreq
    epoch_p50, epoch_p99, twopc_p50, twopc_p99 = get_varflush(mIntr, q)
    with open(f"q{q}_freq.csv", "w") as f:
        csv_writer = csv.writer(f)
        csv_writer.writerow(mFreq)
        csv_writer.writerow(epoch_p50)
        csv_writer.writerow(epoch_p99)
        csv_writer.writerow(twopc_p50)
        csv_writer.writerow(twopc_p99)
