#include "blackbox.hpp"
#include <chrono>
#include <omp.h>

int main(){
	int n = 128, seed= 1;
	std::vector<double> x(n,3.1);
	bool ValueTestSuccessful = true;
	std::cout<<"\n\n Vérification déterimnisme sur la meme instance de la boite noire \n \n";
	for(int i = 1; i< 25; i++){
		Blackbox bb(n, i, seed);

		string f=bb.f(x);
		string g=bb.f(x);

		bool isEqual = f==g;
		if(!isEqual)
			ValueTestSuccessful = false;

		std::string checkTest = isEqual ? "OK" : "Problem";

		std::cout<<"valeur de f"<< i <<" : "<< std::left<<f<<std::setw(25)<<" | "<<g<< std::setw(25) << "|"+checkTest <<"\n";   
	//bb.DisplayTheoricalOptimal();
	}

	std::cout<<"\n\n Vérification détermnisme sur 2 instance de la boite noire avec la meme graine aléatoire \n \n";
	for(int i = 1; i< 25; i++){

		Blackbox bb1(n, i, seed), bb2(n, i, seed);
		string f=bb1.f(x);
		string g=bb2.f(x) ;

		bool isEqual = f==g;

		if(!isEqual)
			ValueTestSuccessful = false;

		std::string checkTest = isEqual ? "OK" : "Problem";

		cout<<"valeur de f"<< i <<" : "<< std::left<<f<<std::setw(25)<<" | "<<g<< std::setw(25) << "|"+checkTest <<"\n";   
	}

	std::string successfulValueTest;
	if (ValueTestSuccessful)
		successfulValueTest = "\n All value tests successful\n";
	else
		successfulValueTest = "\n There is a problem in value test\n";
	std::cout<<successfulValueTest;

	std::cout<<"test on theorical optimal value";
	for(int i = 1; i<25; i++){
		Blackbox bb(n,i,seed);
		x = bb.getXopt();
		std::cout<<"pb "<<i<<"\t f(xopt) = "<<bb.f(x)<<"\n";
	}


	std::cout<<"\n\n Benchmark des durées moyennes (10 eval) en fonction de la dimension pour chaque problème\n";

	int nbMaxEval = 10;
	for(int pbNum = 1; pbNum< 25; pbNum++){
		std::cout<< "exec. time for pb "<<pbNum<<"\t:\t";
		for(n = 1000; n<1001; n = 2*n){

			auto startbb = omp_get_wtime();//std::chrono::high_resolution_clock::now();
			Blackbox bb(n, pbNum, seed);
			auto stopbb = omp_get_wtime();//std::chrono::high_resolution_clock::now();

			auto meanbuild = stopbb-startbb;//std::chrono::duration_cast<std::chrono::microseconds>(stopbb - startbb).count(); 
			std::cout<<"("<<meanbuild<<")";

			double meanDuration = 0;

			//#pragma omp parallel for reduction(+ : meanDuration) num_threads(8)
			for(int nbEval = 0; nbEval<nbMaxEval; nbEval++)
			{
				std::vector<double> x(n, (nbEval-5)/2);

				auto start = omp_get_wtime();//std::chrono::high_resolution_clock::now();
				bb.f(x);
				auto stop = omp_get_wtime();//std::chrono::high_resolution_clock::now();

				meanDuration += stop-start;//std::chrono::duration_cast<std::chrono::microseconds>(stop - start).count(); 
			}

			meanDuration = meanDuration/nbMaxEval;
			std::cout<< meanDuration <<"\t";
		}
		std::cout<<"\n";
	}

	std::cout<<"verification que le chamgement de seed change bien les valeurs de f et de xopt \n";
	n=2;
	x = std::vector<double>(n,-3.0);
	for(int i = 1; i< 25; i++){

		Blackbox bb1(n, i, 1), bb2(n, i, 2);

		string f=bb1.f(x);
		string g=bb2.f(x) ;

		bool isEqual = f==g;

		if(!isEqual)
			ValueTestSuccessful = false;

		std::string checkTest = isEqual ? "Problem : same value for different seeds" : "OK";

		cout<<"valeur de f"<< i <<" : "<< std::left<<f<<std::setw(25)<<" | "<<g<< std::setw(25) << "|"+checkTest <<"\n";
		bb1.DisplayTheoricalOptimal();
		bb2.DisplayTheoricalOptimal();
	}
	return 0;
}


