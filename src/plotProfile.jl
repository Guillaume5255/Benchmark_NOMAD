include("data-perf-profile.jl")

using Plots
pgfplots()
#gr()
#gadfly()
#pyplot()

using LaTeXStrings


function GetProblemsDimension(runs::Array{Run_t, 1},nbProblems::Int64) #returns an array a where a[i] is the dimension of ith problem
    problemDimension = zeros(1,nbProblems)
    for run in runs
        problemDimension[run.pb_num]=run.dim
    end
    return problemDimension
end

#generic function that plots the profiles made on some runs in a specific window 
function PlotProfile(attr::String, tau::Float64, runs::Array{Run_t,1}, alphaStep::Float64, alphaMax::Float64, kappaStep::Float64, kappaMax::Float64, algoNames::Array{String, 1}, algoColors::Array{Symbol, 1}, outputFolder::String, outputName::String, Title::String)

	tps_matrix = tpsMatrix(tau,runs,attr)
    rps_matrix = rpsMatrix(tps_matrix) 
    nbProblems = size(tps_matrix)[1]

    problemsDimensions = GetProblemsDimension(runs,nbProblems)
	normalized_tps_matrix = copy(tps_matrix)
    for p in 1:nbProblems
        normalized_tps_matrix[p,:] = normalized_tps_matrix[p,:]/problemsDimensions[p] #to modify, dimension is not the same for each problem
    end

	alphaPP = 0.0:alphaStep:alphaMax
	kappaDP = 0.0:kappaStep:kappaMax
    
    legendPos = :bottomright
	PPplot = plot(dpi=300)
	DPplot = plot(dpi=300)

	for s in 1:size(algoNames)[1]

		PPValue =  [PerformanceProfile(alpha, s, rps_matrix) for alpha in alphaPP]
		DPValue =  [DataProfile(kappa, s, normalized_tps_matrix) for kappa in kappaDP]

		PPplot = plot!(PPplot,alphaPP, PPValue, color=algoColors[s], label = algoNames[s], legend=legendPos, linetype=:steppre)
		DPplot = plot!(DPplot,kappaDP, DPValue, color=algoColors[s], label = algoNames[s], legend=legendPos, linetype=:steppre)

	end

	xlabel!(PPplot,"\$\\alpha\$")
	xlabel!(DPplot,"\$\\kappa\$")

	ylabel!(PPplot,"proportion de problemes resolus")
	ylabel!(DPplot,"proportion de problemes resolus")

	title!(PPplot,Title)
	title!(DPplot,Title)

	println("saving in $(outputFolder)")

	cd(outputFolder)
	savefig(PPplot,"pp_"*outputName*".svg")
    savefig(DPplot,"dp_"*outputName*".svg")
    
	tree =  split(outputFolder,"/")
	backToSrc=""
	for i in 1:(size(tree)[1]-1)
		backToSrc = backToSrc*"../"
	end
	backToSrc = backToSrc*"src"
    cd(backToSrc)

	println("done")
end

#get a list of dimensions used in the runs
function GetDims(runs::Array{Run_t,1})
	maxDim=1
	for run in runs
		if maxDim < run.dim
			maxDim = run.dim
		end
	end

	allDims = zeros(1,maxDim)
	for run in runs
		allDims[run.dim]=run.dim
	end

	dims = []
	for dim in allDims
		if dim > 0
			push!(dims, dim)
		end
	end
	return dims
end

#specific function to prepare the data for comparing static and dynamic strategies
function PreprocessRunsStaticDynamic(nb2nBlock::Int64)
	#directories for dynamic and static runs (only oignon and enriched)
	dirDynamicLinRun = "../run-pc-perso-confinement/run-pb-test-dynamic" #to change to "../run-pc-perso-confinement/run-pb-test/dynamic/exp"
	dirDynamicExpRun = "../run-pc-perso-confinement/run-pb-test/dynamic/exp" 
	dirStaticRun = "../run-pc-perso-confinement/run-pb-test-static"

	staticRunsAllDims = ExtractData(dirStaticRun)
	dynamicLinRunsAllDims = ExtractData(dirDynamicLinRun)
	dynamicExpRunsAllDims = ExtractData(dirDynamicExpRun)

    nbProblems = 24
    
    staticRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,staticRunsAllDims)
	dynamicLinRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,dynamicLinRunsAllDims)
	dynamicExpRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,dynamicExpRunsAllDims)

	for run in staticRunsAllDims #poll strategies are the solvers, changing static to dynamic changes the solver so we put this information in run.poll_strategy
		# : run.poll_strategy < 3 : static else dynamic 
		run.poll_strategy = run.poll_strategy-2

		run.pb_num = nbProblems*(run.pb_seed) + run.pb_num #computing real pb number with seed 
	end

	for run in dynamicLinRunsAllDims
		run.pb_num = nbProblems*(run.pb_seed) + run.pb_num #computing real pb number with seed 
	end

	for run in dynamicExpRunsAllDims #poll strategies are the solvers, changing static to dynamic changes the solver so we put this information in run.poll_strategy
		# : run.poll_strategy < 3 : static else dynamic 
		run.poll_strategy = run.poll_strategy+2

		run.pb_num = nbProblems*(run.pb_seed) + run.pb_num #computing real pb number with seed 
	end

	allRuns = [staticRunsAllDims; dynamicLinRunsAllDims; dynamicExpRunsAllDims]
	allRuns = ExcludeDims([64],allRuns)

	return allRuns
end

function CompareStaticDynamic(attr::String, allRuns::Array{Run_t,1})
	tau = 0.001
	outputFolder = "../plots/pb-test/dynamicVSstatic/profiles/$(attr)"
	AlgoNames = ["Oignon statique", "Enrichie statique", "Oignon dynamique lin.", "Enrichie dynamique lin."]#, "Oignon dynamique exp.", "Oignon dynamique exp."] 
	AlgoColors = [:grey, :blue, :red, :yellow]
	dims = GetDims(allRuns)

	nb2nBlock = 8
	for n in dims 
		runs = FilterRuns("DIM", n)
		outputName = "dim_$(n)_tau_$(tau)_attr_$(attr)"
		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(nb2nBlock)\$"
		alphaStep = 0.5
		alphaMax = 1000.0
		kappaStep = 0.5
		kappaMax = 1000.0
		PlotProfile(attr, tau, runs, alphaStep, alphaMax, kappaStep, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end
end





function PreprocessAllStaticRuns()
	AllStaticRunsDir = "../run-pb-test/allStaticRuns"
	AllStaticRuns =  ExtractData(AllStaticRunsDir)
	return AllStaticRuns
end

function CompareAllStatic(attr::String, allRuns::Array{Run_t,1})


end