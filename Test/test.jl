
allplots = [plot()]

for i in 1:10
    n = 50+10*i
    push!(allplots, plot!(allplots[i],1:n,rand(n), leg= false))
end

mutable struct StrategyData_t
    dim::Int64 #the dimension must be the same for all runs made with the current strategy otherwise the expected number of evaluations to get a good value of f is 
    poll_strategy::Int64 #we focus on a single strategy so this field must be the same for all the runs
    nb_2nBlock::Int64
    
    nb_runs::Int64

    related_runs::Array{Run_t,1}
    mean_finalValue::Float64
    mean_nbEval::Int64
    function StrategyData_t(runs::Array{Run_t,1})
        nb_runs = size(runs)[1]
        mean_nbEval=0
        mean_finalValue=0
        for run in runs
            mean_nbEval+=run.eval_nb[end]
            mean_finalValue+=run.eval_f[end]
        end
        new(runs[1].poll_strategy, runs[1].dim)
    end
end



listOfDirs=[    "fixedDim_allPbNum_allPbSeed_allStrategy_fixedNbOf2nBlock",     #which strategy is better  
                "fixedDim_fixedPbNum_allPbSeed_allStrategy_fixedNbOf2nBlock",   #which strategy is better on a specific problem
                "allDim_fixedPbNum_allPbSeed_allStrategy_fixedNbOf2nBlock",     #effect of the dimension over all the strategies
                "allDim_fixedPbNum_allPbSeed_fixedStrategy_fixedNbOf2nBlock",   #effect of the dimension over a specific strategy
                "fixedDim_allPbNum_allPbSeed_fixedStrategy_allNbOf2nBlock",     #effect of the number of points for a fixed strategy (only 3 and 4)
            ]