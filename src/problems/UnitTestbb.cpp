#include "blackbox.hpp"
#include <chrono>

int main(){
    int n = 5, seed= 1;
    std::vector<double> x(n,3.0);

	std::cout<<"\n\n Vérification détermnisme sur la meme instance de la boite noire \n \n";
    for(int i = 1; i< 25; i++){
		cout<<"ok";
        Blackbox bb(n, i, seed);

        double f=bb.f(x);
        double g=bb.f(x) ;
        
        bool isEqual = f==g;
        
        std::string checkTest = isEqual ? "OK" : "Problem";
        
        std::cout<<"valeur de f"<< i <<" : \t"<<f<<"\t|\t "<<g<< "\t|"+checkTest <<"\n";   
    }
    
    std::cout<<"\n\n Vérification détermnisme sur 2 instance de la boite noire avec la meme graine aléatoire \n \n";
    for(int i = 1; i< 25; i++){

        Blackbox bb1(n, i, seed), bb2(n, i, seed);
		
        double f=bb1.f(x);
        double g=bb2.f(x) ;
        
        bool isEqual = f==g;
        
        std::string checkTest = isEqual ? "OK" : "Problem";
        
        cout<<"valeur de f"<< i <<" : \t"<<f<<"\t|\t "<<g<< "\t|"+checkTest <<"\n";   
    }
    std::cout<<"\n\n Benchmark des durées moyennes (10 eval) en fonction de la dimension pour chaque problème\n";
    
    
    for(int pbNum = 1; pbNum< 25; pbNum++){
    	std::cout<< "exec. time for pb "<<pbNum<<"\t:\t";
    	
    	for(n = 2; n<1024; n=2*n){
        	Blackbox bb(n, pbNum, seed);
        	double meanDuration = 0;
        	#pragma omp parallel for shared(meanDuration)
        	for(int nbEval = 0; nbEval<10; nbEval++){
        		x = std::vector<double>(n, (nbEval-5)/2);
        		
        		auto start = std::chrono::high_resolution_clock::now();
        		bb.f(x);
        		auto stop = std::chrono::high_resolution_clock::now();
        		
        		#pragma omp atomic
        		meanDuration += std::chrono::duration_cast<std::chrono::seconds>(stop - start).count(); 
        		
        	}
        	meanDuration = meanDuration/10;
        	std::cout<< meanDuration <<"\t";
    	}
    	std::cout<<"\n";
    }
    
    return 0;
}


