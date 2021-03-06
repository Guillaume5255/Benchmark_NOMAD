using DelimitedFiles
include("dataStruct.jl")

const ROOT_RUN_DIR = "/runData"

function Display(run::Run_t)
	str = "$(run.dim)_$(run.pb_num)_$(run.pb_seed)_$(run.poll_strategy)_$(run.nb_2n_blocks)"
	println(str)
end


function FindEmptyRun(dir::String)
	runs = ExtractData(dir)
	for run in runs
		if run.eval_f == []
			Display(run)
		end
	end
end


#returns the absolute path to the folder Benchmark_NOMAD :
#/dir1/dir2/dir3/Benchmark_NOAMD
function GetAbsolutePath()
	path = split(pwd(),"Benchmark_NOMAD")[1]
	path = path*"Benchmark_NOMAD"
	return path
end

#### function to extract data form files obtained with benchmarker.exe
function ExtractData(dir::String) 
	#fills an array of Run_t objects, each object contains the data of the run : 
	#wich dimension, which problem, which seed, which strategy, which number of 2n blocks
	#all files are of the format run_dim_pbNumber_pbSeed_pollStrategy_nbOf2nBlocks_.txt
	# all problems are scalable (dim \in N^*)
	#there are 24 problems (pbNumber \in [[1;24]])
	#pbSeed \in N
	#pollStrategy \in [[1;4]] 
	#	1:classic poll
	#	2:multi poll
	#	3:oignon poll
	#	4:enriched poll
	absolutePath = GetAbsolutePath()
	dir = absolutePath*dir
	runsList = readdir(dir)
	runs = Array{Run_t,1}([])
	nbRunsExtracted = 0
	for runName in runsList
		#println(runName)
		runAttr=split(runName, "_")
		if runAttr[1]=="run" #we only try to read run files
			runData = readdlm(dir*"/"*runName)
			
			run=Run_t(
			parse(Int,runAttr[2]),
			parse(Int,runAttr[3]),
			parse(Int,runAttr[4]),
			parse(Int,runAttr[5]),
			parse(Int,runAttr[6]),
			runData[:,1],
			runData[:,2],
			runData[:,3],
			runData[:,4])
			nbRunsExtracted = nbRunsExtracted +1
			push!(runs, run)
		end
	end
	println("Extracted $(nbRunsExtracted) runs")

	return runs
end

function OldExtractData(dir::String) 
	#fills an array of Run_t objects, each object contains the data of the run : 
	#wich dimension, which problem, which seed, which strategy, which number of 2n blocks
	#all files are of the format run_dim_pbNumber_pbSeed_pollStrategy_nbOf2nBlocks_.txt
	# all problems are scalable (dim \in N^*)
	#there are 24 problems (pbNumber \in [[1;24]])
	#pbSeed \in N
	#pollStrategy \in [[1;4]] 
	#	1:classic poll
	#	2:multi poll
	#	3:oignon poll
	#	4:enriched poll
	absolutePath = GetAbsolutePath()
	dir = absolutePath*dir
	runsList = readdir(dir)
	runs = Array{Run_t,1}([])
	nbRunsExtracted = 0
	for runName in runsList
		#println(runName)
		runAttr=split(runName, "_")
		if runAttr[1]=="run" #we only try to read run files
			runData = readdlm(dir*"/"*runName)

			run=Run_t(
			parse(Int,runAttr[2]),
			parse(Int,runAttr[3]),
			parse(Int,runAttr[4]),
			parse(Int,runAttr[5]),
			parse(Int,runAttr[6]),
			[0],
			runData[:,1],
			runData[:,3],
			runData[:,2])
			nbRunsExtracted = nbRunsExtracted +1
			push!(runs, run)
		end
	end
	println("Extracted $(nbRunsExtracted) runs")

	return runs
end

function ExtractSpecificData(dir::String, attr::String, value::Int64) 
	#fills an array of Run_t objects, each object contains the data of the run : 
	#wich dimension, which problem, which seed, which strategy, which number of 2n blocks
	#all files are of the format run_dim_pbNumber_pbSeed_pollStrategy_nbOf2nBlocks_.txt
	# all problems are scalable (dim \in N^*)
	#there are 24 problems (pbNumber \in [[1;24]])
	#pbSeed \in N
	#pollStrategy \in [[1;4]] 
	#	1:classic poll
	#	2:multi poll
	#	3:oignon poll
	#	4:enriched poll
	absolutePath = GetAbsolutePath()
	dir = absolutePath*dir
	runsList = readdir(dir)
	runs = Array{Run_t,1}([])

	InterestingAttribute = 0
	if attr == "DIM"
		InterestingAttribute = 2
	elseif attr == "PB_NUM"
		InterestingAttribute = 3
	elseif attr == "PB_SEED"
		InterestingAttribute = 4
	elseif attr == "POLL_STRATEGY"
		InterestingAttribute = 5
	elseif attr == "NB_2N_BLOCK"
		InterestingAttribute = 6
	elseif attr == ""
		return ExtractData(dir)
	else
		println("unknown attribute : $(attr), returning empty array of runs")
		return runs
	end
	nbRunsExtracted = 0
	for runName in runsList
		runAttr=split(runName, "_")
		if runAttr[1]=="run" && parse(Int,runAttr[InterestingAttribute]) == value #we only try to read run files
			nbRunsExtracted = nbRunsExtracted +1
			runData = readdlm(dir*"/"*runName)
			
			run=Run_t(
			parse(Int,runAttr[2]),
			parse(Int,runAttr[3]),
			parse(Int,runAttr[4]),
			parse(Int,runAttr[5]),
			parse(Int,runAttr[6]),
			runData[:,1],
			runData[:,2],
			runData[:,3],
			runData[:,4])
			
			push!(runs, run)
		end
	end
	println("Extracted $(nbRunsExtracted) runs")
	return runs
end


#### functions for managing runs

function ExcludeProblems(pbNum::Array{Int64,1},runs::Array{Run_t,1} )
	newRuns = Array{Run_t,1}([])

	for run in runs
		addRun = true 
		for pn in pbNum
			if run.pb_num == pn 
				addRun = false
				break
			end
		end
		if addRun
			push!(newRuns, run)
		end
	end
	return newRuns
end

function ExcludeDims(dims::Array{Int64,1},runs::Array{Run_t,1} )
	newRuns = Array{Run_t,1}([])

	for run in runs
		addRun = true 
		for dim in dims
			if run.dim == dim 
				addRun = false
				break
			end
		end
		if addRun
			push!(newRuns, run)
		end
	end
	return newRuns
end

function ExcludePollStrategies(pollStrategies::Array{Int64,1},runs::Array{Run_t,1})
	newRuns = Array{Run_t,1}([])

	for run in runs
		addRun = true 
		for ps in pollStrategies
			if run.poll_strategy == ps 
				addRun = false
				break
			end
		end
		if addRun
			push!(newRuns, run)
		end
	end
	return newRuns
end

function FilterRuns(att::String, value::Int64, runs::Array{Run_t,1})
	newRuns = Array{Run_t,1}([])
	if att == "DIM"
		for run in runs
			if run.dim == value
				push!(newRuns, run)
			end
		end
	elseif att == "PB_NUM"
		for run in runs
			if run.pb_num >= value
				push!(newRuns, run)
			end
		end
	elseif att == "PB_SEED"
		for run in runs
			if run.pb_seed == value
				push!(newRuns, run)
			end
		end
	elseif att == "POLL_STRATEGY"
		for run in runs
			if run.poll_strategy == value
				push!(newRuns, run)
			end
		end
	elseif att == "NB_2N_BLOCK"
		for run in runs
			if run.nb_2n_blocks == value
				push!(newRuns, run)
			end
		end
	else 
		println("attribute $attr unknown, returning not filtered runs")
		return runs
	end
	return newRuns
end

function NormalizeRun(runs::Array{Run_t,1})
	for run in runs
		#fmax = run.eval_f[1]
		for i in 1:size(run.eval_f)[1]
			run.eval_f[i] = run.eval_f[i]+1
			#run.eval_nb[i] = run.eval_nb[i]/(run.nb_2n_blocks*2*run.dim)
		end
	end
	return runs
end
