#!/bin/bash
parentPath=$PWD
RUNS=run_8_25_"$1"*

cd $parentPath/static
rm $RUNS

cd $parentPath/dynamic/sans-mem/lin
rm $RUNS

cd $parentPath/dynamic/sans-mem/exp
rm $RUNS

cd $parentPath/dynamic/avec-mem/lin
rm $RUNS

cd $parentPath/dynamic/avec-mem/exp
rm $RUNS

