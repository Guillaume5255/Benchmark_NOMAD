here are the files needed to run NOMAD 4 with the implementation of Multi-poll, Oignon-poll and Enriched-poll.

On one side : c++ and .sh files : to run NOMAD 4
On the other side : .jl files : to exploit data.

when make is run, benchmark.cpp is compiled in ../run with the brackbox problems in /problems (24 analytical problems without constraints and one real blackbox, styrene)

benchmark.cpp uses the library mode of NOMAD 4 to run it on several problems and change the algorithm parameter. Two uses can be done : 
	./benchmark.exe 1 2 3 4 5 will run NOMAD 4 in dimension 1, on problem 2 generated with seed value 3, with poll strategy 4, with 5 positives basis
	./benchmark.exe will run NOMAD 4 with parameters specified in the main function of benchmark.cpp

running benckmark.exe will generate one or many .txt files containing the optimization history to the specific set of parameters. 
Restarted benchmark.exe will not do already existing runs ie. runs corresponding to .txt files that already exist.
/!\ ctrl+c while benchmark.exe is running is stopping NOMAD 4 but empty run files are created. you need to hit this command several times in a row to avoid it

benchmarkJobs.sh is used to run benchmark.exe in an environment that is using SLURM for parallel computing


.jl files implement tools to vizualize data form several run files. those tools are data and performane profile from the book "Derivative-Free and Blackbox Optimization"

-dataStruct.jl is used to create an object built with the data from each run file.
-helperFunctions.jl contains a set of functions that are useful to extract data form .txt files and to manage collections of runs.
-data-perf-profile.jl implements the data and performance profiles
-plot-profile.jl manages plotting profiles with some provided data

-compareGeometry.jl uses plot-profile.jl to represent the influence of geometry of set of points in the optimization performances.
-compareStaticDynamicWithoutMemory uses plot-profile.jl to represent the influence of a variating number of points in scalable strategies in the optimization

