#!/bin/bash

# Request resources:
#SBATCH --time=0:40:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p shared
#SBATCH -n 1                    # number of MPI ranks
#SBATCH --cpus-per-task=64   # number of MPI ranks per CPU socket
#SBATCH --mem-per-cpu=1G

module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0

sbcl --dynamic-space-size 64000 --load "build_step.lisp"

echo "Running code"
rm data_WEAK.csv
export GC_THREADS=64
export OMP_NUM_THREADS=1
export INITIAL_REFINE=4
export NAME=WEAK
for s in DR
do
    export SOLVER=$s
    ##Up to 8^2=64 threads
    for r in 1 2 4 8
    do
        #echo $t
        export OMP_NUM_THREADS=$(bc<<< "$r*$r")
        export REFINE=$(bc<<< "$INITIAL_REFINE*$r")
        echo $REFINE
        ./worker
    done
done
