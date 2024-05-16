#!/bin/bash

# Request resources:
#SBATCH --time=1:00:0  # 6 hours (hours:minutes:seconds)
#SBATCH -n 64                    # number of MPI ranks
#SBATCH --cpus-per-task=1   # number of MPI ranks per CPU socket
#SBATCH --mem=2G      # 1 GB RAM
#SBATCH -p shared
#SBATCH -N 1-64

module load gcc
module load aocl
module load mvapich2

echo "Running code"
rm output-mpi/*
export MV2_ENABLE_AFFINITY=0
export OMP_NUM_THREADS=1
sbcl --dynamic-space-size 2000 --load "build_step.lisp" --quit

#export REFINE=128
#mpirun -N 128 ./mpi-worker --dynamic-space-size 2000
export REFINE=64
mpirun -N 64 ./mpi-worker --dynamic-space-size 2000
export REFINE=32
mpirun -N 32 ./mpi-worker --dynamic-space-size 2000
export REFINE=16
mpirun -N 16 ./mpi-worker --dynamic-space-size 2000
export REFINE=8
mpirun -N 8 ./mpi-worker --dynamic-space-size 2000
export REFINE=4
mpirun -N 4 ./mpi-worker --dynamic-space-size 2000
export REFINE=2
mpirun -N 2 ./mpi-worker --dynamic-space-size 2000
export REFINE=1
mpirun -N 1 ./mpi-worker --dynamic-space-size 2000
