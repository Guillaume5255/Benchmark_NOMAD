#!/bin/sh

module unload gcc/9.1.0
module load gcc/7.2.0

DIM=8
PB_NUM=25
EXE="benchmarker.exe"
PB_SEED_MIN=0
PB_SEED_MAX=10
PARENT_PATH=$PWD

classicalPollRunner () {
	cd classical-poll
	CMD="$PWD/$EXE"
	for pb_seed in `seq 0 9`;
	do
		$CMD $DIM $PB_NUM $pb_seed 1 1
	done
	cd $PARENT_PATH
}

runner () {
	nb_2n_block=64
	cd "$PARENT_PATH/$1"
	CMD="$PWD/$EXE"
	for pb_seed in `seq 0 0`;
	do
		$CMD $DIM $PB_NUM $pb_seed 3 $nb_2n_block &
		$CMD $DIM $PB_NUM $pb_seed 4 $nb_2n_block
	done
	cd $PARENT_PATH
}

#classicalPollRunner &
runner "dynamic/sans-mem/lin" &
runner "dynamic/sans-mem/exp"&
runner "static" &
runner "dynamic/avec-mem/lin" &
runner "dynamic/avec-mem/exp"
