#!/bin/bash
parentPath=$PWD

cd $parentPath/static
rm run*

cd $parentPath/dynamic/sans-mem/lin
rm run*

cd $parentPath/dynamic/sans-mem/exp
rm run*

cd $parentPath/dynamic/avec-mem/lin
rm run*

cd $parentPath/dynamic/avec-mem/exp
rm run*

