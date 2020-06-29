#!/bin/bash
parentPath=$PWD

cd $parentPath/static
rm *

cd $parentPath/dynamic/sans-mem/lin
rm *

cd $parentPath/dynamic/sans-mem/exp
rm *

cd $parentPath/dynamic/avec-mem/lin
rm *

cd $parentPath/dynamic/avec-mem/exp
rm *

