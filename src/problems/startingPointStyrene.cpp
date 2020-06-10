#include "blackbox.hpp"
#include <fstream>
#include <chrono>
#include <omp.h>
//#include <cmath>


int minimalDifference(std::vector<int> x, std::vector<int> y){ // computes min{|xi-yi| : i=1..n}
	int minDiff = 1000000000;
	int diff;
	size_t dim = x.size();
	for(size_t i = 0; i<dim; i++){
		diff = std::abs(x[i]-y[i]); 
		if(minDiff>diff)
			minDiff = diff;
	}
	return minDiff;
}


int distanceToSet(std::vector<std::vector<int>> A, std::vector<int> x){ //computes min{ min{|ai-yi| : i=1..n} : ai in A}
	int minDistance = 1000000000;	
	for(size_t i = 0; i<A.size(); i++){
		int dist = minimalDifference(A[i], x);
		if(dist < minDistance)
			minDistance = dist;
	}
	return minDistance;
}
	

std::vector<int> generateRandomPoint(size_t n, int lb, int ub){ //generates a point in the box [lb,ub]^n with integer coordinates
	std::vector<int> randomPoint(n);
	for(size_t i = 0; i<n ; i++)
		randomPoint[i] = lb + rand()%(ub-lb+1);
	return randomPoint;
}

bool checkFeasibility(std::vector<int> x, Blackbox bb){ // check if x is feasible by aggregating constraints
	bool isFeasible = false;
	std::vector<double> xdouble(x.begin(), x.end());
	std::string bbo = bb.f(xdouble);
	if(!(bbo[0]=='E')){
		std::cout<< bbo <<"\n";
		std::string delimiter = " ";
		size_t pos = 0;
		std::string token;
		double constraintAggregation = 0;
		std::string bboBackup = bbo;
		bool firstLoop = true;
		while ((pos = bbo.find(delimiter)) != std::string::npos) {
			token = bbo.substr(0, pos);
			//std::cout << token <<"\t";
			bbo.erase(0, pos + delimiter.length());
			if(!firstLoop) // otherwise we also count the objectif in the constraint aggregation		
				constraintAggregation += std::max(std::stod(token), 0.0);
			firstLoop = false;
		}
		//std::cout << "\n";
		if(constraintAggregation == 0.0){
			isFeasible = true;
			std::cout<<"feasible output :\t " <<bboBackup<<"\n";
		}	
	}
	else{
		std::cout<<"ERROR\n";
	}
	return isFeasible;
}

void writePoint(std::vector<int> x, size_t nbPointsGenerated, size_t evaluationNumber, ofstream &startingPointsFile){
	size_t dim = x.size();
	std::cout<<"added point :\t";
	for(size_t i = 0; i< dim; i++){
		std::cout<<"\t"<<x[i];
		startingPointsFile <<x[i]<<" ";
	}
	startingPointsFile << std::endl;
	//startingPointsFile.close();
	std::cout<<"\n"<<"after " << nbPointsGenerated << " points generated and "
				  << evaluationNumber << " evaluations\n\n";
	return;
}

int main(){
	size_t dim = 8;
	int lb = 0;
	int ub = 100;

	std::vector<int> x0(dim);
	x0[0]=54;
	x0[1]=66;
	x0[2]=86;
	x0[3]=8;
	x0[4]=29;
	x0[5]=51;
	x0[6]=32;
	x0[7]=15;
	int minDist = 5;
	std::vector<std::vector<int>> startingPointSet(1,x0);
	ofstream startingPointsFile("STYRENE/points/startingPointsMinDist"+std::to_string((int)minDist)+".txt", std::ios_base::app);

	size_t maxNbStartingPoint = 10;


	size_t evaluationNumber = 0; //we did not evaluated x0
	size_t nbPointsGenerated = 1; // but we generated it

	writePoint(x0, nbPointsGenerated, evaluationNumber, startingPointsFile);
	size_t nbPointsAdded = 1;
	Blackbox bb(dim, 25, 1);// must be after that the first point has been added

	while(nbPointsAdded<maxNbStartingPoint){
		std::vector<int> x = generateRandomPoint(dim, lb, ub);
		int dist = distanceToSet(startingPointSet, x);
		nbPointsGenerated += 1; // this one counts all the points including when we generated a point too close form the set
		if(!(dist<minDist)){
			evaluationNumber += 1; // this one counts all the evaluated points ie. once we have verified it was not too close to already feasible points
			if(checkFeasibility(x,bb)){
				startingPointSet.push_back(x);
				writePoint(x,nbPointsGenerated, evaluationNumber, startingPointsFile);
				nbPointsAdded++;				
			}
		}
	}
	return 0;
}


