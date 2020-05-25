### Benchmark_NOMAD
In this depot, a set of problems is used to do scalability and performance benchmark over 4 poll strategies implemented in the beta version of [`NOMAD 4`](https://github.com/Guillaume5255/nomad). 

Analytical test problems are implemented in [`/src/problems/blackbox.cpp`](/src/problems/blackbox.cpp) and [`/src/problems/blackbox.hpp`](/src/problems/blackbox.hpp). they are numbered form 1 to 24.

A real blackbox code is avaliable in [`/src/problems/STYRENE`](/src/problems/STYRENE). this problem is accessible trough [`/src/problems/blackbox.hpp`](/src/problems/blackbox.hpp) as problem 25.


When `make` is run in [`/src/runner`](/src/runner), it compiles [`/src/runner/benchmark.cpp`](/src/runner/benchmark.cpp) in [`/run`](/run) 

there are two ways to run this program :
	-with five arguments : type `./benchmarker.exe 8 12 0 4 6` and problem 12 will be generated in dimension 8 with seed 0 and solved with poll strategy 4 with 6 positive basis. This is used to run a specific instance
	- with no arguments : type `./benchmarker.exe` the program will iterate trough the loops of the main function of [`/src/runner/benchmark.cpp`](/src/runner/benchmark.cpp). This is used to run many instances.

When executed, this program produces the history of the amelioration of the objectives 
functions optimized by NOMAD 4. The run history has the name :
run_dimension_problemNum_problemSeed_pollStrategy_numberOf2nBlocks_.txt 
with :

  -dimension : is the number of input for the blackbox
  
  -problemNum : define which problem is used. 
			1 to 24 : analytical problems without constraint, 
			25 : styrene, a blackbox problem of dimension 8 with 4 binary constraints and 7 quantifiable constraints
  
  -problemSeed : is used to generate random deterministic componens in the selected problem (such as rotation matrix and starting point).
                This feature allows us to generate a whole family of problems with only one initial problem, just like changing the     
                starting point. (not working with styrene)

  -pollStrategy : defines the poll strategy used during the run (1 = classic poll, 2 = multi poll, 3 = oignon poll, 4 = enriched 
                poll)

  -numberOf2nBlocks : refers to the number of 2n positive basis (where n is the dimension) used to generate points for the poll step. This parameter can only be set for oignon poll and extended poll. For classic poll,  numberOf2nBlocks = 1 and for multi poll, numberOf2nBlocks = 2n+1.

Each line of each run history are : `ITER EVAL TIME BBO`

and contains at least four columns : the first column is the iteration number (of NOMAD4) at which a new success was found, the second 
column is the evaluation number, the third column is the value of f that led to the corresponding success, the fourth column is the time that went through since the begining of the optimization.

All analytical problems are bounded below by 0, are defined for x in `[-5, 5]^n` and are without any constraint.
An idea that could be exploited to build constrained analytical problems would be to use one of those analytical problems as objectif, and one 
or several others as constraints.

Styrene is solved in the box `[0,100]^8`

The program Benchmark.jl written in julia, exploits the data contained in the files created by the execution of benchmarker.exe to 
extract relevant data about the runs.

