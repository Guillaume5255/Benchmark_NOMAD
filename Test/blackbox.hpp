#include <cmath>
#include <iostream>
#include <string>
#include <vector>
#include <list>

//#define _USE_MATH_DEFINES

using namespace std;

class Blackbox
{
public:
    Blackbox(const int n, const double alpha, const double beta, const int functionNumber);

    ~Blackbox(){};
    
    double f(vector<double> x);

private:
    int _n,funcNum;
    double _alpha;
    double _beta;
    vector<vector<double>> _Q,_R;

    vector<double> _xopt;
    vector<double> _ones;

    double _fopt;
    
    //helper methodes 
    vector<vector<double>> Householder(vector<double> direction);
    vector<double> LinearApplication(vector<vector<double>> M, vector<double> x );
    vector<double>  ExternalProduct(double y,vector<double> x);
    double ScalarProduct( vector<double> x ,vector<double> y); 
    vector<double> VectorProduct( vector<double> x ,vector<double> y); // VectorProduct((a,b),(c,d)) = (ab,cd)
    vector<vector<double>> MatrixProduct(vector<vector<double>> A, vector<vector<double>> B);
    vector<double> RandomDirection(int max);
    vector<double> VectorSum( vector<double> x ,vector<double> y);
    vector<double> RandomOnesVector(); //generates a _n dimensional vector with random ones 

    double Norm(vector<double> x);
    vector<double> Lambda();
    vector<double> Lambda(double a);
    double Fpen(vector<double> x);
    vector<double> Tasy(vector<double> x);
    vector<double> Tosz(vector<double> x);

};