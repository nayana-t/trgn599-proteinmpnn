import glob, re, csv, statistics

rows, allv = [], []
for path in sorted(glob.glob("outputs_repro/seqs/*.fa")):
    vals = [float(x) for x in re.findall(r"seq_recovery=([0-9.]+)", open(path).read())]
    if not vals:
        continue
    name = path.split("/")[-1].replace(".fa", "")
    rows.append([name, len(vals), round(statistics.mean(vals), 4),
                 round(min(vals), 4), round(max(vals), 4)])
    allv += vals

with open("results_recovery.csv", "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["protein", "n_seqs", "mean", "min", "max"])
    w.writerows(rows)

print(f"proteins: {len(rows)}  sequences: {len(allv)}")
print(f"mean recovery:   {statistics.mean(allv):.4f}")
print(f"per-protein min: {min(r[2] for r in rows):.4f}")
print(f"per-protein max: {max(r[2] for r in rows):.4f}")
print(f"published:       0.5240")
