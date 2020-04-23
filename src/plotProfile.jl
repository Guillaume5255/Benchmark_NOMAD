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


	normalized_tps_matrix = copy(tps_matrix)

	# this step is used in data profile in the case where we look at how behaves algorithms in term of evaluation,  it has no sens when we are interested by profiles in iteration or in time 
	if attr == "EVAL"
		problemsDimensions = GetProblemsDimension(runs,nbProblems)
		for p in 1:nbProblems
			normalized_tps_matrix[p,:] = normalized_tps_matrix[p,:]/problemsDimensions[p] #to modify, dimension is not the same for each problem
		end
	end

	alphaPP = 0.9:alphaStep:alphaMax
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

	xlabel!(PPplot,"\$\\alpha ($attr) \$")
	xlabel!(DPplot,"\$\\kappa ($attr) \$")

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
			push!(dims, Int(dim))
		end
	end
	return dims
end

function SetRealPbNumber(runs::Array{Run_t,1})
	realNbProblems = 24
	for run in runs
		run.pb_num = realNbProblems*(run.pb_seed) + run.pb_num
	end
end



#specific function to prepare the data for comparing static and dynamic strategies
function PreprocessRunsStaticDynamic(nb2nBlock::Int64)
	#directories for dynamic and static runs (only oignon and enriched)
	dirClassicRun = "../run-pc-perso-confinement/run-pb-test/classical-poll"
	dirDynamicLinRun = "../run-pc-perso-confinement/run-pb-test/dynamic/lin" 
	dirDynamicExpRun = "../run-pc-perso-confinement/run-pb-test/dynamic/exp" 
	dirStaticRun = "../run-pc-perso-confinement/run-pb-test/static"

	classicRuns = ExtractData(dirClassicRun)
	staticRunsAllDims = ExtractData(dirStaticRun)
	dynamicLinRunsAllDims = ExtractData(dirDynamicLinRun)
	dynamicExpRunsAllDims = ExtractData(dirDynamicExpRun)


    staticRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,staticRunsAllDims)
	dynamicLinRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,dynamicLinRunsAllDims)
	dynamicExpRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,dynamicExpRunsAllDims)

	for run in staticRunsAllDims #poll strategies are the solvers, changing static to dynamic changes the solver so we put this information in run.poll_strategy
		# : run.poll_strategy < 3 : static else dynamic 
		run.poll_strategy = run.poll_strategy-2
	end

	for run in dynamicExpRunsAllDims #poll strategies are the solvers, changing static to dynamic changes the solver so we put this information in run.poll_strategy
		# : run.poll_strategy < 3 : static else dynamic 
		run.poll_strategy = run.poll_strategy+2
	end

	for run in classicRuns #poll strategies are the solvers, changing static to dynamic changes the solver so we put this information in run.poll_strategy
		# : run.poll_strategy < 3 : static else dynamic 
		run.poll_strategy = 5
	end

	allRuns = [staticRunsAllDims; dynamicLinRunsAllDims; dynamicExpRunsAllDims; classicRuns]
	allRuns = ExcludeDims([64],allRuns)
	SetRealPbNumber(allRuns) 
	return allRuns
end
function SetAlphaKappa(attr::String, nb2nBlock::Int, dim::Int, tau::Float64)
	alphaStepArray = [] #pp
	alphaMaxArray = []
	kappaStepArray = [] #dp
	kappaMaxArray = []

	if attr == "EVAL"
		if tau == 0.01
			alphaStepArray = [0.1, 0.2, 0.2, 0.2, 0.2]
			alphaMaxArray = [10.0, 20.0, 25.0, 30.0, 30.0]
			kappaStepArray = [1.0, 5.0, 10.0, 10.0, 10.0]
			kappaMaxArray = [200.0, 1000.0, 2000.0, 5000.0, 10000.0]
		end
		if tau == 0.001
			alphaStepArray = [0.1, 0.2, 0.2, 0.2, 0.2]
			alphaMaxArray = [10.0, 25.0, 25.0, 50.0, 50.0]
			kappaStepArray = [1.0, 5.0, 10.0, 10.0, 10.0]
			kappaMaxArray = [300.0, 5000.0, 7500.0, 10000.0, 10000.0]
		end

	end
	if attr == "ITER"
		if tau == 0.01
			alphaStepArray = [0.1, 0.1, 0.1, 0.1, 0.1]
			alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
			kappaStepArray = [0.2, 0.2, 0.2, 0.2, 0.2]
			kappaMaxArray = [25.0, 25.0, 30.0, 30.0, 30.0]
		end
		if tau == 0.001
			alphaStepArray = [0.1, 0.1, 0.1, 0.1, 0.1]
			alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
			kappaStepArray = [0.2, 0.2, 0.2, 0.2, 0.2]
			kappaMaxArray = [25.0, 25.0, 30.0, 30.0, 30.0]
		end
	end
	i = Int(log2(dim))
	return alphaStepArray[i], alphaMaxArray[i], kappaStepArray[i], kappaMaxArray[i]
end

#specific function to plot data and performance profile to compare static and dynamic runs
function CompareStaticDynamic(attr::String, allRuns::Array{Run_t,1})
	tau = 0.01
	outputFolder = "../plots/pb-test/dynamicVSstatic/profiles/$(attr)"
	AlgoNames = ["Oignon statique", "Enrichie statique", "Oignon dynamique lin.", "Enrichie dynamique lin.", "Classique"]#, "Oignon dynamique exp.", "Oignon dynamique exp."] 
	AlgoColors = [:grey, :blue, :red, :yellow, :black]
	dims = GetDims(allRuns)

	nb2nBlock = allRuns[1].nb_2n_blocks #except for the classical poll, all other runs have the same number of 2n block 
	for n in dims 
		runs = FilterRuns("DIM", Int(n),allRuns)

		outputName = "dim_$(n)_tau_$(tau)"
		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(nb2nBlock) \\times 2n \$"
		
		alphaStep, alphaMax, kappaStep, kappaMax = SetAlphaKappa(attr,nb2nBlock, n, tau)


		PlotProfile(attr, tau, runs, alphaStep, alphaMax, kappaStep, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end
end





function PreprocessAllStaticRuns()
	dirClassicRun = "../run-pc-perso-confinement/run-pb-test/classical-poll"
	dirOtherRun = "../run-pc-perso-confinement/run-pb-test/compareGeometry"

	otherStaticRuns =  ExtractData(dirOtherRun)
	classicRun = ExtractData(dirClassicRun)
	SetRealPbNumber(classicRun)
	SetRealPbNumber(otherStaticRuns)
	return [classicRun; otherStaticRuns]
end

function SetAlphaKappaAllStatic(attr::String, dim::Int, tau::Float64)
	alphaStepArray = [] #pp
	alphaMaxArray = []
	kappaStepArray = [] #dp
	kappaMaxArray = []

	if attr == "EVAL"
		if tau == 0.01
			alphaStepArray = [0.1, 0.2, 0.2, 0.2]
			alphaMaxArray = [10.0, 20.0, 25.0, 50.0 ]
			kappaStepArray = [1.0, 5.0, 10.0, 10.0]
			kappaMaxArray = [200.0, 1000.0, 2000.0, 10000.0]
		end
		if tau == 0.001
			alphaStepArray = [0.1, 0.2, 0.2, 0.2]
			alphaMaxArray = [10.0, 25.0, 25.0, 50.0 ]
			kappaStepArray = [1.0, 5.0, 10.0, 10.0]
			kappaMaxArray = [300.0, 5000.0, 7500.0, 10000.0]
		end

	end
	if attr == "ITER"
		if tau == 0.01
			alphaStepArray = [0.1, 0.1, 0.1, 0.1]
			alphaMaxArray = [15.0, 15.0, 10.0, 15.0]
			kappaStepArray = [0.2, 0.2, 0.2, 0.2]
			kappaMaxArray = [25.0, 25.0, 30.0, 30.0]
		end
		if tau == 0.001
			alphaStepArray = [0.1, 0.1, 0.1, 0.1]
			alphaMaxArray = [15.0, 15.0, 10.0, 15.0]
			kappaStepArray = [0.2, 0.2, 0.2, 0.2]
			kappaMaxArray = [25.0, 25.0, 30.0, 30.0]
		end
	end
	i = Int(log2(dim))
	return alphaStepArray[i], alphaMaxArray[i], kappaStepArray[i], kappaMaxArray[i]
end

function CompareAllStatic(attr::String, allRuns::Array{Run_t,1})
	tau = 0.01
	outputFolder = "../plots/pb-test/geometryInfluence/profiles/$(attr)"
	AlgoNames = ["Classic", "Multi statique","Oignon statique", "Enrichie statique"]
	AlgoColors = [:black, :blue, :red, :yellow ]
	#dims = GetDims(allRuns)
	dims = [2 4 8 16]
	for n in dims 
		nb2nBlock = 2*n+1 	 #except for the classical poll, all other runs have the same number of 2n block 
		runs = FilterRuns("DIM", Int(n), allRuns)

		outputName = "dim_$(n)_tau_$(tau)"
		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(nb2nBlock) \\times 2n \$"
		
		alphaStep, alphaMax, kappaStep, kappaMax = SetAlphaKappaAllStatic(attr, n, tau)


		PlotProfile(attr, tau, runs, alphaStep, alphaMax, kappaStep, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end

end