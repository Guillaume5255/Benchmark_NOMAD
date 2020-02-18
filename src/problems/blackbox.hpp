#include <cmath>
#include <iostream>
#include <string>
#include <vector>
#include <bits/stdc++.h> 
#include <unistd.h>
#include <omp.h>
#include <algorithm>	// std::max


//#define _USE_MATH_DEFINES

//#define _PARALLEL2


using namespace std;

class Blackbox
{
public:
	Blackbox(const int dim,const int functionNumber, const int instance);
	~Blackbox(){};
	
	double f(std::vector<double> x) ;
	
	void DisplayTheoricalOptimal();
	
	std::vector<double> getX0(){return _x0;}
	std::vector<double> getXopt();

private: //to comment when doing unit test 
	const int _n,funcNum,pb_seed;	//dimension, problem number and seed for the generation of random matrix
	double _alpha, _beta, 
			_fopt = 0.0,
			_f0 = 0,	//used in problem 16
			u0,u1,s,d;	//used in problem 24

	int _hi;	//used in problems 21 and 22

	std::vector<std::vector<double>> _Q,_R,	//rotation matrix : randomly generated at the blackbox built 
									C, Y;	//random matrix used for problems 21 and 22
	std::vector<double> _x0,	//starting point, randomly chosen
						_xopt,	//value for optimal solution (when defined in the problem)
						_ones,	//vector with +1 or -1 coordiantes randomly distributed
						w,		//vector used for pb 21 and 22
						_theta, _phi;	//random rotation angles needed in RotationQ,R
	

	void ExternalProduct(double y,std::vector<double>& x);								//a.(x,y) = (ax,ay)
	std::vector<double> vectorProduct( std::vector<double> x ,std::vector<double> y);	//Product term by term : std::vectorProduct((a,b),(c,d)) = (ab,cd)
	std::vector<double> RandomDirection(double max);									//Generates a random std::vector in [[-max, max ]]^n (integer component)
	std::vector<double> vectorSum(std::vector<double> x ,std::vector<double> y);		//Inner sum of a std::vectorial space
	std::vector<double> RandomOnesvector();												//Generates a random std::vector in {-1,1}^n
	void Lambda(std::vector<double>& x);												// Diagonal matrix seen as a std::vector
	std::vector<double> Lambda(double a);
	void Tasy(std::vector<double>& x);													//Symetry breaker
	void Tosz(std::vector<double>& x);													//The input std::vector can be of any size
	void RotationQ(std::vector<double>& x);
	void RotationR(std::vector<double>& x);

	double ScalarProduct( std::vector<double> x ,std::vector<double> y);				//Cannonical scalar product
	double Norm(std::vector<double> x);													//Euclidian norm
	double Fpen(std::vector<double> x);													//Penalty to the objectif function

	double blackbox(std::vector<double> x);												//Code for the blackboxes (f calls blackbox after checking that the input is of the good size)
	
	void SetUpAngles();																	//set angles for the rotations
	void SetUpRandomValue(int hi);														// set random values for pb 21 and 22
	//analytical problems
	double p1(std::vector<double> x);
	double p2(std::vector<double> x);
	double p3(std::vector<double> x);
	double p4(std::vector<double> x);
	double p5(std::vector<double> x);
	double p6(std::vector<double> x);
	double p7(std::vector<double> x);
	double p8(std::vector<double> x);
	double p9(std::vector<double> x);
	double p10(std::vector<double> x);
	double p11(std::vector<double> x);
	double p12(std::vector<double> x);
	double p13(std::vector<double> x);
	double p14(std::vector<double> x);
	double p15(std::vector<double> x);
	double p16(std::vector<double> x);
	double p17(std::vector<double> x);

	double p19(std::vector<double> x);
	double p20(std::vector<double> x);
	double p21(std::vector<double> x);

	double p23(std::vector<double> x);
	double p24(std::vector<double> x);
};
