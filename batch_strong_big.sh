#!/bin/bash

# Request resources:
#SBATCH --time=5:00:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p multi
#SBATCH -n 1                    # number of MPI ranks
#SBATCH --cpus-per-task=128   # number of MPI ranks per CPU socket
#SBATCH --mem=240G


#mem-per-cpu=1G
module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0

echo "Running strong scaling"
sbcl --dynamic-space-size 240GB --load "build_step.lisp"

#export SOLVER=IMPLICIT
#export REFINE=16
#rm data_STRONG_BIG.csv
export GC_THREADS=128
export OMP_NUM_THREADS=1
export NAME=STRONG_BIG
for r in 32
do
    export REFINE=$r
    for s in DR IMPLICIT
    do
        export SOLVER=$s
        for t in 128 96 64 48 32 16 8 4 2 1
        do
            echo $t
            export OMP_NUM_THREADS=$t
            ./worker --dynamic-space-size 240GB
        done
    done
done
