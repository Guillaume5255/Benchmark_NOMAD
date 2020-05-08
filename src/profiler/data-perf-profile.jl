
include("helperFunctions.jl")


################################data profile and performance profile ######################################

#there are 24 problems that has random components in their builds (not in their evaluations ! ), we have 5 different instances of each problems, maybe it's not relevant to look at all instances

#we have three ways to compute tps : by looking to iterations, evaluations and time.

# returns the amount of computation time, the number of iterations or the number of evaluations to satisfy the convergence test : f(x_0)-f(x)>= (1-tau)(f(x_0)-f_L))
function tps(tau::Float64, run::Run_t, attr::String)
	f_L = 0.0#here we know that all problems can reach 0 as minimum, so we take f_L = 0, to compute explicitely on real blackboxes
	fx_0 = run.eval_f[1]

	if attr == "EVAL"
		for i in 1:size(run.eval_f)[1]
			fx =  run.eval_f[i]
			if fx_0-fx >= (1-tau)*(fx_0-f_L)
				return run.eval_nb[i]	#if we want to do profile in term of eval we return the first eval number where f satisfies the convergence test
			end
		end

	elseif attr == "TIME"
		for i in 1:size(run.eval_f)[1]
			fx =  run.eval_f[i]
			if fx_0-fx >= (1-tau)*(fx_0-f_L)
				return run.eval_time[i] # if we want to do profile in term of computation time we return the first time corresponding to f satisfying he convergence test
			end
		end

	elseif attr == "ITER"
		for i in 1:size(run.eval_f)[1]
			fx =  run.eval_f[i]
			if fx_0-fx >= (1-tau)*(fx_0-f_L)
				return run.iter[i]
			end
		end
	end

	return Inf

end

#returns the number of solvers and problems based on the runs given as parameters
#looking to run.poll_strategy min and max; run.pb_num min and max and computes the product of the differences - 1
#suppose that there are no gap in slover and pb list : if there are k solvers, there are indexed from 1 to k, if there are p problems, there are indexed form 1 to p
function GetNbSolversProblems(runs::Array{Run_t,1})
	numSolverMax = -Inf
	numSolverMin = Inf
	numPbMax = -Inf
	numPbMin = Inf
	for run in runs
		if numSolverMax < run.poll_strategy
			numSolverMax = run.poll_strategy
		end
		if numSolverMin > run.poll_strategy
			numSolverMin = run.poll_strategy
		end
		if numPbMax < run.pb_num
			numPbMax = run.pb_num
		end
		if numPbMin > run.pb_num
			numPbMin = run.pb_num
		end
	end

	nbSolvers = numSolverMax - numSolverMin + 1
	nbPorblems = numPbMax - numPbMin + 1
	return nbSolvers, nbPorblems
end


function tpsMatrix(tau::Float64, runs::Array{Run_t,1}, attr::String)
	nbSolvers, nbProblems = GetNbSolversProblems(runs)
	tps_matrix = zeros(nbProblems,nbSolvers)

	for run in runs
		p = run.pb_num
		s = run.poll_strategy # one solver = one strategy 
		tps_matrix[p,s]=tps(tau, run, attr)
	end
	
	return tps_matrix
end

function rpsMatrix(tps_matrix::Array{Float64,2})
	nbProblems, nbSolveurs = size(tps_matrix)
	rps_matrix = copy(tps_matrix)
	for p in 1:nbProblems
		minTps = minimum(tps_matrix[p,:])
		rps_matrix[p,:] = rps_matrix[p,:]/minTps
	end
	return rps_matrix
end

function PerformanceProfile(alpha::Float64, s::Int64,rps_matrix::Array{Float64,2})
	count = 0 # for a given solver s, counts the number of times r_ps is smaller than alpha
	nbProblems = size(rps_matrix)[1]
	for p in 1:nbProblems
		if rps_matrix[p,s] <= alpha
			count = count+1
		end
	end

	return count/nbProblems
end


function DataProfile(kappa::Float64, s::Int64, normalized_tps_matrix::Array{Float64,2})
	#normalized_tps_matrix = tps_matrix/n+1, we dont have access to n 
	count = 0
	nbProblems = size(normalized_tps_matrix)[1]
	for p in 1:nbProblems
		if normalized_tps_matrix[p,s] <= kappa
			count = count+1
		end
	end

	return count/nbProblems
end
#
#
##the set of solvers will be classic poll, multi poll and for oignon and enriched poll, we will work with Nb2nBlock that seems the best according to plots given by PlotMeanFinalValue()
#
#function prepareRunsForProfiles()
#	dir0 = "../run-pb-test" #"../run-pb-bb"
#
#	println("extracting data from $(dir0)")
#	runsPbTest = ExtractData(dir0);
#	println("done")
#
#	#runsPbTest = FilterRuns("PB_NUM",7,runsPbTest)
#	#runsPbTest=ExcludeProblems([n for n in 1:14], runsPbTest)
#
#	println("excluding LHS strategie (no iteration there)")
#	runsPbTest = ExcludePollStrategies([5], runsPbTest)
#	println("done")
#
#	runsPbTest = FilterRuns("PB_SEED", 0, runsPbTest)
#
#	runsPbTestAllDimClassic = FilterRuns("POLL_STRATEGY", 1, runsPbTest)
#
#	runsPbTestAllDimMulti = FilterRuns("POLL_STRATEGY", 2, runsPbTest)
#
#
#
#	allRunsPbTestDim2 = FilterRuns("DIM",2,runsPbTest)
#	runsPbTestDim2Filtered = [FilterRuns("NB_2N_BLOCK", 7, allRunsPbTestDim2);FilterRuns("DIM",2,runsPbTestAllDimClassic);FilterRuns("DIM",2,runsPbTestAllDimMulti)]
#						#be careful when changing this  ^  for example, here if 7 is remplaced by 5 the result given by Filter run will include part of this   ^
#	allRunsPbTestDim4 = FilterRuns("DIM",4,runsPbTest)
#	runsPbTestDim4Filtered = [FilterRuns("NB_2N_BLOCK", 5, allRunsPbTestDim4);FilterRuns("DIM",4,runsPbTestAllDimClassic);FilterRuns("DIM",4,runsPbTestAllDimMulti)]
#
#	allRunsPbTestDim8 = FilterRuns("DIM",8,runsPbTest)
#	runsPbTestDim8Filtered = [FilterRuns("NB_2N_BLOCK", 6, allRunsPbTestDim8);FilterRuns("DIM",8,runsPbTestAllDimClassic);FilterRuns("DIM",8,runsPbTestAllDimMulti)]
#
#	allRunsPbTestDim16 = FilterRuns("DIM",16,runsPbTest)
#	runsPbTestDim16Filtered = [FilterRuns("NB_2N_BLOCK", 64, allRunsPbTestDim16);FilterRuns("DIM",16,runsPbTestAllDimClassic);FilterRuns("DIM",16,runsPbTestAllDimMulti)]
#
#	allRunsPbTestDim32 = FilterRuns("DIM",32,runsPbTest)
#	runsPbTestDim32Filtered = [FilterRuns("NB_2N_BLOCK", 128, allRunsPbTestDim32);FilterRuns("DIM",32,runsPbTestAllDimClassic);FilterRuns("DIM",32,runsPbTestAllDimMulti)]
#
#	allRunsPbTestDim64 = FilterRuns("DIM",64,runsPbTest)
#	runsPbTestDim64Filtered = [FilterRuns("NB_2N_BLOCK", 16, allRunsPbTestDim64);FilterRuns("DIM",64,runsPbTestAllDimClassic);FilterRuns("DIM",64,runsPbTestAllDimMulti)]
#
#
#
#	return [runsPbTestDim2Filtered, runsPbTestDim4Filtered, runsPbTestDim8Filtered, runsPbTestDim16Filtered, runsPbTestDim32Filtered, runsPbTestDim64Filtered]
#end
#
#
#function PlotProfile(attr::String, tau::Float64)
#	println("preprocessing runs")
#	groupsOfRuns = prepareRunsForProfiles()
#	println("done")
#	dims = [2, 4, 8, 16, 32, 64]
#
#	colors = [:black, :blue, :red, :yellow]
#	pollStr = ["Classique", "Multi", "Oignon", "Enrichie"]
#	
#	legendPos = :bottomright
#
#
#	for l in 1:size(dims)[1]
#		println(l)
#		tps_matrix = tpsMatrix(tau, groupsOfRuns[l],attr)
#		
#		normalized_tps_matrix = copy(tps_matrix)
#		normalized_tps_matrix = normalized_tps_matrix/(dims[l]+1)
#		rps_matrix = rpsMatrix(tps_matrix) 
#
#		alphaPP = 0.0:1.0:(1000*dims[l])
#		alphaDP = 0.0:1.0:(1000*dims[l])
#		PPplot = plot(dpi=300)
#		DPplot = plot(dpi=300)
#
#		Title = "dimension $(dims[l]), tau = $(tau)"
#
#		for s in 1:size(pollStr)[1]
#
#			PerformanceProfileValue =  [PerformanceProfile(alpha, s, rps_matrix) for alpha in alphaPP]
#			PerformanceProfileValue =  [DataProfile(alpha, s, normalized_tps_matrix) for alpha in alphaDP]
#
#			PPplot = plot!(PPplot,alphaPP, PerformanceProfileValue, color=colors[s], label = pollStr[s], legend=legendPos, linetype=:steppre)
#
#			DPplot = plot!(DPplot,alphaDP, PerformanceProfileValue, color=colors[s], label = pollStr[s], legend=legendPos, linetype=:steppre)
#
#		end
#
#		xlabel!(PPplot,"alpha")
#		xlabel!(DPplot,"alpha")
#
#		ylabel!(PPplot,"proportion de problemes resolus")
#		ylabel!(DPplot,"proportion de problemes resolus")
#
#
#		title!(PPplot,Title)
#		title!(DPplot,Title)
#
#
#
#		filename = "../plots/pb-test/profiles"
#		#filename = "../plots/pb-bb-styrene/profiles"
#		println("saving in $(filename)")
#
#		cd(filename)
#		savefig(PPplot,"performance_profile_dim_$(dims[l])_tau_$(tau)_attr_$(attr).png")
#		savefig(DPplot,"data_profile_dim_$(dims[l])_tau_$(tau)_attr_$(attr).png")
#		cd("../../src")
#
#		println("done")
#
#	end
#end
#
#
#
#function PreprocessRunsStaticDynamic() # used in CompareStaticDynamic()
#	#directories for dynamic and static runs (only oignon and enriched)
#	dirDynamicLinRun = "../run-pc-perso-confinement/run-pb-test-dynamic" #to change to "../run-pc-perso-confinement/run-pb-test/dynamic/exp"
#	dirDynamicExpRun = "../run-pc-perso-confinement/run-pb-test/dynamic/exp" 
#
#	dirStaticRun = "../run-pc-perso-confinement/run-pb-test-static"
#
#	staticRunsAllDims = ExtractData(dirStaticRun)
#	dynamicLinRunsAllDims = ExtractData(dirDynamicLinRun)
#	#dynamicExpRunsAllDims = ExtractData(dirDynamicExpRun)
#
#	nbProblems = 24
#	for run in staticRunsAllDims #poll strategies are the solvers, changing static to dynamic changes the solver so we put this information in run.poll_strategy
#		# : run.poll_strategy < 3 : static else dynamic 
#		run.poll_strategy = run.poll_strategy-2
#
#		run.pb_num = nbProblems*(run.pb_seed) + run.pb_num #computing real pb number with seed 
#	end
#
#	for run in dynamicLinRunsAllDims
#		run.pb_num = nbProblems*(run.pb_seed) + run.pb_num #computing real pb number with seed 
#	end
#
#	#for run in dynaicExpRunsAllDims #poll strategies are the solvers, changing static to dynamic changes the solver so we put this information in run.poll_strategy
#		# : run.poll_strategy < 3 : static else dynamic 
#	#	run.poll_strategy = run.poll_strategy+2
#
#	#	run.pb_num = nbProblems*(run.pb_seed) + run.pb_num #computing real pb number with seed 
#	#end
#
#	return [staticRunsAllDims; dynamicLinRunsAllDims]#; dynamicExpRunsAllDims]
#end
#
#function PreprocessAllStaticRuns()
#	AllStaticRunsDir = "../run-pb-test/allStaticRuns"
#	#All
#end
#
#
##creates plots in ../plots/pb-test/dynamicVSstatic/profiles/
##using data in ../run-pc-perso-confinement/run-pb-test-dynamic and ../run-pc-perso-confinement/run-pb-test-static
##trying to show differences between oignon and enriched poll with static and dynamic mode
#function CompareStaticDynamic(attr::String, nb2nBlock::Int64, tau::Float64)
#	#for comparing static dynamic 
#	runsAllDims = PreprocessRunsStaticDynamic()
#	runsAllDims = FilterRuns("NB_2N_BLOCK",nb2nBlock,runsAllDims)
#	#runsAllDims = FilterRuns("PB_SEED",0,runsAllDims)#to remove
#
#	#for comparing all static strategies
#	#runsAllDims = PreprocessAllStaticRuns()
#
#	#for comparinng previous strategies real blackbox problems 
#
#	dims = [2, 4, 8, 16, 32]#, 64] data to come
#
#	colors = [:grey, :blue, :red, :yellow]
#	pollStr = ["Oignon statique", "Enrichie statique", "Oignon dynamique lin.", "Enrichie dynamique lin."]#, "Oignon dynamique exp.", "Oignon dynamique exp."] 
#	#markers = [:cross, :cross, :xcross, :xcross]
#	legendPos = :bottomright
#
#	for n in dims
#		runs = FilterRuns("DIM",n,runsAllDims)
#
#		tps_matrix = tpsMatrix(tau,runs,attr)
#		rps_matrix = rpsMatrix(tps_matrix) 
#
#		normalized_tps_matrix = copy(tps_matrix)
#		normalized_tps_matrix = normalized_tps_matrix/(n+1)
#
#		#nb2nblock = 8 attr = EVAL
#		#alphaPP = 0.0:0.5:(20)
#		#kappaDP = 0.0:1.0:(25*n*n)
#
#		#nb2nblock = 64 attr = EVAL
#		alphaPP = 0.0:0.5:(100)
#		kappaDP = 0.0:1.0:(50*n*n+600)
#
#		#nb2nblock = 8 attr = ITER
#		#alphaPP = 0.0:0.1:(15)
#		#kappaDP = 0.0:0.1:(n+25)
#
#		PPplot = plot(dpi=300)
#		DPplot = plot(dpi=300)
#
#		Title = "\$n = $(n), \\tau = $(tau), n_p^{max} = $(nb2nBlock)\$"
#
#		for s in 1:size(pollStr)[1]
#
#			PPValue =  [PerformanceProfile(alpha, s, rps_matrix) for alpha in alphaPP]
#			DPValue =  [DataProfile(kappa, s, normalized_tps_matrix) for kappa in kappaDP]
#
#			PPplot = plot!(PPplot,alphaPP, PPValue, color=colors[s], label = pollStr[s], legend=legendPos, linetype=:steppre)
#			DPplot = plot!(DPplot,kappaDP, DPValue, color=colors[s], label = pollStr[s], legend=legendPos, linetype=:steppre)
#
#		end
#
#		xlabel!(PPplot,"\$\\alpha\$")
#		xlabel!(DPplot,"\$\\kappa\$")
#
#		ylabel!(PPplot,"proportion de problemes resolus")
#		ylabel!(DPplot,"proportion de problemes resolus")
#
#		title!(PPplot,Title)
#		title!(DPplot,Title)
#
#		#filename = "../plots/pb-test/compareAllStrategies/$(attr)" #to compare all strategies, execute multi oignon and enriched with the same number of points : 2n+1
#		filename = "../plots/pb-test/dynamicVSstatic/profiles/$(attr)"
#		println("saving in $(filename)")
#
#		cd(filename)
#		savefig(PPplot,"pp_dim_$(n)_tau_$(tau)_attr_$(attr).svg")
#		savefig(DPplot,"dp_dim_$(n)_tau_$(tau)_attr_$(attr).svg")
#		cd("../../../../../src")
#
#		println("done")
#
#	end
#end
#
#
