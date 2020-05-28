include("plotProfile.jl")

#functions to plot convergence plots on styrene
function Preprocess()
	dirOnlyPoll = "/run-pc-perso-confinement/run-styrene/only-poll"
	dirAllFeatures = "/run-pc-perso-confinement/run-styrene/all-features-enabled"
	
	#each array contains runs from Oignon and Enriched poll made with the specified intensification strategy and enabled features
#op = only poll	: no search enabled during the runs
	println("Extracting data for only poll")
	opClassicalPoll = ExtractData(dirOnlyPoll*"/classical-poll")
	opStatic = ExtractSpecificData(dirOnlyPoll*"/static","NB_2N_BLOCK", 64)
	opDynamicWithoutMemLin = ExtractData(dirOnlyPoll*"/dynamic/sans-mem/lin")
	opDynamicWithoutMemExp = ExtractData(dirOnlyPoll*"/dynamic/sans-mem/exp")
	opDynamicWitMemLin = ExtractData(dirOnlyPoll*"/dynamic/avec-mem/lin")
	opDynamicWitMemExp = ExtractData(dirOnlyPoll*"/dynamic/avec-mem/exp")
	
	opClassicalPoll = FilterRuns("PB_SEED", 0, opClassicalPoll)
	opStatic = FilterRuns("PB_SEED", 0, opStatic)
	opDynamicWithoutMemLin = FilterRuns("PB_SEED", 0, opDynamicWithoutMemLin)
	opDynamicWithoutMemExp = FilterRuns("PB_SEED", 0, opDynamicWithoutMemExp)
	opDynamicWitMemLin = FilterRuns("PB_SEED", 0, opDynamicWitMemLin)
	opDynamicWitMemExp = FilterRuns("PB_SEED", 0, opDynamicWitMemExp)
	
	opOignon = copy(opClassicalPoll)
	opEnriched = copy(opClassicalPoll)
	for tempRun in opStatic
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 2
			push!(opOignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 2
			push!(opEnriched,run)
		end
	end
	for tempRun in opDynamicWithoutMemLin
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 3
			push!(opOignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 3
			push!(opEnriched,run)
		end
	end
	for tempRun in opDynamicWithoutMemExp
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 4
			push!(opOignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 4
			push!(opEnriched,run)
		end
	end
	for tempRun in opDynamicWitMemLin
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 5
			push!(opOignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 5
			push!(opEnriched,run)
		end
	end
	for tempRun in opDynamicWitMemExp
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 6
			push!(opOignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 6
			push!(opEnriched,run)
		end
	end

#af = all features : search, models, anisotropic mesh enabled TODO : work on all features
	println("Extracting data for all features enabled")
	afClassicalPoll = ExtractData(dirAllFeatures*"/classical-poll")
	afStatic = ExtractSpecificData(dirAllFeatures*"/static","NB_2N_BLOCK", 64)
	afDynamicWithoutMemLin = ExtractData(dirAllFeatures*"/dynamic/sans-mem/lin")
	afDynamicWithoutMemExp = ExtractData(dirAllFeatures*"/dynamic/sans-mem/exp")
	afDynamicWitMemLin = ExtractData(dirAllFeatures*"/dynamic/avec-mem/lin")
	afDynamicWitMemExp = ExtractData(dirAllFeatures*"/dynamic/avec-mem/exp")
	
	afClassicalPoll = FilterRuns("PB_SEED", 0, afClassicalPoll)
	afStatic = FilterRuns("PB_SEED", 0, afStatic)
	afDynamicWithoutMemLin = FilterRuns("PB_SEED", 0, afDynamicWithoutMemLin)
	afDynamicWithoutMemExp = FilterRuns("PB_SEED", 0, afDynamicWithoutMemExp)
	afDynamicWitMemLin = FilterRuns("PB_SEED", 0, afDynamicWitMemLin)
	afDynamicWitMemExp = FilterRuns("PB_SEED", 0, afDynamicWitMemExp)


	return opOignon, opEnriched 
end

function benchmarker(runs::Array{Run_t,1},pollStr::String,attr::String,feature::String)

	Title = "STYRENE : \$n = 8, n_p^{max} = 64 \\times 2n\$"
	outputFolder = "/plots/pb-bb-styrene/staticVSDynamic/convergence/$(attr)"
	outputName = "$(feature)_$(pollStr)"
	#list of algoriths used in profiles, the order is important, AlgoName[i] will be the name of the algoritm with poll strategy i (set in Preprocess ()) 
	AlgoNames = ["Classique", "$(pollStr) statique", "$(pollStr) sans mem. lin.", "$(pollStr) sans mem. exp.", "$(pollStr) avec mem. lin.", "$(pollStr) avec mem. exp."]#, "Oignon dynamique exp.", "Oignon dynamique exp."] 
	#colors of the profiles
	AlgoColors = [:black, :gray80, :royalblue1, :blue3, :green, :gold]#Array{Symbol,1}([])
	ConvergencePlot(attr,runs,AlgoNames,AlgoColors,outputFolder, outputName, Title )
end

function plotBenchmark(attr::String)
	Oignon, Enriched = Preprocess()
	println(size(Oignon)[1])
	println(size(Enriched)[1])
	feature = "onlyPoll"
	benchmarker(Oignon, "Oignon", attr, feature)
	benchmarker(Enriched, "Enrichie", attr, feature)

	feature = "allEnabled"


end
