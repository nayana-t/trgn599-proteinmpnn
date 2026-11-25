# trgn599-proteinmpnn
# Partial reproduction: ProteinMPNN native sequence recovery

TRGN 599, Module 3 — paper critique and partial reproduction.

**Paper.** Dauparas, J. *et al.* "Robust deep learning-based protein sequence
design using ProteinMPNN." *Science* **378**, 49-56 (2022).
doi:10.1126/science.add2187

**Authors' code and weights.** <https://github.com/dauparas/ProteinMPNN>
(commit `8907e667`, as recorded in the output FASTA headers)

**Result reproduced.** Figure 2A — average native sequence recovery on native
protein backbones. Published: **52.4%** for ProteinMPNN, 32.9% for Rosetta.

## Result

| | sequence recovery | n |
|---|---|---|
| Published (Fig. 2A) | 52.4% | 402 backbones |
| This reproduction, deduplicated | **55.06%** (95% CI 50.3-59.8) | 18 proteins |
| This reproduction, before deduplication | 56.15% | 36 structures |

The published value falls inside the confidence interval, so this reproduction
is statistically consistent with the paper.

Per-protein recovery ranged from 32.6% (7PC1) to 80.0% (7PCA), SD 10.2
percentage points. See `results_recovery.csv`.

## What was run

Inference only, using the authors' released `v_48_002` checkpoint (48 edges,
0.02 A training noise), which ships inside their repository. No training or
fine-tuning.

| setting | value |
|---|---|
| checkpoint | `v_48_002` |
| sampling temperature | 0.1 |
| sequences per target | 8 |
| random seed | 37 |
| backbone noise at inference | 0.0 |

The paper does not state which checkpoint, sampling temperature, or number of
designs per backbone produced the 52.4% in Fig. 2A. These settings are
therefore my own choices, not a reconstruction of the authors' protocol.

Compute: USC CARC Discovery, `main` partition, 4 CPU cores, no GPU. Roughly
3-9 seconds per protein.

## Test set

Selected by RCSB query (`query.json`), not hand-picked:

- deposited after **2021-08-02**, the training-data cutoff for the released
  weights (stated in the authors' `training/README.md`)
- X-ray diffraction, resolution 2.0 A or better
- single polymer chain, 50-250 residues
- first 40 hits sorted by deposition date ascending (4,754 entries matched)

Because every structure postdates the training data, none can have been
trained on. 36 of the 40 downloaded successfully in legacy PDB format.

**Deduplication.** Sorting by deposition date returns structures deposited in
batches, which are often the same protein under different conditions. The
initial 36 structures contained only 18 distinct proteins — nine structures of
one 178-residue protein, six of another, and so on. `dedupe.py` keeps one
representative per group, greedily excluding any structure whose native
sequence is >= 0.90 similar to a representative already kept (Python
`difflib.SequenceMatcher` ratio, not a formal sequence alignment).

Deduplication moved the mean from 56.15% to 55.06%, i.e. redundancy was
inflating the result. The authors cluster their own training data at 30%
sequence identity for the same reason.

## Reproducing

Requires Python >= 3.9, PyTorch, NumPy. No GPU.

```bash
git clone https://github.com/dauparas/ProteinMPNN.git

module purge
module load conda
conda create -n mpnn-repro python=3.10 -y
conda activate mpnn-repro
pip install torch numpy

# rebuild the test set (login node - compute nodes have no internet)
curl -sS -X POST https://search.rcsb.org/rcsbsearch/v2/query \
  -H "Content-Type: application/json" --data-binary @query.json -o results.json
mkdir -p data/pdbs
while read id; do
  curl -sSf -o "data/pdbs/${id}.pdb" "https://files.rcsb.org/download/${id}.pdb" \
    || echo "FAILED: $id"
done < pdb_ids.txt

sbatch run_reproduction.sh   # all structures
python dedupe.py
sbatch run_dedup.sh          # distinct proteins only
python final_result.py
```

Edit `--account` in the Slurm scripts to your own allocation.

## Notes on reproducibility

`--seed 37` gave bit-identical recovery values across two different machines
for an identical input set. It does not give per-protein stability when the
input set changes: ProteinMPNN draws from one seeded stream across all
structures in a batch, so the same protein can receive different noise
depending on what else is in the run.
