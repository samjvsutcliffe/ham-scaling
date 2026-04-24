rm output/*
#export REFINE=64
#export OMP_NUM_THREADS=64
#./mpi-worker
#export REFINE=32
#export OMP_NUM_THREADS=32
#./mpi-worker
#export REFINE=16
#export OMP_NUM_THREADS=16
#./mpi-worker
export REFINE=4
export OMP_NUM_THREADS=8
./mpi-worker
export OMP_NUM_THREADS=4
./mpi-worker
export OMP_NUM_THREADS=2
./mpi-worker
export OMP_NUM_THREADS=1
./mpi-worker
