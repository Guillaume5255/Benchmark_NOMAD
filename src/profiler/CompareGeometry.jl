include("core/plotProfile.jl")

## Here we want to compare all the static runs, they are all made with the same number of positive basis : 2n+1 
# because multi poll is non scalable, so we set NB_LAYER = 2n+1 for oignon poll and NB_2N_BLOCK = 2n+1 for enriched poll 
# we aim to see the influence of the geometry used to generate the points
function Preprocess(separateDims::Bool)
	dirClassicRun = ROOT_RUN_DIR*"/run-pb-test/classical-poll"
	dirOtherRun = ROOT_RUN_DIR*"/run-pb-test/compareGeometry"

	otherStaticRuns =  ExtractData(dirOtherRun)
	classicRun = ExtractData(dirClassicRun)
	SetRealPbNumber(classicRun, separateDims)
	SetRealPbNumber(otherStaticRuns, separateDims)
	return [classicRun; otherStaticRuns]
end

function SetAlphaKappa(attr::String, dim::Int, tau::Float64)
	alphaMaxArray = []
	kappaMaxArray = []

	if attr == "EVAL"
		if tau == 0.01
			alphaMaxArray = [10.0, 20.0, 25.0, 50.0, 100.0]
			kappaMaxArray = [200.0, 1000.0, 2000.0, 10000.0, 50000.0]
		end
		if tau == 0.0001
			alphaMaxArray = [10.0, 25.0, 25.0, 100.0, 100.0 ]
			kappaMaxArray = [300.0, 5000.0, 7500.0, 10000.0, 50000.0]
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
	if attr == "TIME"
		if tau == 0.01
			alphaMaxArray = [10.0, 20.0, 25.0, 30.0, 30.0]
			kappaMaxArray = [0.10, 0.5, 3.0, 70.0, 600.0]
		end
		if tau == 0.0001
			alphaMaxArray = [10.0, 20.0, 25.0, 30.0, 30.0]
			kappaMaxArray = [0.25, 0.75, 1.2, 4.0, 2.0]
		end

	end
	i = Int(log2(dim))
	return alphaMaxArray[i], kappaMaxArray[i]
end



function SetAlphaKappaAllDims(attr::String, tau::Float64)
	alphaMax=0
	kappaMax=0
	if attr == "EVAL"
		if tau == 0.01
			alphaMax = 15.0
			kappaMax = 2500.0
		end
		if tau == 0.0001
			alphaMax = 15.0
			kappaMax = 5000.0
		end
	end

	if attr == "ITER"
		if tau == 0.01
			alphaMax = 15.0
			kappaMax = 200.0
		end
		if tau == 0.0001
			alphaMax = 15.0
			kappaMax = 200.0
		end
	end
	return alphaMax, kappaMax
end

function Benchmarker(tau::Float64,attr::String, allRuns::Array{Run_t,1}, separateDims::Bool)
	#tau = 0.01
	outputFolder = "/plots/pb-test/geometryInfluence/profiles/$(attr)"
	AlgoNames = ["Classique", "Multi statique","Oignon statique", "Enrichie statique"]
	AlgoColors = [:black, :blue, :red, :yellow ]
	#dims = GetDims(allRuns)
	dims = [2 4 8 16 32]
	if separateDims
		for n in dims 
			nb2nBlock = 2*n+1 	 #except for the classical poll, all other runs have the same number of 2n block 
			runs = FilterRuns("DIM", Int(n), allRuns)

			outputName = "dim_$(n)_tau_$(tau)"
			Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(nb2nBlock) \\times 2n \$"

			alphaMax, kappaMax = SetAlphaKappa(attr, n, tau)
			PlotProfile(attr, tau, runs, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
		end
	else
		outputName = "tau_$(tau)"
		Title = "\$ \\tau = $(tau), n_p^{max} = (2n+1) \\times 2n \$"
		alphaMax, kappaMax = SetAlphaKappaAllDims(attr, tau)
		
		PlotProfile(attr, tau, allRuns, alphaMax, kappaMax, AlgoNames, AlgoColors, outputFolder, outputName, Title)
	end
end

function PlotAllProfils(separateDims::Bool)
	#if separateDims == true, profils are made for each dimension
	#else all the data are represented on the same profil 
	allRuns = Preprocess(separateDims)
	for tau in [0.01, 0.0001]	
		for attr in ["EVAL", "ITER"]
			Benchmarker(tau, attr, allRuns, separateDims)
		end
	end
end
