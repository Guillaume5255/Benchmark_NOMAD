//#include "Algos/EvcInterface.hpp"
#include "Eval/Evaluator.hpp"
#include "Algos/MainStep.hpp"
#include "Param/AllParameters.hpp"

#include "problems/blackbox.hpp"
#include "Type/LHSearchType.hpp"

#include <sys/stat.h>
#include <sstream>

// Link the evaluator of NOMAD with the blackbox
class My_Evaluator : public NOMAD::Evaluator
{
public:
	My_Evaluator(const std::shared_ptr<NOMAD::EvalParameters>& evalParams) : NOMAD::Evaluator(evalParams)
	{
	}

	~My_Evaluator() {}


	bool eval_x(NOMAD::EvalPoint &x, const NOMAD::Double& hMax, bool &countEval) const override
	{
		bool eval_ok = false;
		size_t n = x.size();
		std::string  cmd = "./../src/problems/STYRENE/bb/truth.exe ";
		for(size_t i = 0 ;i<n; i++){
			cmd+=std::to_string(x[i].todouble())+" ";
		}
		//cout<<cmd<<"\n";
		try
		{
			std::array<char, 128> buffer;
			std::string bbo="";
			
			auto startEval = omp_get_wtime();
			std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);// we execute the commande and we store the result in pipe
			auto stopEval = omp_get_wtime();
 			
			if (!pipe) {
				throw std::runtime_error("popen() failed! : impossible to read blackbox output.");
			}

			while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
				bbo += buffer.data();
			}

			evalTime += stopEval - startEval;
			
			if (bbo[0]!='E'){
			//	cout<<"--"<<bbo<<"--\n";
				bbo =  std::to_string(evalTime) +" "+ bbo; // be careful ! if the blackbox returns a \n or a space at the end of the output it mess up everything !
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
		return eval_ok; // the evaluation succeeded
	}
	mutable double evalTime = 0.0;
};

// Initialization of all parameters that do not change from one poll method to another
void initParams(NOMAD::AllParameters &p, size_t n, int nb2nBlock )
{
	// parameters creation
	p.getPbParams()->setAttributeValue("DIMENSION", n);
	p.getPbParams()->setAttributeValue("LOWER_BOUND", NOMAD::ArrayOfDouble(n, 0.0)); // all var. >= 0
	p.getPbParams()->setAttributeValue("UPPER_BOUND", NOMAD::ArrayOfDouble(n, 100.0)); // all var. <= 100
	p.getPbParams()->setAttributeValue("MIN_MESH_SIZE",NOMAD::ArrayOfDouble(n, 0.00000001));

	p.getEvalParams()->setAttributeValue("BB_OUTPUT_TYPE", NOMAD::stringToBBOutputTypeList("EXTRA_O OBJ EB EB EB EB PB PB PB PB PB PB PB"));

	p.getEvaluatorControlParams()->setAttributeValue("MAX_BB_EVAL", NOMAD::INF_SIZE_T);
	p.getEvaluatorControlParams()->setAttributeValue("MAX_EVAL", NOMAD::INF_SIZE_T);	
	p.getEvaluatorControlParams()->setAttributeValue("OPPORTUNISTIC_EVAL",false);
	p.getEvaluatorControlParams()->setAttributeValue("BB_MAX_BLOCK_SIZE",(size_t)1);




	size_t nbIter=500; // to change in optimize too
	//p.getEvaluatorControlParams()->setAttributeValue("MAX_BB_EVAL",nbIter*(2*n)*nb2nBlock);// NOMAD::INF_SIZE_T); //10 000 iterations

	p.getRunParams()->setAttributeValue("MAX_ITERATIONS", (size_t)nbIter);
	p.getRunParams()->setAttributeValue("MAX_ITERATION_PER_MEGAITERATION",1);
	p.getRunParams()->setAttributeValue("H_MAX_0", NOMAD::Double(10000));
	p.getRunParams()->setAttributeValue("NM_SEARCH",false);
	p.getRunParams()->setAttributeValue("SPECULATIVE_SEARCH",false);
	p.getRunParams()->setAttributeValue("ANISOTROPIC_MESH",false);
	p.getRunParams()->setAttributeValue("NB_THREADS_OPENMP",3); // to set to 72 on CASIR and to set on 11 at GERAD
	p.getRunParams()->setAttributeValue("HOT_RESTART_READ_FILES", false);
	p.getRunParams()->setAttributeValue("HOT_RESTART_WRITE_FILES", false);
	p.getRunParams()->setAttributeValue("ADD_SEED_TO_FILE_NAMES",false);
	p.getRunParams()->setAttributeValue("FRAME_CENTER_USE_CACHE",false);

	p.getDispParams()->setAttributeValue("DISPLAY_DEGREE",2);
	p.getDispParams()->setAttributeValue("DISPLAY_STATS", NOMAD::ArrayOfString("EVAL BBO"));
	p.getDispParams()->setAttributeValue("DISPLAY_UNSUCCESSFUL",false);
	p.getDispParams()->setAttributeValue("DISPLAY_INFEASIBLE",false);
	// parameters validation
	p.checkAndComply();
}

// Run NOMAD on the problem pb_num, generated with the random seed pb_seed, in dimension dim
// Runing with the poll strategy poll_strategy and starting point x0
void optimize(int dim, int pb_num, int pb_seed,int poll_strategy, int nb_of_2n_block){
	//std::cout<<"building the blackbox\n";
	//auto start = omp_get_wtime();
	//auto blackbox = std::make_shared<Blackbox>(dim, pb_num, pb_seed);
	//auto stop = omp_get_wtime();
	//std::cout<<"done in "<<stop-start<<" s\n\n";

	// Initialize all parameters
	auto params = std::make_shared<NOMAD::AllParameters>();
	initParams(*params, (size_t)dim, nb_of_2n_block);


	auto name = "run_"+std::to_string(dim)+"_"+std::to_string(pb_num)+"_"+std::to_string(pb_seed)+"_"+std::to_string(poll_strategy)+"_";
	int nbIter = 500; // to change in initParams too, here it is useful only for the LHS
	switch (poll_strategy)
	{
	case 1:
		params->getRunParams()->setAttributeValue("CLASSICAL_POLL",true);
		name = name + "1_";
		break;

	case 2:
		params->getRunParams()->setAttributeValue("CLASSICAL_POLL",false); //disactivate classical poll because it is activated by default

		params->getRunParams()->setAttributeValue("MULTI_POLL",true);

		name = name + std::to_string(2*dim+1)+"_";
		break;

	case 3:
		params->getRunParams()->setAttributeValue("CLASSICAL_POLL",false);

		params->getRunParams()->setAttributeValue("OIGNON_POLL",true);
		params->getRunParams()->setAttributeValue("NUMBER_OF_LAYERS",(int)(nb_of_2n_block));

		name = name + std::to_string(nb_of_2n_block)+"_";
		break;
	case 4:
		params->getRunParams()->setAttributeValue("CLASSICAL_POLL",false);

		params->getRunParams()->setAttributeValue("ENRICHED_POLL",true);
		params->getRunParams()->setAttributeValue("NUMBER_OF_2N_BLOCK",nb_of_2n_block);
		params->getRunParams()->setAttributeValue("FRAME_LB",NOMAD::Double(0));
		params->getRunParams()->setAttributeValue("FRAME_UB",NOMAD::Double(1));

		name = name + std::to_string(nb_of_2n_block)+"_";
		break;
	case 5:
		params->getRunParams()->setAttributeValue("CLASSICAL_POLL",false);

		params->getRunParams()->setAttributeValue("LH_EVAL",(2*dim)*nb_of_2n_block*nbIter); //with this parameter, there are no iteration, we just sample the whole region and evaluate all at once
		name = name + std::to_string(nb_of_2n_block)+"_";
		break;

	default:
		params->getRunParams()->setAttributeValue("CLASSICAL_POLL",true);
		name = name + "1_";
		break;
	}
	name = name + ".txt";

	params->getDispParams()->setAttributeValue("STATS_FILE", NOMAD::ArrayOfString(name+" EVAL BBO"));


	// Custom evaluator creation
	std::unique_ptr<My_Evaluator> ev(new My_Evaluator(params->getEvalParams()));




	NOMAD::Point x0((size_t)dim); //getting starting point from the problem created in the evaluator
	//srand(pb_seed+2);//+2 becaus cf blackbox.cpp and the doc about srand(0) and srand(1)
	//for(int i = 0; i<dim ; i++)
	//	x0[i] =  NOMAD::Double(((double)rand()/(double)RAND_MAX)*100);
	// in a first stand we only use one point as starting point, because they may be inefeasible, we need feasible points.
	x0[0]=54.0;
	x0[1]=66.0;
	x0[2]=86.0;
	x0[3]=8.0;
	x0[4]=29;
	x0[5]=51;
	x0[6]=32;
	x0[7]=15;
	params->getPbParams()->setAttributeValue("X0", x0);


	auto TheMainStep = std::make_unique<NOMAD::MainStep>();
	TheMainStep->setAllParameters(params);
	TheMainStep->setEvaluator(std::move(ev));

	struct stat buffer;
	if(stat(name.c_str(),&buffer)!=0){ //check if the run file already exists
		std::cout<<"\n"<<name <<" does not exists, creating it :\n";
		try
		{
			std::cout<<"Optimization : dimension = "<<dim<<", pb num = "<<pb_num<<", poll strategy = "<<poll_strategy<<"\n";

			auto start = omp_get_wtime();
			// Algorithm creation and execution
			TheMainStep->start();
			TheMainStep->run();
			TheMainStep->end();

			auto stop = omp_get_wtime();
			std::cout<<"done in "<<stop-start<<" s\n\n";
		}

		catch(std::exception &e)
		{
			std::cerr << "\nNOMAD has been interrupted (" << e.what() << ")\n\n";
		}


       		NOMAD::OutputQueue::Flush();
        	NOMAD::CacheBase::getInstance()->clear();

	}
	else
		 std::cout<<"\n"<<name <<" already exists, skipping to next one.\n";
}



int main (int argc, char **argv)
{
	bool useArgs = argc >1;

	int DIM_MIN=8; // fixe pour sytrene
	int PB_NUM_MIN=25; //we call styrene the 25th problem
	int PB_SEED_MIN=0; // use the seed to change the sarting point
	int POLL_STRATEGY_MIN=3;
	int NB_2N_BLOCK_MIN=32;

	int DIM_MAX=9;
	int PB_NUM_MAX=26;
	int PB_SEED_MAX=1;
	int POLL_STRATEGY_MAX=5;
	int NB_2N_BLOCK_MAX=33;

	if (useArgs){
		//DIM_MIN = atoi(argv[1]);
		//PB_NUM_MIN = atoi(argv[2]);
		PB_SEED_MIN = atoi(argv[3]);
		POLL_STRATEGY_MIN = atoi(argv[4]);
		NB_2N_BLOCK_MIN = atoi(argv[5]);
		//DIM_MAX = DIM_MIN+1;
		//PB_NUM_MAX = PB_NUM_MIN+1;
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
