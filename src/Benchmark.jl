#code to benchmark poll strategies
#the problems are all defined in [-5,5]^n,
#they all have objective function positive or null, 
#they use random rotations matrix to generate instance
#the entries of the matrix are generated with a random seed that can be changed : changing the seed change the problem 
#the starting point can also be changed, but for the momet, it is arbitrarly fixed to (-4,...-4)

using Plots
#pgfplots()
gr()
#gadfly()
#pyplot()

using LaTeXStrings


include("helperFunctions.jl")




#first goal of this benchmark : is it effeicient to do more poll evaluation ? 
#								which sampling strategy has the best performance in term of finding a local minima ? ==> compute the ratio nb times we do the poll/number of time we find a success

function ObjectifEvolution(dir::String)
	#plots the decreasing of the objective function according to the number of evaluation
	runs = ExtractData(dir)
	normalizedRuns = NormalizeRun(runs)
	colors = [:black, :blue, :red, :yellow] #classic poll, multi poll, oignon poll, enriched poll
	markers = [:cicle, :utrianngle, :dtriangle, :cross] #number of 2n block
	allplots = [plot()]
	j = 1
	for run in normalizedRuns
		i = run.poll_strategy
		Fvalue = [f+1 for f in run.eval_f]
		push!(allplots, plot!(allplots[j],run.eval_nb, Fvalue, color = colors[i] ,xaxis=:log, yaxis=:log, leg = false,linetype=:steppre)) #yaxis=:log) )# fmt = :png) # reuse = true m = markers[i]
		if (j<4)
			j+=1
		else
			j=1
		end
	end
	savefig("objectifEvolution.png")
	return allplots[j]
end







function ObjectifFinalValue( dim::Int64, allRuns::Array{Run_t,1}) 
	#plots the final value of the objectif function (at the end of the optimization)
	#to apply to one problem run with different seed and starting point
	# note : increasing the number of points sampled with the dimension and looking at how the best objectif function value is evolving tells us if the strategy is scalable or not 
	runs = FilterRuns("DIM", dim, allRuns)
	#normalizedRuns = NormalizeRun(runs)
	finalValueEClassic = []
	finalValueFClassic = []

	finalValueEMulti = []
	finalValueFMulti = []

	finalValueEOignon = []
	finalValueFOignon = []

	finalValueEEnriched = []
	finalValueFEnriched = []

	for run in runs#normalizedRuns
		i = run.poll_strategy
		Fvalue = run.eval_f[end]+1
		finalEval = run.eval_nb[end]
		
		if i==1
			push!(finalValueEClassic, finalEval)
			push!(finalValueFClassic, Fvalue)
		end

		if i==2
			push!(finalValueEMulti, finalEval)
			push!(finalValueFMulti, Fvalue)
		end

		if i==3
			push!(finalValueEOignon, finalEval)
			push!(finalValueFOignon, Fvalue)
		end

		if i==4
			push!(finalValueEEnriched, finalEval)
			push!(finalValueFEnriched, Fvalue)
		end
	end

	colors = [:black, :blue, :red, :yellow] #classic poll, multi poll, oignon poll, enriched poll
	scales = [:log, :linear]
	xscale = scales[1]
	yscale = scales[1]
	Label=["Classical Poll" "Multi Poll" "Oignon Poll" "Enriched Poll"]
	p = plot() 
	p = plot!(p,finalValueEClassic,finalValueFClassic,seriestype=:scatter, color = colors[1], label = Label[1], xaxis=xscale, yaxis=yscale)

	p = plot!(p,finalValueEMulti,finalValueFMulti,seriestype=:scatter, color = colors[2], label = Label[2], xaxis=xscale, yaxis=yscale)

	p = plot!(p,finalValueEOignon,finalValueFOignon,seriestype=:scatter, color = colors[3], label = Label[3],xaxis=xscale, yaxis=yscale)

	p = plot!(p,finalValueEEnriched,finalValueFEnriched,seriestype=:scatter, color = colors[4], label = Label[4], xaxis=xscale, yaxis=yscale)
	
	Title = " dimension $(dim)"#, dimension = "*string(runs[1].dim)
	title!(Title)

	xlabel!("nbEval when stopping criterion is reached")
	ylabel!("f value when stopping criterion is reached")

	println("saving in ../Plots")

	cd("../plots")
	savefig(p,"ObjectifFinalValue_$(dim).pdf")
	cd("../src")
	
	println("done")

	
end


function PlotObjectifFinalValue()
	dir0 = "../run-pb-test" #"../run-pb-blackbox"

	println("extracting data from $(dir0)")
	runsPbTest = ExtractData(dir0);
	println("done")

	for n in [2 4 8 16 32 64]
		ObjectifFinalValue(n, runsPbTest)
	end
end













function MeanFinalStats( dim::Int64, allRuns::Array{Run_t,1})
	runs = FilterRuns("DIM", dim, allRuns)
	#normalizedRuns = NormalizeRun(runs)
	Fvalue = [0.0 0.0 0.0 0.0 0.0]
	finalEval = [0.0 0.0 0.0 0.0 0.0]
	strategyCounter = [0.0 0.0 0.0 0.0 0.0]
	for run in runs
		strategyCounter[run.poll_strategy] +=1
	end
	for run in runs#normalizedRuns
		i = run.poll_strategy
		Fvalue[i] += run.eval_f[end]/strategyCounter[i]
		finalEval[i] += run.eval_nb[end]/strategyCounter[i]
	end

	colors = [:black, :blue, :red, :yellow, :green] #classic poll, multi poll, oignon poll, enriched poll
	scales = [:log, :linear]
	xscale = scales[1]
	yscale = scales[1]
	Label=["Classical Poll" "Multi Poll" "Oignon Poll" "Enriched Poll" "LHS"]
	Title = "Mean values dimension $(dim)"

	p = plot()
	for i = 1:4
		abscisse = [finalEval[i]]
		ordonnee = [Fvalue[i]]
		p = plot!(p,abscisse,ordonnee,seriestype=:scatter, color = colors[i], label = Label[i])
	end
	title!(Title)
	xlabel!("mean nbEval/(2*dim*nb2nBlock) when stopping criterion is reached")
	ylabel!("mean f value when stopping criterion is reached")

	println("saving in ../Plots")

	cd("../plots")
	savefig(p,"meanObjectifFinalValue_$(dim).pdf")
	cd("../src")
	
	println("done")

end

function PlotMeanObjectifFinalValue()
	dir0 = "../run-pb-test" #"../run-pb-blackbox"

	println("extracting data from $(dir0)")
	runsPbTest = ExtractData(dir0);
	println("done")

	for n in [2 4 8 16 32 64]
		MeanFinalStats(n, runsPbTest)
	end
end







function PerformanceOfIncreasingNbOfPoint(dim::Int, useLogScale::Bool, allRuns::Array{Run_t,1} ) #plots f*(y axis) according to the strategy used (color) and the number of positive basis used in the poll strategy (x axis) 
	#to run with one strategy where the number of 2n blocks can be set 
	#to see the effect of this increase in the number of point at each poll step
	colors = [:black, :blue, :red, :yellow, :green]

	runs = FilterRuns("DIM",dim,allRuns)

	#runs = FilterRuns("PB_SEED",3,runs)
	#runs = ExcludeProblems([1, 2, 5, 10, 11, 12, 13, 14], runs)
	if useLogScale
		runs = NormalizeRun(runs)
	end
	pollStr = ["Classique" "Multi" "Oignon" "Enrichie" "LHS"]
	legendPos = :topright
	p = plot()
	for run in runs

		Fvalue = run.eval_f[end]
		
		if Fvalue > 75000
			Display(run)
		end

		i = run.nb_2n_blocks
		j = run.poll_strategy
		if useLogScale
			p=plot!(p,[i], [Fvalue], seriestype=:scatter, color = colors[j], label = pollStr[j], legend = legendPos, xaxis = :log2, yaxis = :log10)
			pollStr[j] = ""
		else
			p=plot!(p,[i], [Fvalue], seriestype=:scatter, color = colors[j], label = pollStr[j], legend = legendPos)
			pollStr[j] = ""
		end
	end



	Title = "dimension $(dim) (1 dot = 1 run)"
	title!(Title)
	xlabel!("nb2nBlock ")
	ylabel!("optimal value")

	cd("../plots")
	savefig("all_$(dim)")
	cd("../src")
end







function MeanPerformanceOfIncreasingNbOfPoint(dim::Int64,useLogScale::Bool, allRuns::Array{Run_t,1})#plots the mean f*(y axis) according to the strategy used (color) and the number of positive basis used in the poll strategy (x axis) 
	#to run with one strategy where the number of 2n blocks is increasing
	#to see the effect of this increase in the number of point at each poll step
	runs = FilterRuns("DIM",dim,allRuns)
	#runs = FilterRuns("POLL_STRATEGY",1,runs)


	#runs = FilterRuns("PB_SEED",3,runs)
	#runs = ExcludeProblems([1, 2, 5, 10, 11, 12, 13, 14], runs)
	println("number of runs in dimension $(dim) : ")
	println(size(runs)[1])
	

	if useLogScale
		runs = NormalizeRun(runs)
	end

	maxNb2nBlock = 0 # maximum number of 2n block used (usally for the multi poll)
	nbPollStrategies = 5 #number of poll strategies that were tested
	
	for run in runs
		if run.nb_2n_blocks>maxNb2nBlock
			maxNb2nBlock = run.nb_2n_blocks
		end
	end

	RunsCounter = zeros(maxNb2nBlock, nbPollStrategies)
	maxFvalue = zeros(maxNb2nBlock, nbPollStrategies)
	minFvalue = zeros(maxNb2nBlock, nbPollStrategies)
	for i in 1:maxNb2nBlock
		for j in 1:nbPollStrategies
			minFvalue[i,j] = Inf
		end
	end
	meanFvalue = zeros(maxNb2nBlock, nbPollStrategies)
	sFvalue = zeros(maxNb2nBlock, nbPollStrategies)

	for run in runs
		j = run.poll_strategy
		i = run.nb_2n_blocks
		RunsCounter[i,j] += 1 #run counter[i,j] = the number of runs made with i 2nblocks and poll strategy j
		Fval = run.eval_f[end]
		if Fval > maxFvalue[i,j]
			maxFvalue[i,j] = Fval
		end
		if Fval < minFvalue[i,j]
			minFvalue[i,j] = Fval
		end
	end

	println("\n run counter[i,j] = the number of runs made with i 2nblocks and poll strategy j")
	println(RunsCounter)

	println("\n maxFvalue[i,j] = the biggest value of f* obtained with i 2nblocks and poll strategy j")
	println(maxFvalue)

	println("\n minFvalue[i,j] = the smallest value of f* obtained with i 2nblocks and poll strategy j")
	println(minFvalue)

	for run in runs
		j = run.poll_strategy
		i = run.nb_2n_blocks
		if RunsCounter[i,j] > 0
			meanFvalue[i,j]+= (run.eval_f[end])/RunsCounter[i,j]
		end
	end
	println("\n meanValue[i,j]=mean value of f* on the runs made with  i 2nblocks and poll strategy j")
	println(meanFvalue)

	for run in runs
		j = run.poll_strategy
		i = run.nb_2n_blocks
		if RunsCounter[i,j] > 0
			sFvalue[i,j]+= ((run.eval_f[end]-meanFvalue[i,j])^2)/(RunsCounter[i,j]-1)
		end
	end
	println("\n sFvalue[i,j]=standard deviation of f* on the runs made with  i 2nblocks and poll strategy j")
	println(sFvalue)

	println("\n Plotting...")
	p = plot(dpi=300)


	markers = [:circle, :square, :utriangle, :dtriangle]
	msize = 3
	mcontour = 0.2

	colors = [:black, :blue, :red, :yellow, :green]
	pollStr = ["Classique" "Multi" "Oignon" "Enrichie" "LHS"]
	legendPos = :topright
	Xgrad = :log2
	Ygrad = :log10



	#for run in runs 
	for j in 1:nbPollStrategies
		for i in 1:maxNb2nBlock
		#j = run.poll_strategy
		#i = run.nb_2n_blocks
			if RunsCounter[i,j]>0 #we only plot when there exist at least one run 
				if useLogScale 
					p = plot!(p,[i], [meanFvalue[i,j]], 				 seriestype=:scatter, marker = markers[1], markersize = msize, markerstrokewidth = mcontour, label = pollStr[j],legend=legendPos, color = colors[j], yaxis = Ygrad, xaxis = Xgrad)#, xticks = graduations)

					p = plot!(p,[i], [meanFvalue[i,j]+sqrt(sFvalue[i,j])], seriestype=:scatter, marker = markers[2], markersize = msize, markerstrokewidth = mcontour, label = "",		  legend=legendPos, color = colors[j], yaxis = Ygrad, xaxis = Xgrad)#, xticks = graduations)
	
					p = plot!(p,[i], [maxFvalue[i,j]], 					 seriestype=:scatter, marker = markers[3], markersize = msize, markerstrokewidth = mcontour, label = "",		  legend=legendPos, color = colors[j], yaxis = Ygrad, xaxis = Xgrad)#, xticks = graduations)

					p = plot!(p,[i], [minFvalue[i,j]], 					 seriestype=:scatter, marker = markers[4], markersize = msize, markerstrokewidth = mcontour, label = "",		  legend=legendPos, color = colors[j], yaxis = Ygrad, xaxis = Xgrad)#, xticks = graduations)

					pollStr[j] = ""
				else
					p = plot!(p,[i], [meanFvalue[i,j]], yerr=sqrt(sFvalue[i,j]), seriestype=:scatter, legend = false, color = colors[j])#, yaxis = :log10)
					p = plot!(p,[i], [maxFvalue[i,j]], seriestype=:scatter, marker = :utriangle, legend = false, color = colors[j])#, yaxis = :log10)
					p = plot!(p,[i], [minFvalue[i,j]], seriestype=:scatter, marker = :dtriangle, legend = false, color = colors[j])#, yaxis = :log10)
				end
			end
		end
	end

	Title = "dimension $(dim)"
	title!(Title)
	xlabel!("nombre de bases positives")
	ylabel!("valeurs optimales moyennes")
	filename = "../plots/pb-test/mean-final-value"
	#filename = "../plots/pb-bb-styrene/mean-final-value"

	println("saving in $(filename)")

	cd(filename)
	savefig(p,"mean_$(dim).tex")
	cd("../../src/")
	println("done")
end

function PlotMeanFinalValue()
	#dir0 = "../run-pb-test"
	dir0 ="../run-pb-bb-styrene"
	println("extracting data from $(dir0)")
	runsPbTest = ExtractData(dir0);
	println("done")

	for dim in [8] #[2 4 8 16 32 64]
		MeanPerformanceOfIncreasingNbOfPoint(dim, true,runsPbTest)
	end
end





function ObjectifEvolutionPerIteration(dim::Int64,useLogScale::Bool, allRuns::Array{Run_t,1}, nb2nBlock::Int64)
	runs = FilterRuns("DIM",dim,allRuns)
	allIterations = BuildAllIterations(runs)

	colors = [:black, :blue, :red, :yellow, :green]
	pollStr = ["Classique" "Multi" "Oignon" "Enrichie" "LHS"]
	legendPos = :topright
	

	p = plot(dpi=300)
	println("plotting")
	for iterations in allIterations
		j = iterations.run.poll_strategy
		#if iterations.nb_iter != size(iterations.f_k
		#	Display(iterations.run)
		#end
		#to use with styrene : 
		#T = 
		#for i in size(T)[1]
		#	T[i]=T[i]+4.0
		#end
		p = plot!(p, 1:(iterations.nb_iter+1), iterations.f_k,color = colors[j] ,xaxis=:log10, yaxis=:identity, label = pollStr[j], legend=legendPos, linetype=:steppre)
		pollStr[j] = ""
	end
	println("done")


	Title = "dimension $(dim), nb2nBlock = $(nb2nBlock)"
	title!(Title)
	xlabel!("iteration")
	ylabel!("f(x^k)")


	#filename = "../plots/pb-test/evloution-per-iteration"
	filename = "../plots/pb-bb-styrene/evolution-per-iteration"

	println("saving in $(filename)")

	cd(filename)
	savefig(p,"evolution_per_iteration_dim_$(dim)_nb2nBlock_$(nb2nBlock).png")
	cd("../../../src")

	println("done")

end



function PlotObjectifEvolutionPerIteration()
	#dir0 = "../run-pb-test"
	dir0 = "../run-pb-bb-styrene"

	println("extracting data from $(dir0)")
	runsPbTest = ExtractData(dir0);
	println("done")

	#runsPbTest = FilterRuns("PB_NUM",7,runsPbTest)
	#runsPbTest=ExcludeProblems([n for n in 1:14], runsPbTest)

	println("excluding LHS strategie (no iteration there)")
	runsPbTest = ExcludePollStrategies([5], runsPbTest)
	println("done")

	println("normalize")
	runsPbTest = NormalizeRun(runsPbTest)
	println("done")


	for nb2nBlock in [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17]#[1 2 3 4 5 6 7 8 9 16 17 32 33 64 65 128 129]
		runsPbTestPerNbPt = FilterRuns("NB_2N_BLOCK", nb2nBlock, runsPbTest)
		for dim in [8]#[2 4 8 16 32 64]
			ObjectifEvolutionPerIteration(dim, true, runsPbTestPerNbPt,nb2nBlock )
		end
	end
end


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
		iterations = BuildIteration(run)
		for i in 1:size(iterations.f_k)[1]
			fx =  iterations.f_k[i]
			if fx_0-fx >= (1-tau)*(fx_0-f_L)
				return i 
			end
		end
	end

	return Inf

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