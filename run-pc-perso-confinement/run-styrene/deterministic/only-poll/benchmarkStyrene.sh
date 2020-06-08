#!/bin/sh

#parentFolder=$PWD
#Folders="/dynamic/sans-mem/lin,/dynamic/sans-mem/exp,/dynamic/avec-mem/lin,/dynamic/avec-mem/exp,/classical-poll,/static"

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
		for poll_strategy in `seq 3 4`;
		do
			echo $CMD $DIM $PB_NUM $pb_seed $poll_strategy $nb_2n_block
		done
	done
	cd $PARENT_PATH

}

#echo "starting 1st batch"
#classicalPollRunner &
#runner "dynamic/sans-mem/lin" & 
#runner "dynamic/sans-mem/exp"

echo "starting 2e batch"
runner "static" &
runner "dynamic/avec-mem/lin" &
runner "dynamic/avec-mem/exp"
