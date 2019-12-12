//#include "Algos/EvcInterface.hpp"
#include "Eval/Evaluator.hpp"
#include "Algos/MainStep.hpp"
#include "Param/AllParameters.hpp"

#include "problems/blackbox.hpp"

// Link the evaluator of NOMAD with the blackbox
class My_Evaluator : public NOMAD::Evaluator
{
public:
    My_Evaluator(const std::shared_ptr<NOMAD::EvalParameters>& evalParams,const std::shared_ptr<Blackbox>& blackbox )
        : NOMAD::Evaluator(evalParams) 
    {
        bb = blackbox;
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
            double f = bb->f(xtrue);
            
            std::string bbo = to_string(f);
            x.setBBO(bbo, _evalParams->getAttributeValue<NOMAD::BBOutputTypeList>("BB_OUTPUT_TYPE"));

            eval_ok = true;
        }
        catch (std::exception &e)
        {
            std::string err("Exception: ");
            err += e.what();
            throw std::logic_error(err);
        }
        countEval = true;  // count a black-box evaluation
        return eval_ok;     // the evaluation succeeded
    }
private:
    std::shared_ptr<Blackbox> bb;
};

// Initialization of all parameters that do not change from one poll method to another
void initParams(NOMAD::AllParameters &p, size_t n )
{
    // parameters creation
    p.getPbParams()->setAttributeValue("DIMENSION", n);
    p.getEvalParams()->setAttributeValue("BB_OUTPUT_TYPE", NOMAD::stringToBBOutputTypeList("OBJ"));

    p.getPbParams()->setAttributeValue("LOWER_BOUND", NOMAD::ArrayOfDouble(n, -5.0)); // all var. >= -5
    p.getPbParams()->setAttributeValue("UPPER_BOUND", NOMAD::ArrayOfDouble(n, 5.0)); // all var. <= 5
    

    // the algorithm terminates after 1000 black-box evaluations,
    // or 2000 total evaluations, including cache hits and evalutions for
    // which countEval was false.
    p.getEvaluatorControlParams()->setAttributeValue("MAX_BB_EVAL", 2000*n); //1000

    p.getEvaluatorControlParams()->setAttributeValue("OPPORTUNISTIC_EVAL",false); 
    p.getEvaluatorControlParams()->setAttributeValue("BB_MAX_BLOCK_SIZE",(size_t)1);

    //p.getRunParams()->setAttributeValue("H_MAX_0", NOMAD::Double(10000000));
    p.getRunParams()->setAttributeValue("NM_SEARCH",false);
    p.getRunParams()->setAttributeValue("SPECULATIVE_SEARCH",false);
    p.getRunParams()->setAttributeValue("ANISOTROPIC_MESH",false);
    p.getRunParams()->setAttributeValue("NB_THREADS_OPENMP",11);

    p.getRunParams()->setAttributeValue("POLL_CENTER_USE_CACHE",false);

    p.getDispParams()->setAttributeValue("DISPLAY_DEGREE",1);
    p.getDispParams()->setAttributeValue("DISPLAY_STATS", NOMAD::ArrayOfString("EVAL ( SOL ) OBJ"));

    p.getDispParams()->setAttributeValue("DISPLAY_UNSUCCESSFUL",false);


    p.getRunParams()->setAttributeValue("HOT_RESTART_READ_FILES", false);
    p.getRunParams()->setAttributeValue("HOT_RESTART_WRITE_FILES", false);
    p.getRunParams()->setAttributeValue("ADD_SEED_TO_FILE_NAMES",false);

    
    // parameters validation
    p.checkAndComply();
}

// Run NOMAD on the problem pb_num, generated with the random seed pb_seed, in dimension dim
// Runing with the poll strategy poll_strategy and starting point x0
void optimize(int dim, int pb_num, int pb_seed, int poll_strategy, int nb_of_2n_block, NOMAD::Point x0){
    // creating the blackbox
    auto blackbox = std::make_shared<Blackbox>(dim, pb_num, pb_seed); 

    // Initialize all parameters
    auto params = std::make_shared<NOMAD::AllParameters>();
    initParams(*params, (size_t)dim);


    auto name = "run_"+std::to_string(dim)+"_"+std::to_string(pb_num)+"_"+std::to_string(pb_seed)+"_"+std::to_string(poll_strategy)+"_";
	
    params->getPbParams()->setAttributeValue("X0", x0);

    switch (poll_strategy)
    {
    case 1:
        params->getRunParams()->setAttributeValue("CLASSICAL_POLL",true);
        name = name + "1_";
        break;

    case 2:
        params->getRunParams()->setAttributeValue("CLASSICAL_POLL",false); //disactivate classical poll because it is activated by default

        params->getRunParams()->setAttributeValue("MULTI_POLL",true);
        
        name = name + std::to_string(2*dim)+"_";
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

    default:
        params->getRunParams()->setAttributeValue("CLASSICAL_POLL",true);
        break;
    }
    name = name + ".txt";
    params->getDispParams()->setAttributeValue("STATS_FILE", NOMAD::ArrayOfString(name));


    auto TheMainStep = std::make_unique<NOMAD::MainStep>();

    TheMainStep->setAllParameters(params);
    // Custom evaluator creation
    std::unique_ptr<My_Evaluator> ev(new My_Evaluator(params->getEvalParams(),blackbox));
    TheMainStep->setEvaluator(std::move(ev));

    try
    {
        // Algorithm creation and execution
        TheMainStep->start();
        TheMainStep->run();
        TheMainStep->end();
    }

    catch(std::exception &e)
    {
        std::cerr << "\nNOMAD has been interrupted (" << e.what() << ")\n\n";
    }
    
    NOMAD::OutputQueue::Flush();
    NOMAD::CacheBase::getInstance()->clear();

}



int main (int argc, char **argv)
{

    int DIM_MIN=4; 
    int PB_NUM_MIN=1; 
    int PB_SEED_MIN=0; 
    int POLL_STRATEGY_MIN=1;
    int NB_2N_BLOCK_MIN=1;
    
    int DIM_MAX=5; 
    int PB_NUM_MAX=25; 
    int PB_SEED_MAX=1; 
    int POLL_STRATEGY_MAX=5;
    int NB_2N_BLOCK_MAX=17;

    for(int dim = DIM_MIN ; dim <DIM_MAX ; dim=2*dim){ //every problem is scalable 

        for(int pb_num = PB_NUM_MIN ; pb_num < PB_NUM_MAX ; pb_num++ ){ //problem number : 1..24

            for(int pb_seed = PB_SEED_MIN ; pb_seed < PB_SEED_MAX ; pb_seed++ ){ //to generate the random rotation matrices (with householder) of each problem

                for(int poll_strategy = POLL_STRATEGY_MIN ; poll_strategy < POLL_STRATEGY_MAX ; poll_strategy++){ //1 : classical poll, 2 : multi poll, 3 : oignon poll, 4 : enriched poll


                    if(poll_strategy ==1 || poll_strategy == 2){ //in the case of poll strategies 1 or 2 we can't set the number of 2n blocks of points
                        NOMAD::Point x0((size_t)dim, -3);
                        optimize(dim, pb_num, pb_seed, poll_strategy, 1, x0);
                    }
                    else
                    {
                        for(int nb_2n_block = NB_2N_BLOCK_MIN ; nb_2n_block < NB_2N_BLOCK_MAX ; nb_2n_block=2*nb_2n_block){ //we increase the number of 2n blocks to see the effect on the optimization
                            NOMAD::Point x0((size_t)dim, -3);
                            optimize(dim, pb_num, pb_seed, poll_strategy, nb_2n_block, x0);
                        }
                    }


                }
            }
        }
    }
    return 0;
}
