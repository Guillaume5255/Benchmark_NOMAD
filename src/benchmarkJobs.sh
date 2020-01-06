#!/bin/bash

#SBATCH --job-name="MADS_POLL_benchmark"
# Number of cores
#SBATCH -c 36
#SBATCH --nodes=1
#SBATCH --mail-type=END
#SBATCH --mail-user=Lameynardie.Guillaume@ireq.ca
#SBATCH --array=1-96%40 #one task is a run with one specific poll strategy and a pb number
# 96 tasks that can be run simultanously but upper limit is 40
module load gcc/8.3.0

#min value
DIM_MIN=2
PB_NUM_MIN=$(( ($SLURM_ARRAY_TASK_ID)%24 + 1 ))
#PB_NUM_MIN=1
PB_SEED_MIN=0
POLL_STRATEGY_MIN=$(( ($SLURM_ARRAY_TASK_ID -1)/24 + 1))
#POLL_STRATEGY_MIN=1
NB_2N_BLOCK_MIN=9


#max value
DIM_MAX=65
PB_NUM_MAX=$(( ($PB_NUM_MIN) + 1 ))
#PB_NUM_MAX=25
PB_SEED_MAX=5
POLL_STRATEGY_MAX=$(( ($POLL_STRATEGY_MIN) + 1 ))
#POLL_STRATEGY_MAX=5

NB_2N_BLOCK_MAX=17

EXE="benchmarker.exe"
SLURM_RQ="srun --hint=compute_bound --hint=multithread"
CMD="$PWD/../run/$EXE"
#PAR="&"

runCounter=0

for (( dim=$DIM_MIN; dim<$DIM_MAX; dim=$((2*$dim))  )); do
	for (( pb_num=$PB_NUM_MIN; pb_num<$PB_NUM_MAX; ++pb_num  )); do
		for (( pb_seed=$PB_SEED_MIN; pb_seed<$PB_SEED_MAX; ++pb_seed  )); do

			for (( poll_strategy=$POLL_STRATEGY_MIN; poll_strategy<$POLL_STRATEGY_MAX; ++poll_strategy  )); do
				nb_2n_block=$((1+2*$dim *$(($poll_strategy -1)) ))
				ARGS="$dim $pb_num $pb_seed $poll_strategy $nb_2n_block"
				#for poll strategy 1 and 2 the number of 2n blocks is already fixed, for classic poll,
				#there is only one block, for the multi poll, there are 2*n+1 blocks of 2n points.
				if [ "$poll_strategy" -eq "1" ]|| [ "$poll_strategy" -eq "2" ] ; then
					$SLURM_RQ $CMD $ARGS $PAR
					#runCounter=$(($runCounter +1))
				else
					for (( nb_2n_block=$NB_2N_BLOCK_MIN; nb_2n_block<$NB_2N_BLOCK_MAX; ++nb_2n_block)); do
						ARGS="$dim $pb_num $pb_seed $poll_strategy $nb_2n_block"
						$SLURM_RQ $CMD $ARGS $PAR
						#runCounter=$(($runCounter +1))
					done
				fi
			done
		done
	done
done

#echo "nb runs done : $runCounter"
