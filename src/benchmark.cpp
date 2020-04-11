//#include "Algos/EvcInterface.hpp"
#include "Eval/Evaluator.hpp"
#include "Algos/MainStep.hpp"
#include "Param/AllParameters.hpp"
#include "Type/LHSearchType.hpp"

#include "problems/blackbox.hpp"

#include <sys/stat.h>
#include <sstream>

// Link the evaluator of NOMAD with the blackbox
class My_Evaluator : public NOMAD::Evaluator
{
public:
	My_Evaluator(const std::shared_ptr<NOMAD::EvalParameters>& evalParams, int dim, int pb_num, int pb_seed ) : NOMAD::Evaluator(evalParams)
	{
		bb = new Blackbox(dim, pb_num, pb_seed);
		//bb->DisplayTheoricalOptimal();
	}

	~My_Evaluator() {}


	bool eval_x(NOMAD::EvalPoint &x, const NOMAD::Double& hMax, bool &countEval) const override
	{
		bool eval_ok = false;
		size_t n = x.size();
		vector<double> xtrue(n,0.0);
		for(size_t i = 0 ;i<n; i++){
			xtrue[i]=x[i].todouble();
		}

		try
		{
			//auto startEval = omp_get_wtime();
			auto f = bb->f(xtrue);
			auto stopEval = omp_get_wtime();

			//evalTime += stopEval - startEval;
			if (f[0]!='E'){
				std::ostringstream strs;
				strs << std::setprecision(10) << std::fixed << stopEval-evalTime<<" "<<f;
				std::string bbo = strs.str();
			
				x.setBBO(bbo, _evalParams->getAttributeValue<NOMAD::BBOutputTypeList>("BB_OUTPUT_TYPE"));

				eval_ok = true;
			}
		}
		catch (std::exception &e)
		{
			std::string err("Exception: ");
			err += e.what();
			throw std::logic_error(err);
		}
		countEval = true;  // count a black-box evaluation
		return eval_ok;	 // the evaluation succeeded
	}
	const double evalTime = omp_get_wtime();
	Blackbox* bb;
};

// Initialization of all parameters that do not change from one poll method to another
void initParams(NOMAD::AllParameters &p, size_t n, int pb_num, int pb_seed, int poll_strategy, int nb2nBlock )
{
	// parameters creation

	p.getDispParams()->setAttributeValue("DISPLAY_DEGREE",0);
	p.getDispParams()->setAttributeValue("DISPLAY_STATS", NOMAD::ArrayOfString("ITER EVAL BBO"));
	p.getDispParams()->setAttributeValue("DISPLAY_UNSUCCESSFUL",false);
	p.getDispParams()->setAttributeValue("DISPLAY_INFEASIBLE",false);

	p.getPbParams()->setAttributeValue("DIMENSION", n);
	if (pb_num == 25){
		p.getPbParams()->setAttributeValue("LOWER_BOUND", NOMAD::ArrayOfDouble(n, 0.0));
		p.getPbParams()->setAttributeValue("UPPER_BOUND", NOMAD::ArrayOfDouble(n, 100.0));
	}	
	else{
		p.getPbParams()->setAttributeValue("LOWER_BOUND", NOMAD::ArrayOfDouble(n, -5.0));
		p.getPbParams()->setAttributeValue("UPPER_BOUND", NOMAD::ArrayOfDouble(n, 5.0));
	}
	p.getPbParams()->setAttributeValue("MIN_MESH_SIZE",NOMAD::ArrayOfDouble(n, 0.0000000000001));

	if (pb_num == 25)
		p.getEvalParams()->setAttributeValue("BB_OUTPUT_TYPE", NOMAD::stringToBBOutputTypeList("EXTRA_O OBJ EB EB EB EB PB PB PB PB PB PB PB"));
	else
		p.getEvalParams()->setAttributeValue("BB_OUTPUT_TYPE", NOMAD::stringToBBOutputTypeList("EXTRA_O OBJ"));

	p.getEvaluatorControlParams()->setAttributeValue("MAX_BB_EVAL", NOMAD::INF_SIZE_T);
	p.getEvaluatorControlParams()->setAttributeValue("MAX_EVAL", NOMAD::INF_SIZE_T);	
	p.getEvaluatorControlParams()->setAttributeValue("OPPORTUNISTIC_EVAL",false);
	p.getEvaluatorControlParams()->setAttributeValue("BB_MAX_BLOCK_SIZE",(size_t)1);


	size_t nbIter=500; 
	//p.getEvaluatorControlParams()->setAttributeValue("MAX_BB_EVAL",nbIter*(2*n)*nb2nBlock);// NOMAD::INF_SIZE_T); //10 000 iterations

	p.getRunParams()->setAttributeValue("MAX_ITERATIONS", (size_t)nbIter);
	p.getRunParams()->setAttributeValue("MAX_ITERATION_PER_MEGAITERATION",1);
	p.getRunParams()->setAttributeValue("H_MAX_0", NOMAD::Double(10000));
	p.getRunParams()->setAttributeValue("NM_SEARCH",false);
	p.getRunParams()->setAttributeValue("SPECULATIVE_SEARCH",false);
	p.getRunParams()->setAttributeValue("ANISOTROPIC_MESH",false);
	p.getRunParams()->setAttributeValue("NB_THREADS_OPENMP",1); // to set to 1 on analytical problems and to np_cpu on real blackboxes
	p.getRunParams()->setAttributeValue("HOT_RESTART_READ_FILES", false);
	p.getRunParams()->setAttributeValue("HOT_RESTART_WRITE_FILES", false);
	p.getRunParams()->setAttributeValue("ADD_SEED_TO_FILE_NAMES",false);
	p.getRunParams()->setAttributeValue("FRAME_CENTER_USE_CACHE",false);
	p.getRunParams()->setAttributeValue("DYNAMIC_POLL",false);
	auto name = "run_"+std::to_string(n)+"_"+std::to_string(pb_num)+"_"+std::to_string(pb_seed)+"_"+std::to_string(poll_strategy)+"_";
	switch (poll_strategy)
	{
	case 1:
		p.getRunParams()->setAttributeValue("CLASSICAL_POLL",true);
		name = name + "1_";
		break;

	case 2:
		p.getRunParams()->setAttributeValue("CLASSICAL_POLL",false); //disactivate classical poll because it is activated by default

		p.getRunParams()->setAttributeValue("MULTI_POLL",true);

		name = name + std::to_string(2*n+1)+"_";
		break;

	case 3:
		p.getRunParams()->setAttributeValue("CLASSICAL_POLL",false);

		p.getRunParams()->setAttributeValue("OIGNON_POLL",true);
		p.getRunParams()->setAttributeValue("NUMBER_OF_LAYERS",(int)(nb2nBlock));

		name = name + std::to_string(nb2nBlock)+"_";
		break;
	case 4:
		p.getRunParams()->setAttributeValue("CLASSICAL_POLL",false);

		p.getRunParams()->setAttributeValue("ENRICHED_POLL",true);
		p.getRunParams()->setAttributeValue("NUMBER_OF_2N_BLOCK",nb2nBlock);
		p.getRunParams()->setAttributeValue("FRAME_LB",NOMAD::Double(0));
		p.getRunParams()->setAttributeValue("FRAME_UB",NOMAD::Double(1));

		name = name + std::to_string(nb2nBlock)+"_";
		break;
	case 5:
		p.getRunParams()->setAttributeValue("CLASSICAL_POLL",false);

		p.getRunParams()->setAttributeValue("LH_EVAL",(2*n)*nb2nBlock*nbIter); //with this parameter, there are no iteration, we just sample the whole region and evaluate all at once
		name = name + std::to_string(nb2nBlock)+"_";
		break;

	default:
		p.getRunParams()->setAttributeValue("CLASSICAL_POLL",true);
		name = name + "1_";
		break;
	}
	name = name + ".txt";
	p.getDispParams()->setAttributeValue("STATS_FILE", NOMAD::ArrayOfString(name+" ITER EVAL BBO"));

	// parameters validation
	p.checkAndComply();
}

// Run NOMAD on the problem pb_num, generated with the random seed pb_seed, in dimension dim
// Runing with the poll strategy poll_strategy
void optimize(int dim, int pb_num, int pb_seed, int poll_strategy, int nb_2n_block){
	//check if the run file already exists
	string name = "run_"+std::to_string(dim)+"_"+std::to_string(pb_num)+"_"+std::to_string(pb_seed)+"_"+std::to_string(poll_strategy)+"_"+std::to_string(nb_2n_block)+"_.txt";
	struct stat buffer;
	bool runNotExists = stat(name.c_str(),&buffer)!=0;

	if(runNotExists){
		// Initialize all parameters
		auto params = std::make_shared<NOMAD::AllParameters>();
		initParams(*params, (size_t)dim, pb_num, pb_seed, poll_strategy, nb_2n_block);

		// Custom evaluator creation
		std::unique_ptr<My_Evaluator> ev(new My_Evaluator(params->getEvalParams(), dim,  pb_num,  pb_seed ));

		//getting starting point from the problem created in the evaluator
		NOMAD::Point x0((size_t)dim); 
		std::vector<double> x0true = ev->bb->getX0();
		for(int i = 0; i<dim ; i++)
			x0[i] =  NOMAD::Double(x0true[i]);

		params->getPbParams()->setAttributeValue("X0", x0);


		auto TheMainStep = std::make_unique<NOMAD::MainStep>();
		TheMainStep->setAllParameters(params);
		TheMainStep->setEvaluator(std::move(ev));


		std::cout<<"\n\n"<<name <<" does not exists, creating it :\n\n";
		try
		{
			std::cout<<"\t Optimization : dimension = "<<dim<<", pb num = "<<pb_num<<", poll strategy = "<<poll_strategy<<"\n";
			std::time_t startTime = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());

			std::cout<<"\t Started at : "<<std::ctime(&startTime)<<"\n"; 

			auto start = omp_get_wtime();
			// Algorithm creation and execution
			TheMainStep->start();
			TheMainStep->run();
			TheMainStep->end();

			auto stop = omp_get_wtime();
			std::cout<<"Done in "<<stop-start<<" s\n\n";
		}

		catch(std::exception &e)
		{
			std::cerr << "\nNOMAD has been interrupted (" << e.what() << ")\n\n";
		}

       	NOMAD::OutputQueue::Flush();
        NOMAD::CacheBase::getInstance()->clear();

	}
	else
		 std::cout<<"\n\n"<<name <<" already exists, skipping to next one.\n\n";
}



int main (int argc, char **argv)
{
	bool useArgs = argc >1;

	int DIM_MIN=2;
	int PB_NUM_MIN=1;
	int PB_SEED_MIN=0;
	int POLL_STRATEGY_MIN=3;
	int NB_2N_BLOCK_MIN=2;

	int DIM_MAX=65;
	int PB_NUM_MAX=25;
	int PB_SEED_MAX=5;
	int POLL_STRATEGY_MAX=5;
	int NB_2N_BLOCK_MAX=65;

	if (useArgs){
		DIM_MIN = atoi(argv[1]);
		PB_NUM_MIN = atoi(argv[2]);
		PB_SEED_MIN = atoi(argv[3]);
		POLL_STRATEGY_MIN = atoi(argv[4]);
		NB_2N_BLOCK_MIN = atoi(argv[5]);
		DIM_MAX = DIM_MIN+1;
		PB_NUM_MAX = PB_NUM_MIN+1;
		PB_SEED_MAX = PB_SEED_MIN+1;
		POLL_STRATEGY_MAX = POLL_STRATEGY_MIN+1;
		NB_2N_BLOCK_MAX = NB_2N_BLOCK_MIN+1;
	}

	for(int dim = DIM_MIN ; dim <DIM_MAX ; dim=2*dim){ //every problem is scalable

		for(int pb_num = PB_NUM_MIN ; pb_num < PB_NUM_MAX ; pb_num++ ){ //problem number : 1..24

			for(int pb_seed = PB_SEED_MIN ; pb_seed < PB_SEED_MAX ; pb_seed++ ){ //to generate the random rotation matrices and constant values of each problem

				for(int poll_strategy = POLL_STRATEGY_MIN ; poll_strategy < POLL_STRATEGY_MAX ; poll_strategy++){ //1 : classical poll, 2 : multi poll, 3 : oignon poll, 4 : enriched poll

					if(poll_strategy ==1 || poll_strategy == 2) //in the case of poll strategies 1 or 2 we can't set the number of 2n blocks of points
						optimize(dim, pb_num, pb_seed, poll_strategy, 1+2*dim*(poll_strategy-1));
					else{
						for(int nb_2n_block = NB_2N_BLOCK_MIN ; nb_2n_block < NB_2N_BLOCK_MAX ; nb_2n_block=2*nb_2n_block) //we increase the number of 2n blocks to see the effect on the optimization with poll strategies 3 and 4
							optimize(dim, pb_num, pb_seed, poll_strategy, nb_2n_block);

					}
				}
			}
		}
	}
	return 0;
}
