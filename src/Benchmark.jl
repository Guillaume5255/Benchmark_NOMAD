#code to benchmark poll strategies
#the problems are all defined in [-5,5]^n,
#they all have objective function positive or null, 
#they use random rotations matrix to generate instance
#the entries of the matrix are generated with a random seed that can be changed : changing the seed change the problem 
#the starting point can also be changed, but for the momet, it is arbitrarly fixed to (-4,...-4)


#first goal of this benchmark : is it effeicient to do more poll evaluation ? 
#								which sampling strategy has the best performance in term of finding a local minima ? ==> compute the ratio nb times we do the poll/number of time we find a success

mutable struct Run_t
	dim::Int64
	pb_num::Int64
	pb_seed::Int64
	poll_strategy::Int64
	nb_2n_blocks::Int64
	eval_nb::Array{Float64,1}
	eval_f::Array{Float64,1}
end

function Display(run::Run_t)
	str = "$(run.dim)_$(run.pb_num)_$(run.pb_seed)_$(run.poll_strategy)_$(run.nb_2n_blocks)"
	println(str)
end


dir0 = "../run"# "AllRuns/"*listOfDirs[1]


function FindEmptyRun()
	runs = ExtractData(dir0)
	for run in runs
		if run.eval_f == []
			Display(run)
		end
	end
end


function ExtractData(dir::String) 
	#fills an array of Run_t objects, each object contains the data of the run : 
	#wich dimension, which problem, which seed, which strategy, which number of 2n blocks
	#all files are of the format run_dim_pbNumber_pbSeed_pollStrategy_nbOf2nBlocks_.txt
	# all problems are scalable (dim \in N^*)
	#there are 24 problems (pbNumber \in [[1;24]])
	#pbSeed \in N
	#pollStrategy \in [[1;4]] 
	#	1:classic poll
	#	2:multi poll
	#	3:oignon poll
	#	4:enriched poll
	runsList = readdir(dir)
	runs = Array{Run_t,1}([])
	for runName in runsList
		#println(runName)
		runAttr=split(runName, "_")
		if runAttr[1]=="run" #we only try to read run files
			runData = readdlm(dir*"/"*runName)

			run=Run_t(
			parse(Int,runAttr[2]),
			parse(Int,runAttr[3]),
			parse(Int,runAttr[4]),
			parse(Int,runAttr[5]),
			parse(Int,runAttr[6]),
			runData[:,1],
			runData[:,2])
			#println("minimum f value : "*string(minimum(run.eval_f)))
			#println("run_"*string(run.pb_num)*"_"*string(run.pb_seed)*"_"*string(run.poll_strategy))
			push!(runs, run)
		end
	end
	return runs
end

function ExcludeProblems(pbNum::Array{Int64,1},runs::Array{Run_t,1} )
	newRuns = Array{Run_t,1}([])

	for run in runs
		addRun = true 
		for pn in pbNum
			if run.pb_num == pn 
				addRun = false
				break
			end
		end
		if addRun
			push!(newRuns, run)
		end
	end
	return newRuns
end


function FilterRuns(att::String,value::Int64, runs::Array{Run_t,1})
	newRuns = Array{Run_t,1}([])
	if att == "DIM"
		for run in runs
			if run.dim == value
				push!(newRuns, run)
			end
		end
	elseif att == "PB_NUM"
		for run in runs
			if run.pb_num >= value
				push!(newRuns, run)
			end
		end
	elseif att == "PB_SEED"
		for run in runs
			if run.pb_seed == value
				push!(newRuns, run)
			end
		end
	elseif att == "POLL_STRATEGY"
		for run in runs
			if run.poll_strategy == value
				push!(newRuns, run)
			end
		end
	elseif att == "NB_2N_BLOCK"
		for run in runs
			if run.nb_2n_blocks == value
				push!(newRuns, run)
			end
		end
	else 
		println("attribute $attr unknown, returning not filtered runs")
		return runs
	end
	return newRuns
end

function NormalizeRun(runs::Array{Run_t,1})
	for run in runs
		fmax = run.eval_f[1]
		for i in 1:size(run.eval_f)[1]
			run.eval_f[i] = run.eval_f[i]+1
			run.eval_nb[i] = run.eval_nb[i]/(run.nb_2n_blocks*2*run.dim)
		end
	end
	return runs
end

function ObjectifEvolution()
	#plots the decreasing of the objective function according to the number of evaluation
	#runs = ExtractData(dir0)
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

function ObjectifFinalValue() 
	#plots the final value of the objectif function (at the end of the optimization)
	#to apply to one problem run with different seed and starting point
	# note : increasing the number of points sampled with the dimension and looking at how the best objectif function value is evolving tells us if the strategy is scalable or not 
	runs = ExtractData(dir0)
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
		Fvalue = run.eval_f[end]#+1
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
	Title = "final value"#, dimension = "*string(runs[1].dim)
	p = plot() 
	p = plot!(p,finalValueEClassic,finalValueFClassic,seriestype=:scatter, color = colors[1], label = Label[1])#,xaxis=xscale, yaxis=yscale)

	p = plot!(p,finalValueEMulti,finalValueFMulti,seriestype=:scatter, color = colors[2], label = Label[2])#,xaxis=xscale, yaxis=yscale,)

	p = plot!(p,finalValueEOignon,finalValueFOignon,seriestype=:scatter, color = colors[3], label = Label[3])#,xaxis=xscale, yaxis=yscale,)

	p = plot!(p,finalValueEEnriched,finalValueFEnriched,seriestype=:scatter, color = colors[4], label = Label[4])#,xaxis=xscale, yaxis=yscale,)
	title!(Title)
	xlabel!("nbEval/(2*dim*nb2nBlock) when stopping criterion is reached")
	ylabel!("f value when stopping criterion is reached")
	savefig("ObjectifFinalValue.png")

	return p
	
end

function MeanFinalStats()
	runs = ExtractData(dir0)
	#normalizedRuns = NormalizeRun(runs)
	Fvalue = [0.0 0.0 0.0 0.0]
	finalEval = [0.0 0.0 0.0 0.0]
	strategyCounter = [0.0 0.0 0.0 0.0]
	for run in runs
		strategyCounter[run.poll_strategy] +=1
	end
	for run in runs#normalizedRuns
		i = run.poll_strategy
		Fvalue[i] += run.eval_f[end]/strategyCounter[i]
		finalEval[i] += run.eval_nb[end]/strategyCounter[i]
	end

	colors = [:black, :blue, :red, :yellow] #classic poll, multi poll, oignon poll, enriched poll
	scales = [:log, :linear]
	xscale = scales[1]
	yscale = scales[1]
	Label=["Classical Poll" "Multi Poll" "Oignon Poll" "Enriched Poll"]
	Title = "Mean values"

	p = plot()
	for i = 1:4
		abscisse = [finalEval[i]]
		ordonnee = [Fvalue[i]]
		p = plot!(p,abscisse,ordonnee,seriestype=:scatter, color = colors[i], label = Label[i])
	end
	title!(Title)
	xlabel!("mean nbEval/(2*dim*nb2nBlock) when stopping criterion is reached")
	ylabel!("mean f value when stopping criterion is reached")
end

function PerformanceOfIncreasingNbOfPoint(dim::Int, useLogScale::Bool)
	#to run with one strategy where the number of 2n blocks can be set 
	#to see the effect of this increase in the number of point at each poll step
	colors = [:black, :blue, :red, :yellow]

	runs = ExtractData(dir0);
	runs = FilterRuns("DIM",dim,runs)
	#runs = FilterRuns("PB_SEED",3,runs)
	runs = ExcludeProblems([1, 2, 5, 10, 11, 12, 13, 14], runs)
	if useLogScale
		runs = NormalizeRun(runs)
	end
	pollStr = ["Classical Poll" "Multi Poll" "Oignon Poll" "Enriched Poll"]
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
end

function MeanPerformanceOfIncreasingNbOfPoint(dim::Int64,useLogScale::Bool)
	#to run with one strategy where the number of 2n blocks is increasing
	#to see the effect of this increase in the number of point at each poll step
	runs = ExtractData(dir0);
	runs = FilterRuns("DIM",dim,runs)
	#runs = FilterRuns("PB_SEED",3,runs)
	runs = ExcludeProblems([1, 2, 5, 10, 11, 12, 13, 14], runs)
	println(size(runs)[1])

	if useLogScale
		runs = NormalizeRun(runs)
	end
	maxNb2nBlock = 0 # maximum number of 2n block used (usally for the multi poll)
	for run in runs
		if run.nb_2n_blocks>maxNb2nBlock
			maxNb2nBlock = run.nb_2n_blocks
		end
	end

	RunsCounter = zeros(maxNb2nBlock, 4) #counts the number of runs made with the i-th strategy (columns) on specific nb2nBlock (lines)
	maxFvalue = zeros(maxNb2nBlock, 4)
	minFvalue = zeros(maxNb2nBlock, 4)
	for i in 1:maxNb2nBlock
		for j in 1:4
			minFvalue[i,j] = Inf
		end
	end
	meanFvalue = zeros(maxNb2nBlock, 4)
	sFvalue = zeros(maxNb2nBlock, 4)

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
	#println(RunsCounter)

	for run in runs
		j = run.poll_strategy
		i = run.nb_2n_blocks
		if RunsCounter[i,j] > 0
			meanFvalue[i,j]+= (run.eval_f[end])/RunsCounter[i,j]
		end
	end
	#println(meanFvalue)

	for run in runs
		j = run.poll_strategy
		i = run.nb_2n_blocks
		if RunsCounter[i,j] > 0
			sFvalue[i,j]+= ((run.eval_f[end]-meanFvalue[i,j])^2)/(RunsCounter[i,j]-1)
		end
	end
	#println(sFvalue)

	p = plot()
	colors = [:black, :blue, :red, :yellow]
	pollStr = ["Classical Poll" "Multi Poll" "Oignon Poll" "Enriched Poll"]
	legendPos = :topleft
	for run in runs 
		j = run.poll_strategy
		i = run.nb_2n_blocks
		if RunsCounter[i,j]>0 #we only plot when there exist at least one run 
			if useLogScale 
				p = plot!(p,[i], [meanFvalue[i,j]], seriestype=:scatter, label = pollStr[j],legend=legendPos, color = colors[j], xaxis = :log10, yaxis = :log2)
				#p = plot!(p,[i], [meanFvalue[i,j]+sqrt(sFvalue[i,j])], seriestype=:scatter,  marker = :square, label = "",legend=legendPos, color = colors[j], xaxis = :log2, yaxis = :log10)
				p = plot!(p,[i], [maxFvalue[i,j]], seriestype=:scatter, marker = :utriangle, label = "",legend=legendPos, color = colors[j], xaxis = :log2, yaxis = :log10)
				#p = plot!(p,[i], [minFvalue[i,j]], seriestype=:scatter, marker = :dtriangle, label = "",legend=legendPos, color = colors[j], xaxis = :log2, yaxis = :log10)
				pollStr[j] = ""
			else
				p = plot!(p,[i], [meanFvalue[i,j]], yerr=sqrt(sFvalue[i,j]), seriestype=:scatter, legend = false, color = colors[j])#, yaxis = :log10)
				p = plot!(p,[i], [maxFvalue[i,j]], seriestype=:scatter, marker = :utriangle, legend = false, color = colors[j])#, yaxis = :log10)
				p = plot!(p,[i], [minFvalue[i,j]], seriestype=:scatter, marker = :dtriangle, legend = false, color = colors[j])#, yaxis = :log10)
			end
		end
	end

	Title = "dimension $(dim)"
	title!(Title)
	xlabel!("nb 2n blocks")
	ylabel!("mean optimal value")

	cd("../plots")
	savefig("mean_$(dim)")
end
