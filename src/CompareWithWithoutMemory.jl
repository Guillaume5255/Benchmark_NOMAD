include("plotProfile.jl")

#here we aim to draw the effect of the memory on runs. We compare dynamic runs without memory, dynamic runs with memory, static runs, and the classical poll. 
# All the runs are made with linear intensification.

#specific function to prepare the data for comparing static and dynamic strategies
function Preprocess(nb2nBlock::Int64)
	#directories for dynamic and static runs (only oignon and enriched)
	dirClassicRun = "/run-pc-perso-confinement/run-pb-test/classical-poll"
	dirDynamicWoMemRun = "/run-pc-perso-confinement/run-pb-test/dynamic/without-memory/lin" 
	dirDynamicWMemRun = "/run-pc-perso-confinement/run-pb-test/dynamic/with-memory/lin" 
	dirStaticRun = "/run-pc-perso-confinement/run-pb-test/static"

	classicRuns = ExtractData(dirClassicRun)
	dynamicWoMemoryRunsAllDims = ExtractData(dirDynamicWoMemRun)
	dynamicWMemoryRunsAllDims = ExtractData(dirDynamicWMemRun)
	staticRunsAllDims = ExtractData(dirStaticRun)


    staticRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,staticRunsAllDims)
	dynamicWoMemoryRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,dynamicWoMemoryRunsAllDims)
	dynamicWMemoryRunsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,dynamicWMemoryRunsAllDims)

	#changing the way n_p^k is increased or decreased changes the solver so the 
	for run in staticRunsAllDims 
		run.poll_strategy = run.poll_strategy-1
	end

	for run in dynamicWoMemoryRunsAllDims 
		run.poll_strategy = run.poll_strategy+1
	end

	for run in dynamicWMemoryRunsAllDims 
		run.poll_strategy = run.poll_strategy+3
	end

	allRuns = [classicRuns; staticRunsAllDims; dynamicWoMemoryRunsAllDims; dynamicWMemoryRunsAllDims]
	allRuns = ExcludeDims([32, 64],allRuns)
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
			alphaStepArray = [1.0, 1.0, 1.0, 1.0, 1.0]
			alphaMaxArray = [25.0, 25.0, 25.0, 25.0, 25.0]
			kappaStepArray = [0.5, 0.5, 0.5, 1.0, 1.0]
			kappaMaxArray = [35.0, 70.0, 100.0, 150.0, 200.0]
		end
		if tau == 0.001
			alphaStepArray = [0.1, 0.1, 0.1, 0.1, 0.1]
			alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
			kappaStepArray = [0.5, 0.5, 1.0, 1.0, 1.0]
			kappaMaxArray = [50.0, 75.0, 100.0, 150.0, 200.0]
		end
	end
	if attr == "TIME"
		if tau == 0.01
			alphaStepArray = [0.1, 0.2, 0.2, 0.2, 0.2]
			alphaMaxArray = [10.0, 20.0, 25.0, 30.0, 30.0]
			kappaStepArray = [0.005, 0.01, 0.01, 0.05, 0.01]
			kappaMaxArray = [0.25, 0.75, 1.2, 4.0, 2.0]
		end
		if tau == 0.001
			alphaStepArray = [0.1, 0.2, 0.2, 0.2, 0.2]
			alphaMaxArray = [10.0, 25.0, 25.0, 50.0, 50.0]
			kappaStepArray = [1.0, 5.0, 10.0, 10.0, 10.0]
			kappaMaxArray = [300.0, 5000.0, 7500.0, 10000.0, 10000.0]
		end

	end
	i = Int(log2(dim))
	return alphaStepArray[i], alphaMaxArray[i], kappaStepArray[i], kappaMaxArray[i]
end

#specific function to plot data and performance profile to compare static and dynamic runs
function PlotAll(attr::String, allRuns::Array{Run_t,1})
	tau = 0.001
	outputFolder = "/plots/pb-test/withVSwithoutMemory/profiles/$(attr)"
	AlgoNames = ["Classique", "Oignon statique", "Enrichie statique", "Oignon dynamique wo. mem.", "Enrichie dynamique wo. mem.",  "Oignon dynamique wo. mem.", "Enrichie dynamique wo. mem."]
	AlgoColors = [:black, :grey, :blue, :red, :orange, :green, :brown]
	dims = [2, 4, 8, 16]# GetDims(allRuns)

	nb2nBlock = allRuns[end].nb_2n_blocks #except for the classical poll, all other runs have the same number of 2n block 
	for n in dims 
		runs = FilterRuns("DIM", Int(n),allRuns)

		outputName = "dim_$(n)_tau_$(tau)"
		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(nb2nBlock) \\times 2n \$"
		
		alphaStep, alphaMax, kappaStep, kappaMax = SetAlphaKappa(attr,nb2nBlock, n, tau)


		PlotProfile(attr, tau, runs, alphaStep, alphaMax, kappaStep, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end
end