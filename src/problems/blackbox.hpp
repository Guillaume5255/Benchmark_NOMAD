#include <cmath>
#include <iostream>
#include <string>
#include <vector>
#include <bits/stdc++.h> 
#include <unistd.h>


//#define _USE_MATH_DEFINES

using namespace std;

class Blackbox
{
public:
    Blackbox(const int dim,const int functionNumber, const int instance);
    ~Blackbox(){};
    
    double f(std::vector<double> x) ;

//private: to comment when doing unit test 
    const int _n,funcNum,bseed; // dimension, problem number and seed for the generation of random matrix
    double _alpha, _beta, _fopt = 0.0, _hi;
    std::vector<std::vector<double>> _Q,_R, C, Y;
    std::vector<double> _xopt, _ones, w;
    
    //helper methodes
    std::vector<std::vector<double>> MatrixProduct(std::vector<std::vector<double>> A, std::vector<std::vector<double>> B) ;
    std::vector<std::vector<double>> Householder(std::vector<double> direction) ;                           //  Given a  normalized direction, returns the computation of the associated householder matrix
    
    std::vector<double> LinearApplication(std::vector<std::vector<double>> M, std::vector<double> x );          //  Given a matrix M and a std::vector x, computes the product Mx
    std::vector<double> ExternalProduct(double y,std::vector<double> x);                              //  a.(x,y) = (ax,ay)
    std::vector<double> vectorProduct( std::vector<double> x ,std::vector<double> y);                      //  Product term by term : std::vectorProduct((a,b),(c,d)) = (ab,cd)
    std::vector<double> RandomDirection(int max);                                                //  Generates a random std::vector in [[-max, max ]]^n (integer component)
    std::vector<double> vectorSum(std::vector<double> x ,std::vector<double> y);                          //  Inner sum of a std::vectorial space
    std::vector<double> RandomOnesvector();                                                      //  Generates a random std::vector in {-1,1}^n
    std::vector<double> Lambda();                                                                //  Diagonal matrix seen as a std::vector
    std::vector<double> Lambda(double a);
    std::vector<double> Tasy(std::vector<double> x);                                                  //  Symetry breaker
    std::vector<double> Tosz(std::vector<double> x);                                                  //  The input std::vector can be of any size
    
    double ScalarProduct( std::vector<double> x ,std::vector<double> y);                              //  Cannonical scalar product
    double Norm(std::vector<double> x);                                                          //  Euclidian norm
    double Fpen(std::vector<double> x);                                                          //  Penalty to the objectif function

    double blackbox(std::vector<double> x);                                                      //  Code for the blackboxes (f calls blackbox after checking that the input is of the good size)
    
    void SetUpRandomValue(int hi);
    void DisplayTheoricalOptimal();
    void Normalize(std::vector<std::vector<double>> &M);

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