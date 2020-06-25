
include("helperFunctions.jl")


################################data profile and performance profile ######################################

#there are 24 problems that has random components in their builds (not in their evaluations ! ), we have 5 different instances of each problems, maybe it's not relevant to look at all instances

#we have three ways to compute tps : by looking to iterations, evaluations and time.

# returns the amount of computation time, the number of iterations or the number of evaluations to satisfy the convergence test : f(x_0)-f(x)>= (1-tau)(f(x_0)-f_L))
function tps(tau::Float64, run::Run_t, attr::String, f_L::Float64)
	#f_L = 0.0#here we know that all problems can reach 0 as minimum, so we take f_L = 0, to compute explicitely on real blackboxes
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
	println("nb problems")	
	println(nbProblems)
	tps_matrix = zeros(nbProblems,nbSolvers)
	f_lArray = zeros(nbProblems)
	for p in 1:nbProblems
		f_lArray[p]=Inf
	end
	for run in runs
		p = run.pb_num
		fopt = run.eval_f[end]
		if fopt< f_lArray[p]
			f_lArray[p] = fopt
		end
	end
	#println(f_lArray)		
	for run in runs
		p = run.pb_num
		s = run.poll_strategy # one solver = one strategy 
		tps_matrix[p,s]=tps(tau, run, attr, f_lArray[p])
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

