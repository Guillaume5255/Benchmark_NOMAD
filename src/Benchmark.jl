#code to benchmark poll strategies
#the problems are all defined in [-5,5]^n,
#they all have objective function positive or null, 
#they use random rotations matrix to generate instance
#the entries of the matrix are generated with a random seed that can be changed : changing the seed change the problem 
#the starting point can also be changed, but for the momet, it is arbitrarly fixed to (-4,...-4)


#first goal of this benchmark : is it effeicient to do more poll evaluation ? 
#                               which sampling strategy has the best performance in term of finding a local minima ? ==> compute the ratio nb times we do the poll/number of time we find a success


mutable struct Run_t
    dim::Int64
    pb_num::Int64
    pb_seed::Int64
    poll_strategy::Int64
    nb_2n_blocks::Int64
    eval_nb::Array{Float64,1}
    eval_f::Array{Float64,1}
end




dir0 = "../run"# "AllRuns/"*listOfDirs[1]

function ExtractData(dir::String) 
    #fills an array of Run_t objects, each object contains the data of the run : 
    #wich dimension, which problem, which seed, which strategy, which number of 2n blocks
    #all files are of the format run_dim_pbNumber_pbSeed_pollStrategy_nbOf2nBlocks_.txt
    # all problems are scalable (dim \in N^*)
    #there are 24 problems (pbNumber \in [[1;24]])
    #pbSeed \in N
    #pollStrategy \in [[1;4]] 
    #   1:classic poll
    #   2:multi poll
    #   3:oignon poll
    #   4:enriched poll
    runsList = readdir(dir)
    runs = Array{Run_t,1}([])
    for runName in runsList
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


function NormalizeRun(runs::Array{Run_t,1})
    for run in runs
        fmax = run.eval_f[1]
        for i in 1:size(run.eval_f)[1]
            run.eval_f[i]=run.eval_f[i]/fmax
            run.eval_nb[i]= run.eval_nb[i]/(run.nb_2n_blocks*2*run.dim)
        end
    end
    return runs
end


function ObjectifEvolution()
    #plots the decreasing of the objective function according to the number of evaluation
    runs = ExtractData(dir0)
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

function PerformanceOfIncreasingNbOfPoint()
    #to run with one strategy where the number of 2n blocks is increasing
    #to see the effect of this increase in the number of point at each poll step
    colors = [:blue :yellow :orange :red :black]
    runs = ExtractData(dir0)
    p = plot()
    for run in runs
        ordonnee = [run.eval_f[end]]
        abscisse = [run.eval_nb[end]]
        i = Int(log(run.nb_2n_blocks)/log(2))+1
        p=plot!(p,abscisse, ordonnee, seriestype=:scatter, color = colors[i], legend = false )
    end
    Title = "efficiency of increasing number of points "
    title!(Title)
    xlabel!("final nbEval/(2*dim*nb2nBlock) when stopping criterion is reached")
    ylabel!("final f value when stopping criterion is reached")
end

function MeanPerformanceOfIncreasingNbOfPoint()
    #to run with one strategy where the number of 2n blocks is increasing
    #to see the effect of this increase in the number of point at each poll step
    colors = [:blue :yellow :orange :red :brown :black]
    runs = ExtractData(dir0)
    p = plot()
    blockstep = 21 #nb of iterations changing nb2nBlock
    #abscisse = [2^n for n in 0:blockstep-1]  #to use when the number of 2n block is increased by multiplicating by 2
    abscisse = [3*n+1 for n in 0:blockstep-1]
    ordonnee = zeros(blockstep)
    runsSize = size(runs)[1]
    for run in runs
        #i = Int(log(run.nb_2n_blocks)/log(2))+1 #to use when the number of 2n block is increased by multiplicating by 2
        i = Int((run.nb_2n_blocks-1)/3)+1
        ordonnee[i]+= run.eval_f[end]/(runsSize/blockstep)
    end
    for j in 1:blockstep
        p = plot!(p,[abscisse[j]], [ordonnee[j]],seriestype=:scatter,  legend = false)#, color = colors[j], )
    end

    Title = "mean efficiency of increasing number of points "
    title!(Title)
    xlabel!("nb2nBlock")
    ylabel!("mean f value when stopping criterion is reached")
end
        