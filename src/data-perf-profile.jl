
using Plots
#pgfplots()
gr()
#gadfly()
#pyplot()

using LaTeXStrings


include("helperFunctions.jl")


################################data profile and performance profile ######################################

#there are 24 problems that has random components in their builds (not in their evaluations ! ), we have 5 different instances of each problems, maybe it's not relevant to look at all instances

#we have two ways to compute tps : by looking to iterations and by looking to evaluations, the first one is useful in the case of a constant number of evaluaitons per iterations

function tps_iter(tau::Float64, iterations::Iter_t)# returns the amount of computation time or the number of iterations to satisfy the convergence test : f(x_0)-f(x)>= (1-tau)(f(x_0)-f_L))
												#here we know that all problems can reach 0 as minimum, so we take f_L = 0
	f_L = 0.0 #to compute explicitely if we do not use the set of problems that all reach 0
	fx_0 = iterations.f_k[1]
	for i in 1:size(iterations.f_k)[1]
		fx =  iterations.f_k[i]
		if fx_0-fx >= (1-tau)*(fx_0-f_L)
			return i 
		end
	end
end

function tps(tau::Float64, run::Run_t, attr::String)
	f_L = 0.0 #to compute explicitely if we do not use the set of problems that all reach 0
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
		#iterations = BuildIteration(run)
		#for i in 1:size(iterations.f_k)[1]
		#	fx =  iterations.f_k[i]
		#	if fx_0-fx >= (1-tau)*(fx_0-f_L)
		#		return i 
		#	end
		#end
		for i in 1:size(run.eval_f)[1]
			fx =  run.eval_f[i]
			if fx_0-fx >= (1-tau)*(fx_0-f_L)
				return run.iter[i]
			end
		end
	end

	return Inf

end

function tpsMatrix(tau::Float64, runs::Array{Run_t,1}, attr::String)
	nbSolvers = 4 #find a way to automatically get these information from runs
	nbProblems = 24
	tps_matrix = zeros(nbProblems,nbSolvers)

	for run in runs
		p = run.pb_num
		s = run.poll_strategy # one solver = one strategy (with number of 2nblocks fixed in preprocessing runs in prepareRunsForProfiles())
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
	count = 0
	nbProblems = size(rps_matrix)[1]
	for p in 1:nbProblems
		if rps_matrix[p,s] <= alpha
			count = count+1
		end
	end

	return count/nbProblems
end


function DataProfile(alpha::Float64, s::Int64, normalized_tps_matrix::Array{Float64,2})
	#normalized_tps_matrix = tps_matrix/n+1
	count = 0
	nbProblems = size(normalized_tps_matrix)[1]
	for p in 1:nbProblems
		if normalized_tps_matrix[p,s] <= alpha
			count = count+1
		end
	end

	return count/nbProblems
end


#the set of solvers will be classic poll, multi poll and for oignon and enriched poll, we will work with Nb2nBlock that seems the best according to plots given by PlotMeanFinalValue()

function prepareRunsForProfiles()
	dir0 = "../run-pb-test" #"../run-pb-bb"

	println("extracting data from $(dir0)")
	runsPbTest = ExtractData(dir0);
	println("done")

	#runsPbTest = FilterRuns("PB_NUM",7,runsPbTest)
	#runsPbTest=ExcludeProblems([n for n in 1:14], runsPbTest)

	println("excluding LHS strategie (no iteration there)")
	runsPbTest = ExcludePollStrategies([5], runsPbTest)
	println("done")

	runsPbTest = FilterRuns("PB_SEED", 0, runsPbTest)

	runsPbTestAllDimClassic = FilterRuns("POLL_STRATEGY", 1, runsPbTest)

	runsPbTestAllDimMulti = FilterRuns("POLL_STRATEGY", 2, runsPbTest)



	allRunsPbTestDim2 = FilterRuns("DIM",2,runsPbTest)
	runsPbTestDim2Filtered = [FilterRuns("NB_2N_BLOCK", 7, allRunsPbTestDim2);FilterRuns("DIM",2,runsPbTestAllDimClassic);FilterRuns("DIM",2,runsPbTestAllDimMulti)]
						#be careful when changing this  ^  for example, here if 7 is remplaced by 5 the result given by Filter run will include part of this   ^
	allRunsPbTestDim4 = FilterRuns("DIM",4,runsPbTest)
	runsPbTestDim4Filtered = [FilterRuns("NB_2N_BLOCK", 5, allRunsPbTestDim4);FilterRuns("DIM",4,runsPbTestAllDimClassic);FilterRuns("DIM",4,runsPbTestAllDimMulti)]

	allRunsPbTestDim8 = FilterRuns("DIM",8,runsPbTest)
	runsPbTestDim8Filtered = [FilterRuns("NB_2N_BLOCK", 6, allRunsPbTestDim8);FilterRuns("DIM",8,runsPbTestAllDimClassic);FilterRuns("DIM",8,runsPbTestAllDimMulti)]

	allRunsPbTestDim16 = FilterRuns("DIM",16,runsPbTest)
	runsPbTestDim16Filtered = [FilterRuns("NB_2N_BLOCK", 64, allRunsPbTestDim16);FilterRuns("DIM",16,runsPbTestAllDimClassic);FilterRuns("DIM",16,runsPbTestAllDimMulti)]

	allRunsPbTestDim32 = FilterRuns("DIM",32,runsPbTest)
	runsPbTestDim32Filtered = [FilterRuns("NB_2N_BLOCK", 128, allRunsPbTestDim32);FilterRuns("DIM",32,runsPbTestAllDimClassic);FilterRuns("DIM",32,runsPbTestAllDimMulti)]

	allRunsPbTestDim64 = FilterRuns("DIM",64,runsPbTest)
	runsPbTestDim64Filtered = [FilterRuns("NB_2N_BLOCK", 16, allRunsPbTestDim64);FilterRuns("DIM",64,runsPbTestAllDimClassic);FilterRuns("DIM",64,runsPbTestAllDimMulti)]



	return [runsPbTestDim2Filtered, runsPbTestDim4Filtered, runsPbTestDim8Filtered, runsPbTestDim16Filtered, runsPbTestDim32Filtered, runsPbTestDim64Filtered]
end


function PlotProfile(attr::String, tau::Float64)
	println("preprocessing runs")
	groupsOfRuns = prepareRunsForProfiles()
	println("done")
	dims = [2, 4, 8, 16, 32, 64]

	colors = [:black, :blue, :red, :yellow]
	pollStr = ["Classique", "Multi", "Oignon", "Enrichie"]
	
	legendPos = :bottomright


	for l in 1:size(dims)[1]
		println(l)
		tps_matrix = tpsMatrix(tau, groupsOfRuns[l],attr)
		
		normalized_tps_matrix = copy(tps_matrix)
		normalized_tps_matrix = normalized_tps_matrix/(dims[l]+1)
		rps_matrix = rpsMatrix(tps_matrix) 

		alphaPP = 0.0:1.0:(1000*dims[l])
		alphaDP = 0.0:1.0:(1000*dims[l])
		PPplot = plot(dpi=300)
		DPplot = plot(dpi=300)

		Title = "dimension $(dims[l]), tau = $(tau)"

		for s in 1:size(pollStr)[1]

			PerformanceProfileValue =  [PerformanceProfile(alpha, s, rps_matrix) for alpha in alphaPP]
			PerformanceProfileValue =  [DataProfile(alpha, s, normalized_tps_matrix) for alpha in alphaDP]

			PPplot = plot!(PPplot,alphaPP, PerformanceProfileValue, color=colors[s], label = pollStr[s], legend=legendPos, linetype=:steppre)

			DPplot = plot!(DPplot,alphaDP, PerformanceProfileValue, color=colors[s], label = pollStr[s], legend=legendPos, linetype=:steppre)

		end

		xlabel!(PPplot,"alpha")
		xlabel!(DPplot,"alpha")

		ylabel!(PPplot,"propostion de problemes resolus")
		ylabel!(DPplot,"propostion de problemes resolus")


		title!(PPplot,Title)
		title!(DPplot,Title)



		filename = "../plots/pb-test/profiles"
		#filename = "../plots/pb-bb-styrene/profiles"
		println("saving in $(filename)")

		cd(filename)
		savefig(PPplot,"performance_profile_dim_$(dims[l])_tau_$(tau)_attr_$(attr).png")
		savefig(DPplot,"data_profile_dim_$(dims[l])_tau_$(tau)_attr_$(attr).png")
		cd("../../src")

		println("done")

	end
end