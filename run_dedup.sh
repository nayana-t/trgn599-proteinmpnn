#!/bin/bash
#SBATCH --account=sli68423_1965
#SBATCH --partition=main
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --job-name=mpnn-repro
#SBATCH --output=logs/dedup-%j.out

# Reproduction of ProteinMPNN native sequence recovery

module purge
module load conda
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate mpnn-repro

set -euo pipefail
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

cd /project2/sli68423_1965/tellakul/assignment_3
mkdir -p outputs_dedup

echo "=== settings ==="
echo "structures: $(ls data/pdbs_dedup/*.pdb | wc -l)"
echo "checkpoint: v_48_002   temp: 0.1   seqs/target: 8   seed: 37"

# Step 1: parse structures into ProteinMPNN's input format
python ProteinMPNN/helper_scripts/parse_multiple_chains.py \
  --input_path=data/pdbs_dedup/ \
  --output_path=outputs_dedup/parsed_pdbs.jsonl

# Step 2: design sequences from backbone geometry alone
python ProteinMPNN/protein_mpnn_run.py \
  --jsonl_path outputs_dedup/parsed_pdbs.jsonl \
  --out_folder outputs_dedup \
  --model_name v_48_002 \
  --num_seq_per_target 8 \
  --sampling_temp "0.1" \
  --seed 37 \
  --batch_size 1

# Step 3: aggregate the seq_recovery values ProteinMPNN wrote into the headers
echo "=== result ==="
grep -h "seq_recovery=" outputs_dedup/seqs/*.fa | sed 's/.*seq_recovery=//' | \
  awk '{s+=$1; n++} END {printf "proteins: %d  sequences: %d  mean recovery: %.4f\n", NR_FILES, n, s/n}' \
  NR_FILES=$(ls outputs_dedup/seqs/*.fa | wc -l)
