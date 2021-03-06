#include "blackbox.hpp"

Blackbox::Blackbox(const int dim, const int functionNumber, const int instance ):_n(dim), funcNum(functionNumber), pb_seed(instance){
	//std::cout<<"\n Building the blackbox : seed = "<<pb_seed <<"\n";
	//auto start = omp_get_wtime();
	srand(pb_seed+2);//because srand(0) and srand(1) has special behaviour : see http://www.cplusplus.com/reference/cstdlib/srand/
	_x0 = RandomDirection(5.0);
	_xopt = RandomDirection(5.0);
	_ones = RandomOnesvector();
	SetUpAngles();

	switch (funcNum) {
		case 3:
			_alpha = 10;
			_beta = 0.2;
			break;
		
		case 5:
			_xopt = _ones;
			ExternalProduct(5.0,_xopt);
			break;

		case 6:
			_alpha = 10;
			break;
		
		case 7:
			_alpha = 10;
			break;

		case 12:
			_beta = 0.5;
			break;
		
		case 13:
			_alpha = 10;
			break;

		case 15:
			_alpha = 10;
			_beta = 0.2;
			break;
		
		case 16:
			_alpha = 0.01;
			_f0=0;
			for(int k =0; k < 12; k++)
				_f0 += cos(M_PI*pow(3,k))/pow(2,k);
			break;

		case 17:
			_alpha = 10;
			_beta = 0.5;
			break;

		case 18:
			_alpha = 1000;
			_beta = 0.5;
			break;

		case 20:
			_alpha = 10;
			_xopt = std::vector<double>(_n,4.2096874633);
			//_xopt = RandomOnesvector();
			// ExternalProduct(4.2096874633,_xopt);
			break;

		case 21:
			_hi = 101;
			SetUpRandomValue(_hi);
			_xopt = Y[0];
			ExternalProduct(-1.0,_xopt);
			break;

		case 22:
			_hi = 21;
			SetUpRandomValue(_hi);
			_xopt = Y[0];
			ExternalProduct(-1.0,_xopt);
			break;

		case 23:
			_alpha = 100;
			break;

		case 24:
			_alpha = 100;
			u0 =2.5;
			s = 1.0-1.0/(2.0*sqrt(_n+20.0)-8.2);
			d = 1.0;
			u1 = -sqrt((u1*u1-d)/s);
			_xopt = RandomOnesvector();
			ExternalProduct(u0/2,_xopt);
			break;

		case 25:
			//std::cout<< "seed has no effect on this problem\n";
			if (_n != 8){ 
				throw std::runtime_error("trying to build pb 25(styrene) with dimension != 8, this is not possible.\n");
			}
			else{
				//we first try to get the path to STYRENE directory
				// we execute the pwd command and we store the result in pipe
				std::array<char, 128> buffer;
				string currentPath = "";
				string cmdToGetPath = "pwd";
				std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmdToGetPath.c_str(), "r"), pclose);
				if (!pipe) {
					throw std::runtime_error("popen() failed! : impossible to read current path");
				}

				while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
					currentPath += buffer.data();
				}
				//we now have to split the current path at 'Benchmark_NOMAD' and build STYRENE path

				std::string pathDelimiter = "Benchmark_NOMAD";
				std::string rootPath = currentPath.substr(0, currentPath.find(pathDelimiter));		
				styreneDir = rootPath+pathDelimiter+"/src/problems/STYRENE";
				//this file contains differents starting points for the STYRENE problem
				//they were generated using startingPointStyrene.cpp
				std::string pathToInitialPointsFile = styreneDir+"/points/startingPoints.txt";
				
				std::string point = "";
    				ifstream startingPoints;
				startingPoints.open(pathToInitialPointsFile);
				int line_no = 0;
				while (line_no != pb_seed+1 && getline(startingPoints, point)) {//we keep reading the file while we are not at the good line and that there is still lines to read
				    ++line_no;
				}
				if(line_no == 0)
					throw std::runtime_error(pathToInitialPointsFile+" empty or at the wrong location, compile and run src/problems/startingPointStyrene.cpp to generate it.");
				
				std::string delimiter = " "; // how coordiantes are separated
				size_t pos = 0;
				std::string xi; // coordinate i of point
				int i = 0;
				while ((pos = point.find(delimiter)) != std::string::npos && i<_n) { // we cut the string at " " delimiters to get each coordinates
					xi = point.substr(0, pos);
					point.erase(0, pos + delimiter.length());
					_x0[i] = std::stod(xi);
					++i;
				}

			}
			break;

		default:
			break;
	}
	//auto stop = omp_get_wtime();
		//std::cout<<"\n Done in "<<stop-start<<" s\n";
}
std::vector<double> Blackbox::getXopt(){
	if (funcNum == 5 || funcNum == 20 || funcNum == 21 || funcNum == 22 || funcNum == 24)
		return _xopt;
	else
	{ 
		std::vector<double> tempVal = _xopt;
		for(int i = 0; i<_n;i++)
			tempVal[i]= -tempVal[i];
		return tempVal;
	}
}


void Blackbox::SetUpRandomValue(int hi){ // only used when f21 and f22 are called
	std::vector<double> a(hi);
	a[0] = 1000.0;
	for(int i = 1; i<hi; i++)
		a[i]=pow(1000.0,2.0*double(i)/double(hi));

	random_shuffle(a.begin()+1, a.end());
	w = std::vector<double>(hi,10.0);
	Y = std::vector<std::vector<double>>(hi);
	C = std::vector<std::vector<double>>(hi);
	for(int i = 0; i<hi; i++){
		if (i == 0)
			Y[i] = RandomDirection(4.0);
		else{
			w[i] = 1.1+8*(i-1)/hi;
			Y[i] = RandomDirection(5.0);
		}
		C[i] = Lambda(a[i]);
		ExternalProduct(1.0/pow(a[i],0.25),C[i]);
		random_shuffle(C[i].begin(), C[i].end());
	}
}

void Blackbox::SetUpAngles(){
	int nbOfAngles = _n%2==0 ? _n/2 : (_n-1)/2;
	_theta = std::vector<double>(nbOfAngles);
	_phi = std::vector<double>(nbOfAngles);
	for(int i = 0; i<nbOfAngles; i++){
		_theta[i] = ((double)rand()/(double)RAND_MAX)*2*M_PI;
		_phi[i] = ((double)rand()/(double)RAND_MAX)*2*M_PI;
	}
}

std::vector<double> Blackbox::RandomDirection(double max){ // generates a random std::vector in [-max, max ]^n
	std::vector<double> x(_n,0.0);
	for(int i = 0 ; i <_n ;i++ )
		x[i] =  (((double)rand()/(double)RAND_MAX)*2.0-1.0)*max;
	return x;
}

std::vector<double> Blackbox::RandomOnesvector(){ // generates a random std::vector in {-1,1}^n
	std::vector<double> x(_n);
	//#pragma omp parallel for shared(x)
	for(int i = 0 ; i <_n ;i++ ){
		double xi =  double(rand()%2);
		if (xi==0.0)
			xi = -1.0;
		else
			xi = 1.0;
		//#pragma omp critical
		x[i]=xi;
	}
	return x;
}

void Blackbox::RotationQ(std::vector<double>& x){
	if (_n%2 == 0){
		for(int i = 0; i<(_n/2); i++){
			x[2*i] = x[2*i]*cos(_theta[i])-x[2*i+1]*sin(_theta[i]);
			x[2*i+1] = x[2*i]*sin(_theta[i])+x[2*i+1]*cos(_theta[i]);
		}
	}
	else{
		for(int i = 0; i<((_n-1)/2); i++){
			x[2*i] = x[2*i]*cos(_theta[i])-x[2*i+1]*sin(_theta[i]);
			x[2*i+1] = x[2*i]*sin(_theta[i])+x[2*i+1]*cos(_theta[i]);
		}
	}
}

void Blackbox::RotationR(std::vector<double>& x){
	if (_n%2 == 0){
		for(int i = 0; i<(_n/2); i++){
			x[2*i] = x[2*i]*cos(_phi[i])-x[2*i+1]*sin(_phi[i]);
			x[2*i+1] = x[2*i]*sin(_phi[i])+x[2*i+1]*cos(_phi[i]);
		}
	}
	else{
		for(int i = 0; i<((_n-1)/2); i++){
			x[2*i] = x[2*i]*cos(_phi[i])-x[2*i+1]*sin(_phi[i]);
			x[2*i+1] = x[2*i]*sin(_phi[i])+x[2*i+1]*cos(_phi[i]);
		}
	}
}

void Blackbox::ExternalProduct(double y,std::vector<double>& x){ // a.(x,y) = (ax,ay) 
	for(int i=0; i<_n; i++)
		x[i]=x[i]*y;
}

double Blackbox::ScalarProduct(std::vector<double> x ,std::vector<double> y){ // cannonical scalar product
	double z=0.0;
	//#pragma omp parallel for reduction(+ : z)
	for(int i=0; i<_n; i++)
		z+=x[i]*y[i];

	return z;
}

std::vector<double>  Blackbox::vectorProduct( std::vector<double> x ,std::vector<double> y){ // product term by term : vectorProduct((a,b),(c,d)) = (ab,cd)
	std::vector<double> z(_n);
	for(int i=0; i<_n; i++)
		z[i]=x[i]*y[i];

	return z;
}

std::vector<double> Blackbox::vectorSum( std::vector<double> x ,std::vector<double> y){ // inner sum of a std::vectorial space
	std::vector<double> sum(_n,0);
	for(int i = 0; i<_n; i++)
		sum[i]= x[i]+y[i];

	return sum;
}

double Blackbox::Norm(std::vector<double> x){ // euclidian norm
	double norm = 0;
	//#pragma omp parallel for reduction(+ : norm)
	for(int i=0; i<_n; i++)
		norm += x[i]*x[i];

	return sqrt(norm);
}

void Blackbox::Lambda(std::vector<double>& x){ // diagonal matrix seen as a std::vector 
	double exponent = 0;
	for(int i=0; i<_n; i++){
		exponent=0.5*float(i-1)/float(_n-1);
		x[i] =x[i]*pow (_alpha, exponent);
	}
}

std::vector<double> Blackbox::Lambda(double a){ // diagonal matrix seen as a std::vector 
	std::vector<double> lambda(_n);
	double exponent = 0;
	for(int i=0; i<_n; i++){
		exponent=0.5*float(i-1)/float(_n-1);
		lambda[i] = pow (a, exponent);
	}
	return lambda;
}

double Blackbox::Fpen(std::vector<double> x){ //penalty
	double fpen = 0;
	//#pragma omp parallel for reduction(+ : fpen)
	for(int i=0; i<_n; i++){
		double t = abs(x[i])-5;
		fpen += pow(std::max(t,0.0),2);
	}
	return fpen;
}

void Blackbox::Tasy(std::vector<double>& x){ //symetry breaker
	double exponent;
#ifdef _PARALLEL
	#pragma omp parallel for private(exponent, value) shared(tasy)
#endif
	for(int i=0; i<_n; i++){
		if(x[i]>0){
			exponent=1+_beta*double(i-1)/double(_n-1)*sqrt(x[i]);
			x[i]=pow (x[i], exponent);
		}
	}
}

void Blackbox::Tosz(std::vector<double>& x){ // the input std::vector can be of any size
	int taille = x.size();
	double xhat;
	double signedex=0.0;
	double c1=0;
	double c2=0;
#ifdef _PARALLEL
	#pragma omp parallel for private(xhat, c1, c2, signedex)
#endif
	for(int i=0; i<taille; i++){
		if(x[i]!=0.0)
			xhat = log(abs(x[i]));
		else
			xhat = 0.0;

		if(x[i]>0.0)
			signedex=1.0;
		if(x[i]<0.0)
			signedex=-1.0;

		if (signedex==1.0)
		{
			c1=10;
			c2=7.9;
		}
		else
		{
			c1=5.5;
			c2=3.1;
		}
#ifdef _PARALLEL
		#pragma omp critical
#endif
		x[i]=signedex*exp(xhat+0.049*(sin(c1*xhat)+sin(c2*xhat)));
	}
}

void Blackbox::DisplayTheoricalOptimal(){
	std::cout<<"\n\n Problem "<<funcNum<<" :\n";
	if(funcNum != 9 && funcNum != 19 ){
		std::cout<<"xopt :\n";
	}
	else{
		std::cout<<"zopt :\n";
	}

	std::vector<double> opt = getXopt();
	std::cout<<" (";
	for(int i = 0; i<_n; i++){
		if((i+1)%15 == 0)
			std::cout<<"\n";
		std::cout<<opt[i]<<"\t";
	}
	std::cout<<")";

	//additional information
	if(funcNum ==9 || funcNum ==19)
		std::cout<<"\n /!\\ this value is not computed directly\n";
	if(funcNum ==20){
		std::cout<<"\n /!\\ do not return 0 because it is a value obtained by a solver\n";
		std::cout<<"\n f(xopt) = "<< f(opt)<<"\n";
	}
	if (funcNum == 25)
		std::cout<< "\n This is a real blackbox, xopt is the best value known \n";
}

string Blackbox::f(std::vector<double> x){ //wrapper to be sure x is of the good dimension 
	//usleep(1000000);
	if ((int)x.size() == _n)
		return blackbox(x);
	else
	{
		std::cout<<"x is of dimension "<< x.size() <<"but blackbox takes "<< _n <<" input parameters";
		return "Error : bad dimension";
	}
}

//double Blackbox::getEvalTime(){ // returns the cumulative time spent in evaluations since the first one to the last one.
	

//	return
//}

double Blackbox::p1(std::vector<double> x){
	return Norm(vectorSum(x,_xopt)) + _fopt;
}

double Blackbox::p2(std::vector<double> x){
	std::vector<double> z = vectorSum(x,_xopt);
	Tosz(z);
	double sum = 0;
	for(int i = 0; i<_n; i++){
		sum += pow(10, 6*i/(_n-1))*z[i]*z[i];
	}
	return sum;
}

double Blackbox::p3(std::vector<double> x){
	std::vector<double> z = vectorSum(x,_xopt);
	Tosz(z);
	Tasy(z);
	Lambda(z);
	double sum = 0;

	for(int i = 0; i<_n; i++)
		sum += (double)cos(2*M_PI*z[i]);

	return 10*(_n-sum) + pow(Norm(z),2) + _fopt;
}

double Blackbox::p4(std::vector<double> x){
	std::vector<double> s(_n);
	for(int i = 0; i<_n; i++){
		if (x[i]>0 && (i+1)%2 == 1) // i think there is an error in the paper, they say z[i]>0
			s[i] = 10*pow(10, 0.5*i/(_n-1));
		else
			s[i] = pow(10, 0.5*i/(_n-1));
	}
	std::vector<double> z = vectorSum(x, _xopt);
	Tosz(z);
	z = vectorProduct(s,z);
	double sum1 = 0, sum2 = 0;

	for(int i = 0; i<_n; i++){
		sum1 += cos(2*M_PI*z[i]);
		sum2 += z[i]*z[i];
	}
	return 10*(_n-sum1) + sum2 + 100*Fpen(x) +_fopt;
}

double Blackbox::p5(std::vector<double> x){
	double sum = 0;
	double zi = 0;
	double si = 0;
	for(int i = 0; i<_n; i++){
		if (_xopt[i]>0)
			si = 5*pow(10,i/(_n-1));
		else
			si = -5*pow(10,i/(_n-1));
		if (_xopt[i]*x[i]<5*5)
			zi = x[i];
		else
			zi = _xopt[i];
		sum += 5*abs(si) - si*zi;
	}
	return sum + _fopt;
}

double Blackbox::p6(std::vector<double> x){
	std::vector<double> z = vectorSum(x,_xopt);
	RotationR(z);
	Lambda(z);
	RotationQ(z);
	double sum = 0.0;
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for(int i = 0; i<_n; i++){
		double si =_xopt[i]*z[i];
		if (si >0)
			sum += pow(100*z[i],2);
		else
			sum += pow(z[i],2);
	}
	std::vector<double> tempVal(1,sum);
	Tosz(tempVal);
	return pow(tempVal[0],0.9) + _fopt;
}

double Blackbox::p7(std::vector<double> x){
	std::vector<double> hatz = vectorSum(x,_xopt);
	RotationR(hatz);
	Lambda(hatz);
	std::vector<double> z(_n,0.0);

	for(int i = 0; i<_n; i++){
		if (abs(hatz[i])>0.5)
			z[i] = floor(0.5+hatz[i]);
		else
			z[i] = floor(0.5+10*hatz[i])/10.0;
	}
	RotationQ(z);
	double sum = 0.0;

	for(int i = 0; i<_n; i++)
		sum += pow(10, 2*i/double(_n-1))*z[i]*z[i];

	if(sum > abs(z[1])/10000)
		return 0.1*sum + Fpen(x) + _fopt;
	else
		return 0.1*abs(z[1])/10000 + Fpen(x) + _fopt;
}

double Blackbox::p8(std::vector<double> x){
	double sum = 0;
	std::vector<double> z(_n);
	std::vector<double> I(_n,1.0);
	double t = std::max(sqrt(_n)/8,1.0);
	x = vectorSum(x, _xopt);
	ExternalProduct(t, x);
	z=vectorSum(x,I);
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for (int i = 0; i<_n-1; i++){
		double value = 100*pow(z[i]*z[i]-z[i+1],2) + pow(z[i]-1,2);
		sum += value;
	}
	return sum;
}

double Blackbox::p9(std::vector<double> x){
	double sum = 0;
	std::vector<double> z(_n);
	std::vector<double> O5(_n,0.5);
	double t = std::max(sqrt(_n)/8,1.0);
	RotationR(x);
	ExternalProduct(t,x);
	z=vectorSum(x,O5);
	//z = std::vector<double>(_n, 1.0); //to test the optimal value
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for (int i = 0; i<_n-1; i++){
		double value = 100*pow(z[i]*z[i]-z[i+1],2) + pow(z[i]-1,2);
		sum += value;
	}
	return sum;
}

double Blackbox::p10(std::vector<double> x){
	std::vector<double> z = vectorSum(x, _xopt);
	RotationR(z);
	Tosz(z);
	double sum = 0.0;
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for(int i = 0; i<_n; i++){
		double value = z[i]*z[i]*pow(10,6*i/(_n-1));
		sum += value;
	}
	return sum + _fopt;
}

double Blackbox::p11(std::vector<double> x){
	std::vector<double> z = vectorSum(x, _xopt);
	RotationR(z);
	Tosz(z);
	double sum = pow(10,6)*z[0]*z[0];
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for(int i =1; i<_n; i++){
		sum += z[i]*z[i];
	}
	return sum + _fopt;
}

double Blackbox::p12(std::vector<double> x){
	std::vector<double> z = vectorSum(x, _xopt);
	RotationR(z);
	Tasy(z);
	RotationR(z);
	double sum = z[0]*z[0];
	for(int i =1; i<_n; i++){
		sum += pow(10,6)*z[i]*z[i];
	}
	return sum + _fopt;
}

double Blackbox::p13(std::vector<double> x){

	std::vector<double> z = vectorSum(x, _xopt);
	RotationR(z);
	Lambda(z);
	RotationQ(z);
	double sum = 0.0;
	for(int i =1; i<_n; i++){
		sum += z[i]*z[i];
	}
	return z[0]*z[0]+ 100*sqrt(sum) + _fopt;
}

double Blackbox::p14(std::vector<double> x){
	double sum = 0;
	std::vector<double> z = vectorSum(x,_xopt);
	RotationR(z); //z = R(x-xopt)
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for (int i =0 ; i<_n; i++){
		double value = pow(abs(z[i]),2+4*double(i)/double(_n-1));
		sum += value;
	}
	return sqrt(sum);
}

double Blackbox::p15(std::vector<double> x){
	std::vector<double> z = vectorSum(x,_xopt);
	RotationR(z);
	Tosz(z);
	Tasy(z);
	RotationQ(z);
	Lambda(z);
	RotationR(z);
	double sum = 0;
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for(int i = 0; i<_n; i++){
		double value = cos(2*M_PI*z[i]);
		sum += value;
	}
	return 10*(_n-sum) + pow(Norm(z),2) + _fopt;
}

double Blackbox::p16(std::vector<double> x){
	std::vector<double> z = vectorSum(x, _xopt);
	RotationR(z);
	Tosz(z);
	RotationQ(z);
	Lambda(z);
	RotationR(z);
	// define f0 in constructor --------------------------------------------------
	double sum = 0;
#ifdef _PARALLEL2
	#pragma omp parallel for reduction(+:sum)
#endif
	for(int i = 0; i<_n; i++){
		double localSum = 0;
		for(int k = 0; k < 12 ; k++){
			localSum += cos(2*M_PI*pow(3,k)*(z[i]+0.5))/pow(2,k);
		}
		sum += localSum;
	}
	sum = (sum -_n*_f0)/double(_n);
	return 10*pow(sum,2) + (10.0/double(_n)) * Fpen(x) + _fopt ; //it should be a cube power but with a square it ensures that all problems are bounded below by 0 
}

double Blackbox::p17(std::vector<double> x){ // Only the value for Lambda is changing between p17 and p18

	std::vector<double> z = vectorSum(x,_xopt);
	RotationR(z);
	Tasy(z);
	RotationQ(z);

	Lambda(z); //Lambda*Q*Tasy(R*(x-xopt))
	double sum = 0;
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+ : sum)
#endif
	for(int i=0; i<_n-1; i++){
		double si = sqrt(z[i]*z[i]+z[i+1]*z[i+1]);
		double value = sqrt(si)*(1+pow(sin(50*pow(si,0.2)),2));
		sum += value;
	}
	sum = pow(1/float(_n-1)*sum,2) + 10*Fpen(x) + _fopt;
	return sum;
}

double Blackbox::p19(std::vector<double> x){
	RotationR(x);
	double v = std::max(sqrt(_n)/8.0,1.0);
	ExternalProduct(v,x);
	x = vectorSum(x,std::vector<double>(_n,0.5));
	//x = std::vector<double>(_n, 1.0); //to test the optimal value
	double sum = 0.0;
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for(int i = 1; i<_n; i++){
		double s = 100*pow(x[i-1]*x[i-1]-x[i],2) + pow(x[i-1]-1,2);
		sum += s/4000.0-cos(s);
	}
	return 10.0*sum/(double(_n)-1.0) + 10.0 + _fopt;
}

double Blackbox::p20(std::vector<double> x){
	//the paper is confusing about this function, for original definition, see https://www.sfu.ca/~ssurjano/schwef.html
	double opt = 4.2096874633;
	x = vectorSum(x,std::vector<double>(_n,-opt));

	Lambda(x); 
	RotationR(x); // I added this line to generate an instance depending on the seed
	x = vectorSum(x,_xopt);
	ExternalProduct(100.0,x);

	double sum = 0.0;
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum)
#endif
	for(int i = 0;i<_n; i++)
		sum += x[i]*sin(sqrt(abs(x[i])));

	ExternalProduct(0.01,x);
	return -sum/(100.0*double(_n)) + 4.189828872724339 + 100*Fpen(x) +_fopt;
}

double Blackbox::p21(std::vector<double> x){ //only the fixed values _hi are changing between 21 and 22
	// all the values of y, c, and alpha must be set in the constructor otherwise they will be set at each evaluation
	double val=0.0;
#ifdef _PARALLEL2
	#pragma omp parallel for reduction (std::max : val)
#endif
	for(int i = 0; i< _hi; i++){
		std::vector<double> diff = vectorSum(x,Y[i]);
		RotationR(diff);
		std::vector<double> quad = vectorProduct(C[i],diff);  // the minus sign is already in the std::vector y
		double expo = w[i]*exp(-ScalarProduct(diff,quad)/(2*double(_n)));
		val = std::max(expo,val);
	}
	val=10.0-val;
	std::vector<double> obj(1,val);
	Tosz(obj);
	return pow(obj[0],2)+Fpen(x)+_fopt;
}
double Blackbox::p23(std::vector<double> x){
	std::vector<double> z = vectorSum(x, _xopt);
	RotationR(z);
	Lambda(z);
	RotationQ(z);
	double prod = 1.0;
#ifdef _PARALLEL2
	#pragma omp parallel for reduction(* : prod)
#endif
	for(int i = 0; i<_n; i++){
		double sum = 0.0;
		for(int j = 1; j<33; j++){
			double val = pow(2,j)*z[i];
			double fracpart = val - floor(val);
			if (fracpart > 0.5)
				sum += abs(fracpart - 1.0)/pow(2,j);
			else
				sum += abs(fracpart)/pow(2,j);
		}
		sum = 1 + (i+1)*sum;
		prod = prod*pow(sum,10.0/pow(_n,1.2));
	}
	return 10.0*(prod - 1.0)/pow(_n,2) + Fpen(x) +_fopt;
}
double Blackbox::p24(std::vector<double> x){
	std::vector<double> sign(_n,0.0);
	for(int i = 0; i<_n; i++){
		if (_xopt[i]<0)
			sign[i] = -2.0;
		if (_xopt[i]>0)
			sign[i] = 2.0;
	}
	std::vector<double> hatx = vectorProduct(sign,x);
	std::vector<double> unit(_n, -2.5);
	std::vector<double> z = vectorSum(hatx, unit);
	RotationR(z);
	Lambda(z);
	RotationQ(z);
	double sum1=0.0, sum2=0.0, sum3=0.0;
#ifdef _PARALLEL
	#pragma omp parallel for reduction(+:sum1,sum2,sum3)
#endif
	for(int i = 0; i<_n; i++){
		sum1+= pow(hatx[i]-u0,2);
		sum2+= pow(hatx[i]-u1,2);
		sum3+= cos(2*M_PI*z[i]);
	}
	return std::min(sum1,d*_n+s*sum2)+10*(_n-sum3)+10000*Fpen(x) + _fopt;
}

string Blackbox::styrene(std::vector<double> x){

	size_t dim = 8; // styrene is of dim 8
	//std::string  cmd = "./../src/problems/STYRENE/bb/truth.exe "; // to use when working with runner/benchmarker.exe
	std::string  cmd = styreneDir+"/bb/truth.exe "; //to use when blackbox is run from /problems directory
	for(size_t i = 0 ;i<dim; i++){
		cmd+=std::to_string(x[i])+" ";
	}
	std::array<char, 128> buffer;
	std::string bbo="";

	//auto startEval = omp_get_wtime();
	std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);// we execute the commande and we store the result in pipe
	//auto stopEval = omp_get_wtime();

	if (!pipe) {
		throw std::runtime_error("popen() failed! : impossible to read blackbox output. Verify that "+styreneDir+"/bb/truth.exe exists, otherwise compile it by typing make in a terminal at the executable location.");
	}

	while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
		bbo += buffer.data();
	}
	return bbo;
}



string Blackbox::blackbox(std::vector<double> x) {
	switch (funcNum)
	{
	case 1:
		return std::to_string(p1(x));
		break;
	case 2:
		return std::to_string(p2(x));
		break;
	case 3:
		return std::to_string(p3(x));
		break;
	case 4:
		return std::to_string(p4(x));
		break;
	case 5:
		return std::to_string(p5(x));
		break;
	case 6:
		return std::to_string(p6(x));
		break;
	case 7:
		return std::to_string(p7(x));
		break;
	case 8:
		return std::to_string(p8(x));
		break;
	case 9:
		return std::to_string(p9(x));
		break;
	case 10:
		return std::to_string(p10(x));
		break;
	case 11:
		return std::to_string(p11(x));
		break;
	case 12:
		return std::to_string(p12(x));
		break;
	case 13:
		return std::to_string(p13(x));
		break;
	case 14:
		return std::to_string(p14(x));
		break;
	case 15:
		return std::to_string(p15(x));
		break;
	case 16:
		return std::to_string(p16(x));
		break;
	case 17:
		return std::to_string(p17(x));
		break;
	case 18:
		return std::to_string(p17(x));//only the constant values set in the constructor are changing
		break;
	case 19:
		return std::to_string(p19(x));
		break;
	case 20:
		return std::to_string(p20(x));
		break;
	case 21:
		return std::to_string(p21(x));
		break;
	case 22:
		return std::to_string(p21(x)); //only the constant values set in the constructor are changing
		break;
	case 23:
		return std::to_string(p23(x));
		break;
	case 24:
		return std::to_string(p24(x));
		break;
	case 25:
		return styrene(x);
		break;
	
// we can add call to external blackbox, like styrene with syscall
	default:
		throw std::runtime_error("problem no "+std::to_string(funcNum)+"not yet implemented.\n");
		return std::to_string(-1.0);
		break;
	}
}
