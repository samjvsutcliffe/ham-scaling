#!/bin/bash

# Request resources:
#SBATCH -c 64     # 1 entire node
#SBATCH --time=0:30:0  # 6 hours (hours:minutes:seconds)
#SBATCH --mem=64G      # 1 GB RAM
#SBATCH -p shared

module load gcc
module load aocl

echo "Running code"
rm output/*

export REFINE=2
export OMP_NUM_THREADS=64
sbcl --dynamic-space-size 64000  --disable-debugger --load "test.lisp" --quit
export OMP_NUM_THREADS=32
sbcl --dynamic-space-size 32000  --disable-debugger --load "test.lisp" --quit
export OMP_NUM_THREADS=16
sbcl --dynamic-space-size 16000  --disable-debugger --load "test.lisp" --quit
export OMP_NUM_THREADS=8
sbcl --dynamic-space-size 8000  --disable-debugger --load "test.lisp" --quit
export OMP_NUM_THREADS=4
sbcl --dynamic-space-size 4000  --disable-debugger --load "test.lisp" --quit
export OMP_NUM_THREADS=2
sbcl --dynamic-space-size 4000  --disable-debugger --load "test.lisp" --quit
export OMP_NUM_THREADS=1
sbcl --dynamic-space-size 4000  --disable-debugger --load "test.lisp" --quit
#export OMP_PROC_BIND=true 
#export OMP_PLACES=cores
#export OMP_NUM_THREADS=32
#sbcl --dynamic-space-size 32000  --disable-debugger --load "test.lisp" --quit
#export OMP_NUM_THREADS=16
#sbcl --dynamic-space-size 16000  --disable-debugger --load "test.lisp" --quit
