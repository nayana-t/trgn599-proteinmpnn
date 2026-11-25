#!/bin/bash
#SBATCH --account=sli68423_1965
#SBATCH --partition=main
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:15:00
#SBATCH --job-name=mpnn-smoke
#SBATCH --output=logs/smoke-%j.out

set -euo pipefail

module purge
module load conda
eval "$(conda shell.bash hook)"
conda activate mpnn-repro

set -euo pipefail
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

cd /project2/sli68423_1965/tellakul/assignment_3
mkdir -p outputs

# Step 1: parse structures into the format ProteinMPNN reads
python ProteinMPNN/helper_scripts/parse_multiple_chains.py \
  --input_path=ProteinMPNN/inputs/PDB_monomers/pdbs/ \
  --output_path=outputs/parsed_pdbs.jsonl

# Step 2: design sequences with the authors' released weights (inference only)
python ProteinMPNN/protein_mpnn_run.py \
  --jsonl_path outputs/parsed_pdbs.jsonl \
  --out_folder outputs \
  --model_name v_48_002 \
  --num_seq_per_target 8 \
  --sampling_temp "0.1" \
  --seed 37 \
  --batch_size 1

echo "=== recovery values ==="
grep "^>" outputs/seqs/*.fa
