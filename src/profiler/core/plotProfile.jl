include("data-perf-profile.jl")
using Colors
using Plots
pgfplots()
#gr()
#gadfly()
#pyplot()

using LaTeXStrings


function GetProblemsDimension(runs::Array{Run_t, 1},nbProblems::Int64) #returns an array a where a[i] is the dimension of ith problem
    problemDimension = zeros(1,nbProblems)
    for run in runs
        problemDimension[run.pb_num]=run.dim
    end
    return problemDimension
end

#get a list of dimensions used in the runs
function GetDims(runs::Array{Run_t,1})
	maxDim=1
	for run in runs
		if maxDim < run.dim
			maxDim = run.dim
		end
	end

	allDims = zeros(1,maxDim)
	for run in runs
		allDims[run.dim]=run.dim
	end

	dims = []
	for dim in allDims
		if dim > 0
			push!(dims, Int(dim))
		end
	end
	return dims
end

function SetRealPbNumber(runs::Array{Run_t,1})
	realNbProblems = 24
	for run in runs
		run.pb_num = realNbProblems*(run.pb_seed) + run.pb_num
	end
end

#generic function that plots the profiles made on some runs in a specific window 
function PlotProfile(attr::String, tau::Float64, runs::Array{Run_t,1}, alphaMax::Float64, kappaMax::Float64, algoNames::Array{String, 1}, algoColors::Array{Symbol, 1}, outputFolder::String, outputName::String, Title::String)
	blackAndWhitePlot = false	
	if size(algoColors)[1] == 0
		if !blackAndWhitePlot
			algoColors = distinguishable_colors(size(algoNames)[1])
		else
			algoColors[:black, :grey25, :grey39, :grey64, :grey81, :grey95 ] #TODO change this to get arbitrary number of colors
		end
	end
	
	tps_matrix = tpsMatrix(tau,runs,attr)
	rps_matrix = rpsMatrix(tps_matrix) 
	nbProblems = size(tps_matrix)[1]


	normalized_tps_matrix = copy(tps_matrix)

	# this step is used in data profile in the case where we look at how behaves algorithms in term of evaluation,  it has no sens when we are interested by profiles in iteration or in time 
	if attr == "EVAL"
		problemsDimensions = GetProblemsDimension(runs,nbProblems)
		for p in 1:nbProblems
			normalized_tps_matrix[p,:] = normalized_tps_matrix[p,:]/problemsDimensions[p] #to modify, dimension is not the same for each problem
		end
	end

	alphaMin = 0.9
	kappaMin = -0.1
	alphaStep = (alphaMax-alphaMin)/150.0
	kappaStep = (kappaMax-kappaMin)/150.0
	alphaPP = alphaMin:alphaStep:alphaMax
	kappaDP = kappaMin:kappaStep:kappaMax
	
	
    
	legendPos = :bottomright
	PPplot = plot(dpi=300,ylims = (0,1))
	DPplot = plot(dpi=300,ylims = (0,1))
	
	linestyles = [:solid, :dash, :dot, :dashdot, :dashdotdot, :dot] #TODO to modify to generate an arbitrary number of linestyles
	markers = [:diamond, :utriangle, :pentagon, :circle, :square, :dtriangle] #TODO to modify to generate an arbitrary number or marker types
	msize = 5
	mcontour = 0.5
	nbSolvers = size(algoNames)[1]
	for s in 1:nbSolvers
		markerSpace = 20-Int(floor(nbSolvers/2))+s
		mr=s:markerSpace:150 #marker rate : made folowwing this idea : 
		#https://stackoverflow.com/questions/56048096/supressing-some-labels-in-legend-or-putting-sampled-markers
		PPValue =  [PerformanceProfile(alpha, s, rps_matrix) for alpha in alphaPP]
		DPValue =  [DataProfile(kappa, s, normalized_tps_matrix) for kappa in kappaDP]
		colorForLine = algoColors[s]
		if blackAndWhitePlot
			colorForLine = :black
		end
		PPplot = plot!(PPplot,alphaPP, PPValue, 
				linecolor=colorForLine, 
				label = "", 
				legend=legendPos, 
				linetype=:steppre, 
				linestyle = linestyles[s])
				#marker = markers[s])#plots the line
		PPplot = plot!(PPplot,alphaPP[mr], PPValue[mr], 
				#linecolor=algoColors[s], 
				label = algoNames[s], 
				legend=legendPos, 
				linetype=:scatter,
				#linewidth = 1,
				#linestyle = linestyles[s],
				marker = markers[s],
				markersize = msize,
				markercolor=algoColors[s],
				markerstrokewidth = mcontour)#plots the marker

		DPplot = plot!(DPplot,kappaDP, DPValue, 
				linecolor=colorForLine, 
				label = "", 
				legend=legendPos, 
				linetype=:steppre, 
				linestyle = linestyles[s])
				#marker = markers[s])#plots the line
		DPplot = plot!(DPplot,kappaDP[mr], DPValue[mr], 
				#linecolor=algoColors[s], 
				label = algoNames[s], 
				legend=legendPos, 
				linetype=:scatter,
				#linewidth = 1,
				#linestyle = linestyles[s],
				marker = markers[s],
				markersize = msize,
				markercolor=algoColors[s],
				markerstrokewidth = mcontour)#plots the marker


	end

	xlabel!(PPplot,"\$\\alpha ($attr) \$")
	xlabel!(DPplot,"\$\\kappa ($attr) \$")

	ylabel!(PPplot,"proportion de problemes resolus")
	ylabel!(DPplot,"proportion de problemes resolus")

	title!(PPplot,Title)
	title!(DPplot,Title)

	println("saving in $(outputFolder)")

	currentPath = pwd()
	absolutePath = GetAbsolutePath()

	cd(absolutePath*outputFolder)
	
	savefig(PPplot,"pp_"*outputName*".svg")
	savefig(DPplot,"dp_"*outputName*".svg")
    
	cd(currentPath)

	println("done")
end

# if size(algoName) = s, run.poll_strategy must be in [[1,s]]
function ConvergencePlot(attr::String, runs::Array{Run_t,1}, algoNames::Array{String, 1}, algoColors::Array{Symbol, 1}, outputFolder::String, outputName::String, Title::String)
	convergencePlot = plot(dpi=300)
	legendPos = :topright
	for run in runs
		s = run.poll_strategy
		if attr == "EVAL"
			convergencePlot = plot!(convergencePlot, run.eval_nb, run.eval_f, color=algoColors[s], label = algoNames[s], legend=legendPos, linetype=:steppre, xaxis=:log10)
			xlabel!(convergencePlot,"évaluations")
		end
		if attr == "ITER"
			convergencePlot = plot!(convergencePlot, run.iter.+1, run.eval_f, color=algoColors[s], label = algoNames[s], legend=legendPos, linetype=:steppre, xaxis=:log10)
			xlabel!(convergencePlot,"itérations")
		end
		if attr == "TIME"
			convergencePlot = plot!(convergencePlot, run.eval_time, run.eval_f, color=algoColors[s], label = algoNames[s], legend=legendPos, linetype=:steppre, xaxis=:log10)
			xlabel!(convergencePlot,"temps (s)")
		end
		algoNames[s]=""
	end



	ylabel!(convergencePlot,"valeur de l'objectif")

	title!(convergencePlot,Title)

	println("saving in $(outputFolder)")

	currentPath = pwd()
	absolutePath = GetAbsolutePath()
	cd(absolutePath*outputFolder)
	
	savefig(convergencePlot,"cp_"*outputName*".svg")
    
	cd(currentPath)

	println("done")

end

