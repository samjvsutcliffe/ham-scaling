#!/bin/bash

# Request resources:
#SBATCH --time=0:40:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p shared
#SBATCH -N 1-144                    # number of MPI ranks
#SBATCH -n 144                    # number of MPI ranks
#SBATCH --cpus-per-task=1   # number of MPI ranks per CPU socket
#SBATCH --mem-per-cpu=8G

module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0

echo "Running MPI weak scaling test"


#sbcl --dynamic-space-size 8000 --load "build_step_mpi.lisp"

rm data_MPI_WEAK.csv
echo "solver,threads,refine,throughput,mp-throughput" >> data_MPI_WEAK.csv
for s in DR
do
    export SOLVER=$s
    ##Up to 8^2=64 threads
    for r in 1 2 4 8 10 11 12
    do
        #echo $t
        export OMP_NUM_THREADS=1
        export REFINE=$(bc<<< "$INITIAL_REFINE*$r")
        echo $REFINE
        mpirun -N $(bc<<< "$r*$r") ./mpi-worker
    done
done
