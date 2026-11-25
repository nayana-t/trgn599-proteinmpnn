import glob, re, statistics, math

per_protein = []
for path in sorted(glob.glob("outputs_dedup/seqs/*.fa")):
    v = [float(x) for x in re.findall(r"seq_recovery=([0-9.]+)", open(path).read())]
    if v:
        per_protein.append((path.split("/")[-1].replace(".fa", ""), statistics.mean(v)))

vals = [m for _, m in per_protein]
n = len(vals)
mean = statistics.mean(vals)
sd = statistics.stdev(vals)
se = sd / math.sqrt(n)
lo, hi = mean - 1.96 * se, mean + 1.96 * se

for name, m in sorted(per_protein, key=lambda x: x[1]):
    print(f"  {name}  {100*m:5.1f}%")

print()
print(f"distinct proteins:   {n}")
print(f"mean recovery:       {100*mean:.2f}%")
print(f"SD across proteins:  {100*sd:.1f} points")
print(f"standard error:      {100*se:.1f} points")
print(f"approx 95% CI:       {100*lo:.1f}% to {100*hi:.1f}%")
print(f"published:           52.4%")
print(f"published in CI:     {lo <= 0.524 <= hi}")
