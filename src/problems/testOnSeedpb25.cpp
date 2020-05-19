#include "blackbox.hpp"
#include <fstream>
#include <chrono>
#include <omp.h>

int main(){
	for(int i = 0; i<12; i++){
		Blackbox bb(8, 25, i);
		std::vector<double> x0 = bb.getX0();
		for(int j = 0; j<8; j++)
			std::cout<< x0[j] <<"\t";
		std::cout<<"\n";
		std::cout<<"f(x0) = "<< bb.f(x0);
		std::cout<<"\n\n";
	}
	return 0;
}
