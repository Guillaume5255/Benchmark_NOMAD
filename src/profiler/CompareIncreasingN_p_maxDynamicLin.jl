#here we want to plot the influence of increasing n_p^max on the dynamic poll.
#for each dimension, we will compare DynmaicOignonPoll with n_p^max = 2 4 8 16 32 64 with ClassicalPoll
#for each dimension, we will compare DynmaicEnrichedPoll with n_p^max = 2 4 8 16 32 64 with ClassicalPoll
include("plotProfile.jl")


function Preprocess()
	#directories for dynamic and static runs (only oignon and enriched)
	dirClassicRun = "/run-pc-perso-confinement/run-pb-test/classical-poll"
	dirDynamicWoMemRun = "/run-pc-perso-confinement/run-pb-test/dynamic/without-memory/lin" 

	classicRuns = ExtractData(dirClassicRun)
	dynamicWoMemoryRunsAllDims = ExtractData(dirDynamicWoMemRun)
	

	#changing the way n_p^k is increased or decreased changes the solver so the 
	OignonRuns = FilterRuns("POLL_STRATEGY", 3, dynamicWoMemoryRunsAllDims)
	EnrichedRuns = FilterRuns("POLL_STRATEGY", 4, dynamicWoMemoryRunsAllDims)

	for run in OignonRuns 
		run.poll_strategy = Int(log2(run.nb_2n_blocks))+1
	end


	for run in EnrichedRuns 
		run.poll_strategy = Int(log2(run.nb_2n_blocks))+1
	end

	OignonRuns = [classicRuns; OignonRuns]
	EnrichedRuns = [classicRuns; EnrichedRuns]

	SetRealPbNumber(OignonRuns)
	SetRealPbNumber(EnrichedRuns) 
 

	return OignonRuns, EnrichedRuns
end

function SetAlphaKappa(attr::String, dim::Int, tau::Float64)
	alphaMaxArray = []
	kappaMaxArray = []

	if attr == "EVAL"
		if tau == 0.01
			alphaMaxArray = [10.0, 20.0, 25.0, 20.0, 25.0]
			kappaMaxArray = [150.0, 750.0, 2000.0, 2500.0, 2500.0]
		end
		if tau == 0.0001
			alphaMaxArray = [10.0, 25.0, 25.0, 25.0, 25.0 ]
			kappaMaxArray = [300.0, 2000.0, 2000.0, 2500.0, 2500.0]
		end

	end
	if attr == "ITER"
		if tau == 0.01
			alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
			kappaMaxArray = [35.0, 50.0, 100.0, 200.0, 300.0]
		end
		if tau == 0.0001 #0.001
			alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
			kappaMaxArray = [35.0, 50.0, 100.0, 200.0, 300.0]
		end
	end
	i = Int(log2(dim))
	return alphaMaxArray[i], kappaMaxArray[i]
end

#specific function to plot data and performance profile to compare static and dynamic runs
function Benchmarker(attr::String, OignonRuns::Array{Run_t,1}, EnrichedRuns::Array{Run_t,1})
	tau = 0.01
	outputFolderOignon = "/plots/pb-test/n_p_maxIncreaseInfluenceDynamic/Oignon/WithoutMemory/lin/profiles/$(attr)"
	outputFolderEnriched = "/plots/pb-test/n_p_maxIncreaseInfluenceDynamic/Enriched/WithoutMemory/lin/profiles/$(attr)"
	AlgoNames = ["Sonde classique", "\$n_p^{max} = 2\$", "\$n_p^{max} = 4\$", "\$n_p^{max} = 8\$", "\$n_p^{max} = 16\$", "\$n_p^{max} = 32\$", "\$n_p^{max} = 64\$"]
	AlgoColors = [:black, :grey, :blue, :red, :yellow, :green, :brown]
	dims = [2 4 8 16 32]

	for n in dims 
		filteredOignonRuns = FilterRuns("DIM", Int(n),OignonRuns)
		filteredEnrichedRuns = FilterRuns("DIM", Int(n),EnrichedRuns)

		outputName = "dim_$(n)_tau_$(tau)"
		Title = "\$n = $(n), \\tau = $(tau)\$"
		
		alphaMax, kappaMax = SetAlphaKappa(attr, n, tau)

		PlotProfile(attr, tau, filteredOignonRuns, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolderOignon, outputName, Title)
		PlotProfile(attr, tau, filteredEnrichedRuns, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolderEnriched, outputName, Title)

	end
end