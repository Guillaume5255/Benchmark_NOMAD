include("core/plotProfile.jl")
# : comparaison des contextes de la section : Influence du nombre de points sur la valeur optimale

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
	
	#ClassicalPoll = FilterRuns("PB_SEED", 0, ClassicalPoll)
	#Static = FilterRuns("PB_SEED", 0, Static)
	#DynamicWithoutMemLin = FilterRuns("PB_SEED", 0, DynamicWithoutMemLin)
	#DynamicWithoutMemExp = FilterRuns("PB_SEED", 0, DynamicWithoutMemExp)
	#DynamicWitMemLin = FilterRuns("PB_SEED", 0, DynamicWitMemLin)
	#DynamicWitMemExp = FilterRuns("PB_SEED", 0, DynamicWitMemExp)
	
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
	SetRealPbNumberStyrene(Oignon)
	SetRealPbNumberStyrene(Enriched)
	return [Oignon, Enriched]
end

function SetAlphaKappa(attr::String, nb2nBlock::Int, dim::Int, tau::Float64)
	alphaMax=0
	kappaMax=0
	if attr == "EVAL"
		if tau == 0.1
			alphaMax=30.0
			kappaMax=4000.0
		end
		if tau == 0.01
			alphaMax=30.0
			kappaMax=4000.0
		end

	end
	if attr == "ITER"
		if tau == 0.1
			alphaMax=12.0
			kappaMax=250.0
		end
		if tau == 0.01
			alphaMax=12.0
			kappaMax=250.0
		end
	end
	return alphaMax, kappaMax
end

function Benchmarker(tau::Float64, attr::String, runs::Array{Run_t,1}, pollStr::String, feature::String)
	
	n = 8 #dimension for STYRENE
	npmax=64
	Title = "STYRENE : \$n = 8, \\tau = $(tau), n_p^{max} = $(npmax) \\times 2n\$"
	outputFolder = "/plots/pb-bb-styrene/intensificationInfluence/profils/$(attr)"
	outputName = "$(feature)_$(pollStr)_$(attr)_tau_$(tau)"
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

	alphaMax, kappaMax = SetAlphaKappa(attr,npmax, n, tau)

	PlotProfile(attr, tau, runs, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)

end

function plotAllProfiles()
	featureNames = ["onlyPoll", "allEnabled"]
	featureDirs = ["/only-poll", "/all-features-enabled"]
	determinismType = "/deterministic" #"/deterministic"#
	strategies = ["Oignon","Enrichie"]
	
	for featureType in [1, 2]
		runs = Preprocess(determinismType,featureDirs[featureType])# array of arrays of runs : Preprocess(...) = [Oignon, Enriched]
		for tau in [0.1, 0.01]
			for attr in ["EVAL","ITER"]
				for runType in [1,2]
					Benchmarker(tau, attr, runs[runType], strategies[runType], featureNames[featureType])
				end
			end
		end
	end

end
