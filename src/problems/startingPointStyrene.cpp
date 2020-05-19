#include "blackbox.hpp"
#include <fstream>
#include <chrono>
#include <omp.h>


double distanceToVector(std::vector<double> x, std::vector<double> y){
	double dist = 0.0;
	double dim = x.size();
	for(size_t i = 0; i<dim; i++)
		dist = dist + pow(x[i]-y[i],2);
	return sqrt(dist);
}


double distanceToSet(std::vector<std::vector<double>> A, std::vector<double> x){
	double minDistance = 1000000000;
	for(size_t i = 0; i<A.size(); i++){
		double dist = distanceToVector(A[i], x);
		if(dist < minDistance)
			minDistance = dist;
	}
	return minDistance;
}
	

std::vector<double> generateRandomPoint(int dim, double lb, double ub){
	std::vector<double> randomPoint(dim);
	for(int i = 0; i<dim ; i++)
		randomPoint[i] = lb + (ub-lb)*((double)rand()/(double)RAND_MAX);
	return randomPoint;
}

bool checkFeasibility(std::vector<double> x, Blackbox bb){
	bool isFeasible = false;
	std::string bbo = bb.f(x);
	if(!(bbo[0]=='E')){
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
	return isFeasible;
}

int main(){
	int dim = 8;
	std::vector<double> x0(dim);
	x0[0]=54.0;
	x0[1]=66.0;
	x0[2]=86.0;
	x0[3]=8.0;
	x0[4]=29;
	x0[5]=51;
	x0[6]=32;
	x0[7]=15;

	std::vector<std::vector<double>> startingPointSet(1,x0);
	size_t maxNbStartingPoint = 10;
	double minDist = 20.0;
	

	double lb = 0.0;
	double ub = 100.0;
	Blackbox bb(dim, 25, 1);

	bool keepGoing = true;
	size_t evaluationNumber = 0;
	size_t pointsGenerated = 0;

	ofstream startingPointsFile("STYRENE/points/startingPointsMinDist"+std::to_string((int)minDist)+".txt", std::ios_base::app);


	while(keepGoing){
		std::vector<double> x = generateRandomPoint(dim, lb, ub);
		double dist = distanceToSet(startingPointSet, x);
		pointsGenerated += 1; // this one counts all the points including when we generated a point too close form the set
		if(!(dist<minDist)){
			evaluationNumber += 1; // this one counts all the evaluated points ie. once we have verified it was not too close to already feasible points
			if(checkFeasibility(x,bb)){
				startingPointSet.push_back(x);

				std::cout<<"added point :\t";
				for(int i = 0; i< dim; i++){
					std::cout<<"\t"<<x[i];
					startingPointsFile <<x[i]<<" ";
				}
				startingPointsFile << std::endl;
				//startingPointsFile.close();
				std::cout<<"\n"<<"after " << evaluationNumber << " evaluations and "<< pointsGenerated << " points generated\n\n";
			}
		}
		if(startingPointSet.size()+1 > maxNbStartingPoint)
			keepGoing = false;
	}

	return 0;
}


