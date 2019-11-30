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

    eval_nb::Array{Float64,1}
    eval_f::Array{Float64,1}
end




dir0 = "runtest"# "AllRuns/"*listOfDirs[1]

function ExtractData(dir::String) 
    #fills an array of Run_t objects, each object contains the data of the run : 
    #wich dimension, which problem, which seed, which strategy
    #all files are of the format run_dim_pbNumber_pbSeed_pollStrategy_.txt
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
        fmax = maximum(run.eval_f)
        for i in 1:size(run.eval_f)[1]
            run.eval_f[i]=run.eval_f[i]/fmax
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
        Fvalue = [f+0.000000001 for f in run.eval_f]
        push!(allplots, plot!(allplots[j],run.eval_nb, Fvalue, color = colors[i] ,xaxis=:log, yaxis=:log,m=markers[j], leg = false,linetype=:steppre)) #yaxis=:log) )# fmt = :png) # reuse = true m = markers[i]
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
    normalizedRuns = NormalizeRun(runs)
    finalValueEClassic = []
    finalValueFClassic = []

    finalValueEMulti = []
    finalValueFMulti = []

    finalValueEOignon = []
    finalValueFOignon = []

    finalValueEEnriched = []
    finalValueFEnriched = []

    for run in normalizedRuns
        i = run.poll_strategy
        Fvalue = 1+run.eval_f[end]
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
    p = plot!(p,finalValueEClassic,finalValueFClassic,seriestype=:scatter, color = colors[1],xaxis=xscale, yaxis=yscale, label = Label[1])

    p = plot!(p,finalValueEMulti,finalValueFMulti,seriestype=:scatter, color = colors[2],xaxis=xscale, yaxis=yscale, label = Label[2])

    p = plot!(p,finalValueEOignon,finalValueFOignon,seriestype=:scatter, color = colors[3],xaxis=xscale, yaxis=yscale, label = Label[3])

    p = plot!(p,finalValueEEnriched,finalValueFEnriched,seriestype=:scatter, color = colors[4],xaxis=xscale, yaxis=yscale, label = Label[4])
    title!(Title)
    xlabel!("nbEval when stopping criterion is reached")
    ylabel!("f value when stopping criterion is reached")
    savefig("ObjectifFinalValue.png")

    return p
    
end

function PerformanceOfIncreasingNbOfPoint()

end
