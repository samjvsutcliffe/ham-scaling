#!/bin/bash

# Request resources:
#SBATCH --time=0:40:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p shared
#SBATCH --cpus-per-task=1   # number of MPI ranks per CPU socket
#SBATCH --mem-per-cpu=8G

module load aocc/5.0.0
module load aocl/5.0.0
module load mvapich2
export MV2_ENABLE_AFFINITY=0
echo "Running MPI weak scaling test"

export GC_THREADS=1
export OMP_NUM_THREADS=1

mpirun -N $TASK_REFINE ./mpi-worker
