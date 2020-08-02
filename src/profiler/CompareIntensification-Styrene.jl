include("core/plotProfile.jl")
# : comparaison des contextes de la section : Influence du nombre de points sur la valeur optimale

#determinismType = "/deterministic" "/nondeterministic"
#features = "/only-poll" "/all-features-enabled"
function Preprocess(determinismType::String,features::String)
	runsDir = ROOT_RUN_DIR*"/run-styrene"*determinismType*features
	println("Extracting data from $runsDir")
	#we take the case of only classical poll as reference
	ClassicalPoll = ExtractData(ROOT_RUN_DIR*"/run-styrene"*determinismType*"/only-poll/classical-poll")
	SetRealPbNumberStyrene(ClassicalPoll)

	Static = ExtractSpecificData(runsDir*"/static","NB_2N_BLOCK", 64)
	SetRealPbNumberStyrene(Static)
	DynamicWithoutMemLin = ExtractData(runsDir*"/dynamic/sans-mem/lin")
	SetRealPbNumberStyrene(DynamicWithoutMemLin)
	DynamicWithoutMemExp = ExtractData(runsDir*"/dynamic/sans-mem/exp")
	SetRealPbNumberStyrene(DynamicWithoutMemExp)
	DynamicWitMemLin = ExtractData(runsDir*"/dynamic/avec-mem/lin")
	SetRealPbNumberStyrene(DynamicWitMemLin)
	DynamicWitMemExp = ExtractData(runsDir*"/dynamic/avec-mem/exp")
	SetRealPbNumberStyrene(DynamicWitMemExp)
	
	Oignon = Array{Run_t,1}([])
	Enriched = Array{Run_t,1}([])
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
	Oignon = [ClassicalPoll; Oignon]
	Enriched = [ClassicalPoll; Enriched]
	return [Oignon, Enriched]
end

function SetAlphaKappa(attr::String, tau::Float64)
	alphaMax=0
	kappaMax=0
	if attr == "EVAL"
		if tau == 0.1
			alphaMax=30.0
			kappaMax=4000.0
		end
		if tau == 0.01
			alphaMax=30.0
			kappaMax=8000.0
		end

	end
	if attr == "ITER"
		if tau == 0.1
			alphaMax=12.0
			kappaMax=250.0
		end
		if tau == 0.01
			alphaMax=12.0
			kappaMax=300.0
		end
	end
	return alphaMax, kappaMax
end

function Benchmarker(tau::Float64, attr::String, runs::Array{Run_t,1}, pollStr::String, feature::String)
	
	n = 8 #dimension for STYRENE
	npmax=64
	Title = "\\texttt{STYRENE} : \$n = 8, \\tau = $(tau), n_p^{max} = $(npmax) \\times 2n\$"
	outputFolder = "/plots/pb-bb-styrene/intensificationInfluence/profils/$(attr)"
	pollStrName = ""
	if pollStr == "Oignon" || pollStr == "Onion"
		pollStrName = "Oignon"
	end
	if pollStr == "Enrichie" || pollStr == "Enriched"
		pollStrName = "Enrichie"
	end	
	outputName = "$(feature)_$(pollStrName)_$(attr)_tau_$(tau)"
	#list of algoriths used in profiles, the order is important :
	#AlgoNames[i] is the name of the algoritm with poll strategy i, set in Preprocess () 
	AlgoNames = ["Classic",
			"$(pollStr) static",
			"$(pollStr) wo. mem. lin.",
			"$(pollStr) wo. mem. exp.",
			"$(pollStr) w. mem. lin.",
			"$(pollStr) w. mem. exp."]
	#colors of the profiles
	AlgoColors = [:black, :gray80, :royalblue1, :blue3, :green, :gold]

	alphaMax, kappaMax = SetAlphaKappa(attr, tau)

	PlotProfile(attr, tau, runs, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)

end

function plotAllProfiles()
	featureNames = ["onlyPoll", "allEnabled"]#, "s+o", "search+poll"]
	featureDirs = ["/only-poll", "/all-features-enabled"]#, "/searches-opportunism", "/wo-opportunism"]
	determinismType = "/deterministic" #"/deterministic"#
	strategies = ["Onion", "Enriched"]
	
	for featureType in [1, 2]#, 3, 4]
		runs = Preprocess(determinismType,featureDirs[featureType])# array of arrays of runs : Preprocess(...) = [Oignon, Enriched]
		for tau in [0.1]#, 0.01]
			for attr in ["EVAL","ITER"]
				for runType in [1,2]
					Benchmarker(tau, attr, runs[runType], strategies[runType], featureNames[featureType])
				end
			end
		end
	end

end
