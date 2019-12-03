# Benchmark_NOMAD
In this depot, an implementation of a set of problems is used to do scalability and performance benchmark over 4 poll strategies implemented in NOMAD 4.

Problems are implemented in /src/problems,
when make is run in a terminal open in /src, it compiles benchmark.cpp, builds (if not already exists) the directory /runs and put the binary file benchmarker.exe in it. When executed, this program produces the historic of the amelioration of the objectives functions optimized by NOMAD 4. The run historic has the name :
run_dimension_problemNum_problemSeed_pollStrategy_numberOf2nBlocks_.txt 
with :

  -dimension : is the number of input for the blackbox
  
  -problemNum : define which problem is used (1 to 24)
  
  -problemSeed : is used to generate random deterministic componens in the selected problem (such as rotation matrix).
                This feature allows us to generate a whole family of problems with only one initial problem, just like changing the     
                starting point.

  -pollStrategy : defines the poll strategy used duting the run (1 = classic poll, 2 = multi poll, 3 = oignon poll, 4 = extended 
                poll)

  -numberOf2nBlocks : refers to the number of multiple of 2n point (where n is the dimension) generated for the poll step. this
                   parameter can only be set for oignon poll and entended poll. For claccic poll,  numberOf2nBlocks = 1 and for 
                   multi poll, numberOf2nBlocks = 2n+1.
