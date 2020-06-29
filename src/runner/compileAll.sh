#!/bin/bash

module unload gcc/9.1.0
module load gcc/7.2.0

SRC_PATH=$PWD
EXE=../../run/benchmarker.exe
DEST_PATH=../../run-pc-perso-confinement/run-styrene/deterministic/wo-opportunism

make RUNNER_SOURCE=benchmark_static.cpp
mv $EXE $DEST_PATH/static/

make RUNNER_SOURCE=benchmark_dyn_wo_mem_lin.cpp
mv $EXE $DEST_PATH/dynamic/sans-mem/lin/

make RUNNER_SOURCE=benchmark_dyn_wo_mem_exp.cpp
mv $EXE $DEST_PATH/dynamic/sans-mem/exp/

make RUNNER_SOURCE=benchmark_dyn_w_mem_lin.cpp
mv $EXE $DEST_PATH/dynamic/avec-mem/lin/

make RUNNER_SOURCE=benchmark_dyn_w_mem_exp.cpp
mv $EXE $DEST_PATH/dynamic/avec-mem/exp/

