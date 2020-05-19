include("plotProfile.jl")
# : comparaison entre intensification de la sélection de points sur le cadre et à l'intérieur du cadre

function Preprocess()
	#data directories
	dirClassicRuns = "/run-pc-perso-confinement/run-pb-test/classical-poll" 
	dirEnrichedInsideFrame = "/run-pc-perso-confinement/run-pb-test/static"
	dirEnrichedOnFrame = "/run-pc-perso-confinement/run-pb-test/enriched-on-frame-static"  
	
	runsClassic = ExtractData(dirClassicRuns)
	enrichedRunsOnFrame = ExtractData(dirEnrichedOnFrame)
	enrichedRunsInsideFrame = ExtractSpecificData(dirEnrichedInsideFrame, "POLL_STRATEGY", 4)

	for run in enrichedRunsOnFrame
		run.poll_strategy = 2
	end
	for run in enrichedRunsInsideFrame
		run.poll_strategy = 3
	end

	SetRealPbNumber(runsClassic)
	SetRealPbNumber(enrichedRunsOnFrame)
	SetRealPbNumber(enrichedRunsInsideFrame)

	return runsClassic, [enrichedRunsOnFrame; enrichedRunsInsideFrame]
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

function Benchmarker(tau::Float64, attr::String, allRuns::Array{Run_t,1}, npmax::Int64)
	outputFolder = "/plots/pb-test/insideFrameInfluence/profils/$(attr)"
	#list of algoriths used in profiles, the order is important, AlgoName[i] will be the name of the algoritm with poll strategy i (set in Preprocess ()) 
	AlgoNames = ["Classique", "Enrichie sur le cadre", "Enrichie à l'intérieur du cadre" ]
	#colors of the profiles
	AlgoColors = [:black, :blue, :gold]#Array{Symbol,1}([])
	#list of dimensions in which we do the benchmark
	dims = [32]#[2, 4, 8, 16, 32]

	for n in dims 
		runs = FilterRuns("DIM", Int(n), allRuns)

		outputName = "dim_$(n)_tau_$(tau)_n_max_$(npmax)"
		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(npmax) \\times 2n \$"

		alphaMax, kappaMax = SetAlphaKappa(attr,npmax, n, tau)

		PlotProfile(attr, tau, runs, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end
end

function PlotAllProfiles()
	classicRuns, otherRuns = Preprocess()
	for npmax in [8, 64]
		allRuns = [classicRuns; FilterRuns("NB_2N_BLOCK", npmax, otherRuns)]
		for tau in [0.01, 0.0001]	
			for attr in ["EVAL", "ITER"]
				Benchmarker(tau, attr, allRuns, npmax)
			end
		end
	end
end
