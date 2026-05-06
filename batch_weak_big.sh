#!/bin/bash

# Request resources:
#SBATCH --time=6:00:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p multi
#SBATCH -n 1                    # number of MPI ranks
#SBATCH --cpus-per-task=128   # number of MPI ranks per CPU socket
#SBATCH --mem=240G
#--mem-per-cpu=1G

module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0

#sbcl --dynamic-space-size 64000 --load "build_step.lisp"

echo "Running weak scaling"
rm data_WEAK_BIG.csv
export GC_THREADS=128
export OMP_NUM_THREADS=1
export INITIAL_REFINE=4
export NAME=WEAK_BIG
for s in DR IMPLICIT
do
    export SOLVER=$s
    ##Up to 8^2=64 threads
    for r in 1 2 4 8 16 32 48 64 96 128
    do
        #echo $t
        export OMP_NUM_THREADS=$(bc<<< "$r")
        export REFINE=$(bc<<< "$INITIAL_REFINE*$r")
        echo $REFINE
        ./worker --dynamic-space-size 240GB
    done
done
