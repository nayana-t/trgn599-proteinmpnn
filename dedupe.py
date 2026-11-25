import glob, difflib, shutil, os

# The first sequence in each ProteinMPNN output file is the native sequence.
native = {}
for path in sorted(glob.glob("outputs_repro/seqs/*.fa")):
    lines = open(path).read().splitlines()
    name = path.split("/")[-1].replace(".fa", "")
    native[name] = lines[1].strip()

# Greedy clustering: keep a structure only if it is < 90% identical to
# every representative already kept.
keep = []
for name, seq in native.items():
    if all(difflib.SequenceMatcher(None, seq, native[k]).ratio() < 0.90
           for k in keep):
        keep.append(name)

print(f"{len(native)} structures -> {len(keep)} distinct proteins")
print("kept:", " ".join(keep))

os.makedirs("data/pdbs_dedup", exist_ok=True)
for name in keep:
    shutil.copy(f"data/pdbs/{name}.pdb", f"data/pdbs_dedup/{name}.pdb")
open("pdb_ids_dedup.txt", "w").write("\n".join(keep) + "\n")
