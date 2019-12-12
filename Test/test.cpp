#include <cmath>
#include <iostream>
#include <string>
#include <vector>
#include <omp.h>

using namespace std;

//#define _PARALLEL

int _n = 1000;

std::vector<double> RandomDirection(int max){ // generates a random std::vector in [[-max, max ]]^n
    std::vector<double> x(_n,0.0);
    double norm = 0.0;
    for(int i = 0 ; i <_n ;i++ ){
        x[i] =  double(rand()%(2*max) -max);
        norm += x[i]*x[i];
    }
    norm = sqrt(norm);
    for(int i = 0; i<_n; i++){
        x[i]=x[i]/norm;
    }
    return x;
}

double* RandomArr(int max){ // generates a random std::vector in [[-max, max ]]^n
    double * x = new double[_n];
    double norm = 0.0;
    for(int i = 0 ; i <_n ;i++ ){
        x[i] =  double(rand()%(2*max) -max);
        norm += x[i]*x[i];
    }
    norm = sqrt(norm);
    for(int i = 0; i<_n; i++){
        x[i]=x[i]/norm;
    }
    return x;
}

std::vector<std::vector<double>> MatrixPr(std::vector<std::vector<double>> A, std::vector<std::vector<double>> B){ // given 2 square matrix A and B, returns the product AB

    std::vector<std::vector<double>> C(_n,std::vector<double>(_n)); //allocating the space for the output 
#ifdef _PARALLEL
	#pragma omp parallel for collapse(2) // shared(C) //schedule(guided,1024)
#endif
    for(int i = 0; i<_n; i++){
    	for(int j = 0; j<_n; j++){
    		double cij = 0;
#ifdef _PARALLEL
            //#pragma omp parallel for reduction(+ : cij) 
#endif
    		for(int k = 0; k<_n; k++)
    			cij += A[i][k]*B[k][j];

    		C[i][j] = cij;
    	}
    }

    return C;
}

double** ArrayPr(double **A, double **B){
    double **C = new double*[_n];
    for(int i = 0; i<_n; i++)
        C[i] = new double[_n];

#ifdef _PARALLEL
	#pragma omp parallel for collapse(2)// shared(C) //schedule(guided,1024)
#endif
    for(int i = 0; i<_n; i++){
    	for(int j = 0; j<_n; j++){
    		double cij = 0;
#ifdef _PARALLEL
            #pragma omp parallel for reduction(+ : cij) 
#endif
    		for(int k = 0; k<_n; k++)
    			cij += A[i][k]*B[k][j];

    		C[i][j] = cij;
    	}
    }
    return C;
}

int main(){
    double **A = new double*[_n];
    double **B = new double*[_n];
    std::vector<std::vector<double>> C(_n,std::vector<double>(_n,0.0)), D(_n,std::vector<double>(_n,0.0));
    std::cout<<"initialisation des matrices et des tableaux\n";
    srand (51);
    for(int i = 0; i<_n; i++){
        A[i] = RandomArr(100000);
        B[i] = RandomArr(100000);
    }
    srand (51);
    for(int i = 0; i<_n; i++){
        C[i] = RandomDirection(100000);
        D[i] = RandomDirection(100000);
    }
    std::cout<<"debut du produit (vecteurs)\n";
    
    auto startMat = omp_get_wtime();
    auto res1 = MatrixPr(C,D);
    auto stopMat = omp_get_wtime();
    
    std::cout<<"debut du produit (tableaux)\n";

    auto startArr = omp_get_wtime();
    auto res2 =ArrayPr(A,B);
    auto stopArr = omp_get_wtime();

    auto timeMat = stopMat-startMat, timeArr = stopArr-startArr;
    std::cout<<"Duree de multiplication vecteurs : "<<timeMat<<"\n";
    std::cout<<"Duree de multiplication tableaux : "<<timeArr<<"\n";
    std::cout<<res1[27][265]<<"---"<<res1[835][492]<<"\n";
    std::cout<<res2[27][265]<<"---"<<res2[835][492]<<"\n";




}