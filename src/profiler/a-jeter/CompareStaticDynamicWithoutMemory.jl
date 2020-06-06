include("plotProfile.jl")

#In this section we aim to look at the influence of dynamisme without memory on the optimization

#specific function to prepare the data for comparing static and dynamic strategies
function Preprocess(nb2nBlock::Int64)
	#directories for dynamic and static runs (only oignon and enriched)
	dirClassicRun = "/run-pc-perso-confinement/run-pb-test/classical-poll"
	dirDynamicLinRun = "/run-pc-perso-confinement/run-pb-test/dynamic/without-memory/lin" 
	dirDynamicExpRun = "/run-pc-perso-confinement/run-pb-test/dynamic/without-memory/exp" 
	dirStaticRun = "/run-pc-perso-confinement/run-pb-test/static"

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
	alphaMaxArray = []
	kappaMaxArray = []

	
	if nb2nBlock == 8
		if attr == "EVAL"
			if tau == 0.01
				alphaMaxArray = [10.0, 20.0, 25.0, 30.0, 30.0]
				kappaMaxArray = [200.0, 1000.0, 2000.0, 5000.0, 10000.0]
			end
			if tau == 0.0001
				alphaMaxArray = [10.0, 25.0, 25.0, 50.0, 50.0]
				kappaMaxArray = [300.0, 5000.0, 7500.0, 10000.0, 10000.0]
			end
	
		end
		if attr == "ITER"
			if tau == 0.01
				alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
				kappaMaxArray = [25.0, 25.0, 30.0, 30.0, 30.0]
			end
			if tau == 0.0001
				alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
				kappaMaxArray = [25.0, 25.0, 30.0, 30.0, 30.0]
			end
		end
	end
	if nb2nBlock == 64
		if attr == "EVAL"
			if tau == 0.01
				alphaMaxArray = [80.0, 100.0, 100.0, 100.0, 200.0]
				kappaMaxArray = [400.0, 1000.0, 2000.0, 5000.0, 10000.0]*4
			end
			if tau == 0.0001
				alphaMaxArray = [80.0, 100.0, 100.0, 100.0, 200.0]
				kappaMaxArray = [400.0, 1000.0, 2000.0, 5000.0, 10000.0]*4
			end
	
		end
		if attr == "ITER"
			if tau == 0.01
				alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
				kappaMaxArray = [25.0, 25.0, 30.0, 30.0, 30.0]
			end
			if tau == 0.0001
				alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
				kappaMaxArray = [25.0, 25.0, 30.0, 30.0, 30.0]
			end
		end
	end
	i = Int(log2(dim))
	return alphaMaxArray[i], kappaMaxArray[i]
end

#specific function to plot data and performance profile to compare static and dynamic runs
function Benchmarker(attr::String, allRuns::Array{Run_t,1})
	tau = 0.0001
	outputFolder = "/plots/pb-test/dynamicVSstatic/profiles/$(attr)"
	AlgoNames = ["Oignon statique", "Enrichie statique", "Oignon dynamique lin.", "Enrichie dynamique lin.", "Classique"]#, "Oignon dynamique exp.", "Oignon dynamique exp."] 
	AlgoColors = [:grey, :blue, :red, :yellow, :black]
	dims = GetDims(allRuns)

	nb2nBlock = allRuns[1].nb_2n_blocks #except for the classical poll, all other runs have the same number of 2n block 
	for n in dims 
		runs = FilterRuns("DIM", Int(n),allRuns)

		outputName = "dim_$(n)_tau_$(tau)_n_max_$(nb2nBlock)"
		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(nb2nBlock) \\times 2n \$"
		
		alphaMax, kappaMax = SetAlphaKappa(attr,nb2nBlock, n, tau)


		PlotProfile(attr, tau, runs, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end
end
