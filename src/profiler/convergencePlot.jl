include("core/plotProfile.jl")

#determinismType = "/deterministic" "/nondeterministic"
#features = "/only-poll" "/all-features-enabled"
function Preprocess(determinismType::String,features::String)
	runsDir = "/run-pc-perso-confinement/run-styrene"*determinismType*features
	println("Extracting data from $runsDir")
	#we take the case of only classical poll as reference
	ClassicalPoll = ExtractData("/run-pc-perso-confinement/run-styrene"*determinismType*"/only-poll/classical-poll")
	Static = ExtractSpecificData(runsDir*"/static","NB_2N_BLOCK", 64)
	DynamicWithoutMemLin = ExtractData(runsDir*"/dynamic/sans-mem/lin")
	DynamicWithoutMemExp = ExtractData(runsDir*"/dynamic/sans-mem/exp")
	DynamicWitMemLin = ExtractData(runsDir*"/dynamic/avec-mem/lin")
	DynamicWitMemExp = ExtractData(runsDir*"/dynamic/avec-mem/exp")
	
	ClassicalPoll = FilterRuns("PB_SEED", 0, ClassicalPoll)
	Static = FilterRuns("PB_SEED", 0, Static)
	DynamicWithoutMemLin = FilterRuns("PB_SEED", 0, DynamicWithoutMemLin)
	DynamicWithoutMemExp = FilterRuns("PB_SEED", 0, DynamicWithoutMemExp)
	DynamicWitMemLin = FilterRuns("PB_SEED", 0, DynamicWitMemLin)
	DynamicWitMemExp = FilterRuns("PB_SEED", 0, DynamicWitMemExp)
	
	Oignon = copy(ClassicalPoll)
	Enriched = copy(ClassicalPoll)
	for tempRun in Static
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 2
			push!(Oignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 2
			push!(Enriched,run)
		end
	end
	for tempRun in DynamicWithoutMemLin
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 3
			push!(Oignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 3
			push!(Enriched,run)
		end
	end
	for tempRun in DynamicWithoutMemExp
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 4
			push!(Oignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 4
			push!(Enriched,run)
		end
	end
	for tempRun in DynamicWitMemLin
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 5
			push!(Oignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 5
			push!(Enriched,run)
		end
	end
	for tempRun in DynamicWitMemExp
		run = copy(tempRun)
		if tempRun.poll_strategy == 3
			run.poll_strategy = 6
			push!(Oignon,run)
		end
		if tempRun.poll_strategy == 4
			run.poll_strategy = 6
			push!(Enriched,run)
		end
	end
	return [Oignon, Enriched]
end



function benchmarker(runs::Array{Run_t,1},pollStr::String,attr::String,feature::String)

	Title = "STYRENE : \$n = 8, n_p^{max} = 64 \\times 2n\$"
	outputFolder = "/plots/pb-bb-styrene/intensificationInfluence/convergence/$(attr)"
	outputName = "$(feature)_$(pollStr)_$(attr)"
	#list of algoriths used in profiles, the order is important :
	#AlgoNames[i] will be the name of the algoritm with poll strategy i (set in Preprocess ()) 
	AlgoNames = ["Classique",
			"$(pollStr) statique",
			"$(pollStr) sans mem. lin.",
			"$(pollStr) sans mem. exp.",
			"$(pollStr) avec mem. lin.",
			"$(pollStr) avec mem. exp."]
	#colors of the profiles
	AlgoColors = [:black, :gray80, :royalblue1, :blue3, :green, :gold]
	ConvergencePlot(attr,runs,AlgoNames,AlgoColors,outputFolder, outputName, Title )
end

function plotAllProfiles()
	featureNames = ["onlyPoll", "allEnabled"]
	featureDirs = ["/only-poll", "/all-features-enabled"]
	determinismType = "/deterministic" #"/deterministic"# 
	strategies = ["Oignon","Enrichie"]
	for featureType in [1, 2]
		runs = Preprocess(determinismType,featureDirs[featureType])# array of arrays of runs : Preprocess(...) = [Oignon, Enriched]
		for attr in ["EVAL","ITER","TIME"]
			for runType in [1,2]
				benchmarker(runs[runType], strategies[runType], attr, featureNames[featureType])
			end
		end

	end

end

