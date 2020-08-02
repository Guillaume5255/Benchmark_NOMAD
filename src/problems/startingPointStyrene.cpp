#include "blackbox.hpp"
#include <fstream>
#include <chrono>
#include <omp.h>
//#include <cmath>


double minimalDifference(std::vector<double> x, std::vector<double> y){ // computes min{|xi-yi| : i=1..n}
	double minDiff = 1000000000;
	double diff;
	size_t dim = x.size();
	for(size_t i = 0; i<dim; i++){
		diff = std::abs(x[i]-y[i]); 
		if(minDiff>diff)
			minDiff = diff;
	}
	return minDiff;
}


double distanceToSet(std::vector<std::vector<double>> A, std::vector<double> x){ //computes min{ min{|ai-yi| : i=1..n} : ai in A}
	double minDistance = 1000000000;	
	for(size_t i = 0; i<A.size(); i++){
		double dist = minimalDifference(A[i], x);
		if(dist < minDistance)
			minDistance = dist;
	}
	return minDistance;
}
	

std::vector<double> generateRandomPoint(size_t n, double lb, double ub){ //generates a point in the box [lb,ub]^n with integer coordinates
	std::vector<double> randomPoint(n);
	for(size_t i = 0; i<n ; i++)
		randomPoint[i] = lb + (double)(rand()%(int)(ub-lb+1));
	return randomPoint;
}

bool checkFeasibility(std::vector<double> x, Blackbox bb){ // check if x is feasible by aggregating constraints
	bool isFeasible = false;
	std::vector<double> xdouble(x.begin(), x.end());
	std::string bbo = bb.f(xdouble);
	if(!(bbo[0]=='E')){
		//std::cout<< bbo <<"\n";
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
	//else{
		//std::cout<<"ERROR\n";
	//}
	return isFeasible;
}

void writePoint(std::vector<double> x, size_t nbPointsGenerated, size_t evaluationNumber, std::string pathToInitialPointsFile){
	ofstream startingPointsFile(pathToInitialPointsFile, std::ios_base::app);	
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


void readPointsFromFile(std::string pathToInitialPointsFile, std::vector<std::vector<double>> &startingPointSet){
    	ifstream startingPoints;
	startingPoints.open(pathToInitialPointsFile);
	std::string point = "";
	std::string delimiter = " "; // how coordiantes are separated	
	while (getline(startingPoints, point)) {//we keep reading the file while we are not at the good line and that there is still lines to read
		std::vector<double> x(8);	
		size_t pos = 0;
		std::string xi; // coordinate i of point
		size_t i = 0;
		//std::cout<<"read point : "+point+" --> ";
		while ((pos = point.find(delimiter)) != std::string::npos && i<8) { // we cut the string at " " delimiters to get each coordinates
			xi = point.substr(0, pos);
			point.erase(0, pos + delimiter.length());
			x[i] = std::stod(xi);
			//std::cout<<std::stod(xi)<<"|"<<xi+" ";
			++i;
		}
		//std::cout<<"\n";
		startingPointSet.push_back(x);
	}
	startingPoints.close();
	return;
}

int main(){
	size_t dim = 8;
	double lb = 0;
	double ub = 100;

	std::vector<double> x0(dim);
	x0[0]=54;
	x0[1]=66;
	x0[2]=86;
	x0[3]=8;
	x0[4]=29;
	x0[5]=51;
	x0[6]=32;
	x0[7]=15;

	double minDist = 1;
	size_t maxNbStartingPoint = 30;

	size_t evaluationNumber = 0; //we did not evaluated x0
	size_t nbPointsGenerated = 1; // but we generated it

	std::vector<std::vector<double>> startingPointSet;

	std::string pathToInitialPointsFile = "STYRENE/points/startingPoints.txt";
	readPointsFromFile(pathToInitialPointsFile, startingPointSet);
	std::cout<<"nb points extracted : "<<startingPointSet.size()<<"\n";
	if(startingPointSet.size() == 0){
		writePoint(x0, nbPointsGenerated, evaluationNumber, pathToInitialPointsFile);
		startingPointSet.push_back(x0);
	}
	Blackbox bb(dim, 25, 0);// must be after that the first point has been added
	srand(time(NULL));

	std::time_t startTime = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
	std::cout<<"\t Started at : "<<std::ctime(&startTime)<<"\n"; 

	while(startingPointSet.size()<maxNbStartingPoint){
		std::vector<double> x = generateRandomPoint(dim, lb, ub);
		double dist = distanceToSet(startingPointSet, x);

		nbPointsGenerated += 1; // this one counts all the points including when we generated a point too close form the set
		if(dist>=minDist){
			evaluationNumber += 1; // this one counts all the evaluated points ie. once we have verified it was not too close to already feasible points
			if(checkFeasibility(x,bb)){
				startingPointSet.push_back(x);
				std::cout<<"distance : " <<dist<<"\n";
				writePoint(x,nbPointsGenerated, evaluationNumber, pathToInitialPointsFile);

			}
		}
	}
	return 0;
}


