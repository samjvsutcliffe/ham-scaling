#!/bin/bash

module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0
set -e
sbcl --dynamic-space-size 8000 --load "build_step_mpi.lisp"
set +e
rm data_MPI_WEAK.csv
echo "solver,threads,refine,throughput,mp-throughput" >> data_MPI_WEAK.csv

export GC_THREADS=1
export OMP_NUM_THREADS=1
export INITIAL_REFINE=1
export NAME=MPI_WEAK
for s in DR
do
    export SOLVER=$s
    ##Up to 8^2=64 threads
    for r in 1 2 4 8 16 32 64 128 256
    do
        export REFINE=$(bc<<< "$INITIAL_REFINE*$r")
        export TASK_REFINE=$(bc<<< "$r")
        sbatch --nodes 1-512 --ntasks $TASK_REFINE batch_mpiweak_multi.sh
    done
done
