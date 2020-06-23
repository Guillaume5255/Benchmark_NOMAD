#code to benchmark poll strategies
#the problems are all defined in [-5,5]^n,
#they all have objective function positive or null, 
#they use random rotations matrix to generate instance
#the entries of the matrix are generated with a random seed that can be changed : changing the seed change the problem 
#the starting point can also be changed, but for the momet, it is arbitrarly fixed to (-4,...-4)

using Plots
pgfplots()
#gr()
#gadfly()
#pyplot()

using LaTeXStrings
include("core/helperFunctions.jl")

function getStats(runs::Array{Run_t,1}, pollStrategy::Int64, nb2nblock::Int64)
	maxVal = 0.0
	minVal = Inf
	mean = 0.0
	sigma = 0.0
	runs = FilterRuns("POLL_STRATEGY", pollStrategy, runs)
	runs = FilterRuns("NB_2N_BLOCK", nb2nblock, runs)
	counter = 0
	for run in runs
		counter += 1 
		if run.eval_f[end]>maxVal
			maxVal = run.eval_f[end]
		end
		if run.eval_f[end]<minVal
			minVal = run.eval_f[end]
		end
		mean += run.eval_f[end]
	end
	mean = mean/counter
	for run in runs
		sigma += (mean - run.eval_f[end])*(mean - run.eval_f[end])
	end
	sigma = sqrt(sigma)/(counter-1)
	return counter, maxVal, minVal, mean, sigma
end


function plotStats(runs::Array{Run_t,1}, dim::Int64)
	markers = [:circle, :square, :utriangle, :dtriangle]
	msize = 5
	mcontour = 0.5

	colors = [:black, :blue, :red, :yellow, :green]
	pollStr = ["Classique" "Multi" "Oignon" "Enrichie" "LHS"]
	legendPos = :topright
	Xgrad = :log2
	Ygrad = :log2
	p = plot(dpi=300,yaxis = :log10, seriestype=:scatter, legend=legendPos )
	for ps in [1 2 3 4 5]
		for nb2nblock in [1 2 4 8 16 32 64 2*dim+1]
			counter, maxValue, minValue, mean, sigma = getStats(runs, ps, nb2nblock)
			if counter > 0 #if there exists runs for this combinaison of ps and nb2nblock
				p = plot!(p, [nb2nblock], [mean],
					color = colors[ps], marker = markers[1], markersize = msize, markerstrokewidth = mcontour,
					label = pollStr[ps])
				p = plot!(p, [nb2nblock], [maxValue],
					color = colors[ps], marker = markers[3], markersize = msize, markerstrokewidth = mcontour,
					label = "")
				pollStr[ps] = ""
			end
		end
	end
	
	Title = "\$n=$(dim)\$"
	title!(Title)
	xlabel!("nombre de bases positives")
	ylabel!("valeurs optimales moyennes et maximales")
	
	outputFolder = "/plots/pb-test/meanFinalValueRevisited"
	outputName = "dim_$(dim)"
	println("saving in $(outputFolder)")

	currentPath = pwd()
	absolutePath = GetAbsolutePath()
	cd(absolutePath*outputFolder)
	
	savefig(p,"mfv_"*outputName*".svg")
    
	cd(currentPath)

	println("done")

end

function InfluenceOfNbPoints()
	dir0="/run-pb-test-static-casir"
	dir1 = "/run-pc-perso-confinement/run-pb-test"
	println("extracting data from $(dir1)")
	runsCasir = OldExtractData(dir0);
	allRuns = [ExtractData(dir1*"/compareGeometry");
			ExtractData(dir1*"/static");
			FilterRuns("POLL_STRATEGY", 5, runsCasir);
			ExtractData(dir1*"/classical-poll") ]	
	println("done")

	for dim in [2 4 8 16 32]
		runs = FilterRuns("DIM",dim, allRuns)
		plotStats(runs,dim)
	end
end
	
