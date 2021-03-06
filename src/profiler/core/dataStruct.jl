mutable struct Run_t
	dim::Int64
	pb_num::Int64
	pb_seed::Int64
	poll_strategy::Int64
	nb_2n_blocks::Int64
	iter::Array{Int64,1}
	eval_nb::Array{Int64,1}
	eval_time::Array{Float64,1}	
	eval_f::Array{Float64,1}
	
end

Base.copy(run::Run_t) = Run_t(run.dim, run.pb_num, run.pb_seed, run.poll_strategy, run.nb_2n_blocks, run.iter, run.eval_nb, run.eval_time, run.eval_f)

mutable struct Iter_t
	run::Run_t
	f_k::Array{Float64,1} #array with as much elements as the number of iterations, element k is the best value of f obtainted at iteration k
	nb_iter::Int64 
end
