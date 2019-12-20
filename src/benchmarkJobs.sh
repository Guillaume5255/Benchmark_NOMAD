#!/bin/bash

#SBATCH --job-name="MADS_POLL_benchmark"
# Number of cores
#SBATCH -c 36
#SBATCH --nodes=1
#SBATCH --mail-type=END
#SBATCH --mail-user=guillaume.lameynardie@polymtl.ca
#SBATCH --array=1-24 #one task per problem
module load gcc/8.3.0

#min value
DIM_MIN=2
PB_NUM_MIN=$(( ($SLURM_ARRAY_TASK_ID - 1)  + 1 ))
PB_SEED_MIN=0
POLL_STRATEGY_MIN=1
NB_2N_BLOCK_MIN=2


#max value
DIM_MAX=33
PB_NUM_MAX=$(( $SLURM_ARRAY_TASK_ID  ))
PB_SEED_MAX=1
POLL_STRATEGY_MAX=5
NB_2N_BLOCK_MAX=5

EXE="benchmarker.exe"
SLURM_RQ="srun --hint=compute_bound --hint=multithread"
CMD="$PWD/../run/$EXE"
#PAR="&"

for (( dim=$DIM_MIN; dim<$DIM_MAX; dim=$((2*$dim))  )); do
	for (( pb_num=$PB_NUM_MIN; pb_num<=$PB_NUM_MAX; ++pb_num  )); do
		for (( pb_seed=$PB_SEED_MIN; pb_seed<$PB_SEED_MAX; ++pb_seed  )); do

			for (( poll_strategy=$POLL_STRATEGY_MIN; poll_strategy<$POLL_STRATEGY_MAX; ++poll_strategy  )); do
				nb_2n_block=$((1+2*$dim *$(($poll_strategy -1)) ))
				ARGS="$dim $pb_num $pb_seed $poll_strategy $nb_2n_block"
				#for poll strategy 1 and 2 the number of 2n blocks is already fixed, for classic poll,
				#there is only one block, fot the multi poll, there are 2*n+1 blocks of 2n points.
				if [ "$poll_strategy" -eq "1" ]|| [ "$poll_strategy" -eq "2" ] ; then
					$SLURM_RQ $CMD $ARGS $PAR
				else
					for (( nb_2n_block=$NB_2N_BLOCK_MIN; nb_2n_block<$NB_2N_BLOCK_MAX; nb_2n_block=$(( 2*$nb_2n_block))   )); do
						ARGS="$dim $pb_num $pb_seed $poll_strategy $nb_2n_block"
						$SLURM_RQ $CMD $ARGS $PAR
					done
				fi
			done
		done
	done
done

