include("core/plotProfile.jl")
# : comparaison des contextes de la section : Influence du nombre de points sur la valeur optimale

function Preprocess()
	#data directories
	dirClassicRuns = "/run-pc-perso-confinement/run-pb-test/classical-poll" 
	dirStaticRuns = "/run-pc-perso-confinement/run-pb-test/static"
	dirDynamicRuns = "/run-pc-perso-confinement/run-pb-test/dynamic" #/without-memory/lin"  
	
	#extracting the runs
	runsClassic = ExtractData(dirClassicRuns)

	oignonRunsStatic = ExtractSpecificData(dirStaticRuns, "POLL_STRATEGY", 3)
	oignonRunsDynamicWithoutMemoryLin = ExtractSpecificData(dirDynamicRuns*"/without-memory/lin", "POLL_STRATEGY", 3)
	oignonRunsDynamicWithoutMemoryExp =  ExtractSpecificData(dirDynamicRuns*"/without-memory/exp", "POLL_STRATEGY", 3)
	oignonRunsDynamicWithMemoryLin =  ExtractSpecificData(dirDynamicRuns*"/with-memory/lin", "POLL_STRATEGY", 3)
	oignonRunsDynamicWithMemoryExp =  ExtractSpecificData(dirDynamicRuns*"/with-memory/exp", "POLL_STRATEGY", 3)

	enrichedRunsStatic = ExtractSpecificData(dirStaticRuns, "POLL_STRATEGY", 4)
	enrichedRunsDynamicWithoutMemoryLin = ExtractSpecificData(dirDynamicRuns*"/without-memory/lin", "POLL_STRATEGY", 4)
	enrichedRunsDynamicWithoutMemoryExp =  ExtractSpecificData(dirDynamicRuns*"/without-memory/exp", "POLL_STRATEGY", 4)
	enrichedRunsDynamicWithMemoryLin =  ExtractSpecificData(dirDynamicRuns*"/with-memory/lin", "POLL_STRATEGY", 4)
	enrichedRunsDynamicWithMemoryExp =  ExtractSpecificData(dirDynamicRuns*"/with-memory/exp", "POLL_STRATEGY", 4)

	#changing the poll strategy number - classic 
	for run in runsClassic
		run.poll_strategy = 1
	end

	#changing the poll strategy number - oignon 
	for run in oignonRunsStatic
		run.poll_strategy = 2
	end

	for run in oignonRunsDynamicWithoutMemoryLin
		run.poll_strategy = 3
	end

	for run in oignonRunsDynamicWithoutMemoryExp
		run.poll_strategy = 4
	end

	for run in oignonRunsDynamicWithMemoryLin
		run.poll_strategy = 5
	end

	for run in oignonRunsDynamicWithMemoryExp
		run.poll_strategy = 6
	end

	#changing the poll strategy number - enriched 
	for run in enrichedRunsStatic
		run.poll_strategy = 2
	end

	for run in enrichedRunsDynamicWithoutMemoryLin
		run.poll_strategy = 3
	end

	for run in enrichedRunsDynamicWithoutMemoryExp
		run.poll_strategy = 4
	end

	for run in enrichedRunsDynamicWithMemoryLin
		run.poll_strategy = 5
	end

	for run in enrichedRunsDynamicWithMemoryExp
		run.poll_strategy = 6
	end


	Oignon = [runsClassic;
			oignonRunsStatic;
			oignonRunsDynamicWithoutMemoryLin;
			oignonRunsDynamicWithoutMemoryExp;
			oignonRunsDynamicWithMemoryLin;
			oignonRunsDynamicWithMemoryExp]
	Enriched = [runsClassic;
			enrichedRunsStatic;
			enrichedRunsDynamicWithoutMemoryLin;
			enrichedRunsDynamicWithoutMemoryExp;
			enrichedRunsDynamicWithMemoryLin;
			enrichedRunsDynamicWithMemoryExp]
	
	#we rebuild the pb number given the seed
	SetRealPbNumber(Oignon) 
	SetRealPbNumber(Enriched) 

	return Oignon, Enriched
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
				kappaMaxArray = [50.0, 50.0, 100.0, 200.0, 200.0]
			end
			if tau == 0.0001
				alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
				kappaMaxArray = [50.0, 100.0, 150.0, 250.0, 200.0]
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
				kappaMaxArray = [50.0, 50.0, 100.0, 200.0, 150.0]
			end
			if tau == 0.0001
				alphaMaxArray = [15.0, 15.0, 10.0, 15.0, 15.0]
				kappaMaxArray = [50.0, 100.0, 150.0, 250.0, 200.0]
			end
		end
	end
	i = Int(log2(dim))
	return alphaMaxArray[i], kappaMaxArray[i]
end

function Benchmarker(tau::Float64, attr::String, allRuns::Array{Run_t,1}, npmax::Int64, pollStr::String)
	allRuns =[FilterRuns("NB_2N_BLOCK", 1, allRuns); FilterRuns("NB_2N_BLOCK", npmax, allRuns)] #to conserve classic runs
	#tau = 0.01 ou 0.0001
	outputFolder = "/plots/pb-test/intensificationInfluence/$(pollStr)/profiles/$(attr)"
	#list of algoriths used in profiles, the order is important, AlgoName[i] will be the name of the algoritm with poll strategy i (set in Preprocess ()) 
	AlgoNames = ["Classique", "$(pollStr) statique", "$(pollStr) sans mem. lin.", "$(pollStr) sans mem. exp.", "$(pollStr) avec mem. lin.", "$(pollStr) avec mem. exp."]#, "Oignon dynamique exp.", "Oignon dynamique exp."] 
	#colors of the profiles
	AlgoColors = [:black, :gray80, :royalblue1, :blue3, :green, :gold]#Array{Symbol,1}([])
	#list of dimensions in which we do the benchmark
	dims = [2, 4, 8, 16, 32]

	for n in dims 
		runs = FilterRuns("DIM", Int(n), allRuns)

		outputName = "dim_$(n)_tau_$(tau)_n_max_$(npmax)"
		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(npmax) \\times 2n \$"

		alphaMax, kappaMax = SetAlphaKappa(attr,npmax, n, tau)

		PlotProfile(attr, tau, runs, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end
end

function PlotAllProfiles()
	Oignon, Enrichie = Preprocess()
	for tau in [0.01, 0.0001]
		for npmax in [8, 64]
			for attr in ["EVAL", "ITER"]
				Benchmarker(tau, attr, Oignon, npmax, "Oignon")
				Benchmarker(tau, attr, Enrichie, npmax, "Enrichie")
			end
		end
	end
end
