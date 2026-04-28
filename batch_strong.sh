#!/bin/bash

# Request resources:
#SBATCH --time=0:30:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p shared
#SBATCH -n 1                    # number of MPI ranks
#SBATCH --cpus-per-task=64   # number of MPI ranks per CPU socket
#SBATCH --mem-per-cpu=1G


module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0

#sbcl --dynamic-space-size 64000 --load "build_step.lisp"

#export SOLVER=IMPLICIT
export REFINE=8
export GC_THREADS=64
export OMP_NUM_THREADS=1
export NAME=STRONG
rm data_STRONG.csv
# IMPLICIT
for s in DR
do
    export SOLVER=$s
    for t in 1 2 4 8 16 24 32 48 64
    do
        echo $t
        export OMP_NUM_THREADS=$t
        ./mpi-worker
    done
done
