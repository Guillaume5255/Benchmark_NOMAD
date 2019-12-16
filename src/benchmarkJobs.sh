#!/bin/bash


DIM_MIN=4
PB_NUM_MIN=1
PB_SEED_MIN=0
POLL_STRATEGY_MIN=1
NB_2N_BLOCK_MIN=2

DIM_MAX=8
PB_NUM_MAX=3
PB_SEED_MAX=2
POLL_STRATEGY_MAX=5
NB_2N_BLOCK_MAX=5

EXE = benchmarker.exe

SLURM_RQ = srun

for (( dim = $DIM_MIN; dim < $DIM_MAX; dim =$(expr 2'*'"$dim")  )); do
	for (( pb_num = $PB_NUM_MIN; pb_num < $PB_NUM_MAX; ++pb_num  )); do
		for (( pb_seed = $PB_SEED_MIN; pb_seed < $PB_SEED_MAX; ++pb_seed  )); do

			for (( poll_strategy = $POLL_STRATEGY_MIN; poll_strategy < $POLL_STRATEGY_MAX; ++poll_strategy  )); do
				if [ "$poll_strategy" -eq "1" ]|| [ "$poll_strategy" -eq "2" ] ; then
  					$SLURM_RQ ./$EXE $dim $pb_num $pb_seed $poll_strategy 1
				else
					for (( nb_2n_block = $NB_2N_BLOCK_MIN; nb_2n_block < $NB_2N_BLOCK_MAX; nb_2n_block =$(expr 2'*'"$nb_2n_block")   )); do
						 $SLURM_RQ ./$EXE $dim $pb_num $pb_seed $poll_strategy $nb_2n_block
					done
				fi
			done
		done
	done
done

