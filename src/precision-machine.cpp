#include <iostream>
#include <string>

//program to get machine precision

int main(){
	double epsilon = 1.0;
	while (1.0+epsilon != 1.0){
		epsilon = 0.1*epsilon;
		std::cout<<"epsilon : "<< epsilon<<"\n";
	}
	return 0;
}
