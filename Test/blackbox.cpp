#include "blackbox.hpp"

Blackbox::Blackbox(const int n, const double alpha, const double beta, const int functionNumber){
    funcNum = functionNumber;
    _n = n;
    _alpha = alpha; // TODO:delete those values form the parameters of construtor
    _beta = beta;
    srand (0.123);

    _ones = RandomOnesVector();
    _xopt = vector<double>(_n,0.0);

    _fopt = 1;

    vector<double> u = RandomDirection(5); // we compute 2 random directions 
    vector<double> v = RandomDirection(5);
 
    double n_U = Norm(u); // we compute their norms 
    double n_V = Norm(v);
 
    
    // with those 2 directions, we generate 2 random orthogonal matrix (let's say A and B) 
    //and we compute the product Q=A^2 and R=B^2 that are rotation matrix (det(Q) = det(A^2) =det(A)^2 = 1)
    vector<vector<double>> A = Householder(ExternalProduct(1/n_U,u));
    vector<vector<double>> B = Householder(ExternalProduct(1/n_V,v));

    _Q = MatrixProduct(A,A); 
    _R = MatrixProduct(B,B);    
}

vector<double> Blackbox::LinearApplication(vector<vector<double>> M, vector<double> x ){ // given a matrix M and a vector x, computes the product Mx
    vector<double> y(_n);
    double yj;
    for(int j = 0; j<_n; j++){
        yj = 0;
        for(int i = 0; i<_n ;i++){
            yj = yj+M[i][j]*x[i];
        }
        y[j]=yj;
    }
    return y;
}

vector<vector<double>> Blackbox::MatrixProduct(vector<vector<double>> A, vector<vector<double>> B){ // given 2 square matrix A and B, returns the product AB
    vector<vector<double>> C(_n);
    for(int i = 0; i<_n; i++){
        C[i]= LinearApplication(A, B[i]);
    }
    return C;
}

vector<double> Blackbox::RandomDirection(int max){ // generates a random vector in [[-max, max ]]^n
    vector<double> x(_n,0.0);
    for(int i = 0 ; i <_n ;i++ ){
        x[i] =  double(rand()%(2*max) -max);
    }
    return x;
}

vector<double> Blackbox::RandomOnesVector(){ // generates a random vector in {-1,1}^n
    vector<double> x(_n,0.0);
    for(int i = 0 ; i <_n ;i++ ){
        x[i] =  double(rand()%2);
        if (x[i]=0.0)
            x[i] = -1.0;
        else 
            x[i] = 1.0;
    }
    return x;
}


vector<vector<double>> Blackbox::Householder(vector<double> direction){ //given a  normalized direction, returns the computation of the associated householder matrix
    vector<vector<double>> H(_n);
    vector<double> Hj(_n);
    for(int j = 0; j<_n; j++){
        for(int i = 0; i<_n ;i++){
            Hj[i]= -2*direction[i]*direction[j];
            if (i==j)
               Hj[i] = Hj[i]+1;
        }
        H[j]=Hj;
    }
    return H;
}


vector<double> Blackbox::ExternalProduct(double y,vector<double> x){ // a.(x,y) = (ax,ay) 
    vector<double> z(_n);
    for(int i=0; i<_n; i++){
        z[i]=x[i]*y;
    }
    return z;
}


double Blackbox::ScalarProduct(vector<double> x ,vector<double> y){ // cannonical scalar product
    double z;
    for(int i=0; i<_n; i++){
        z+=x[i]*y[i];
    }
    return z;
}


vector<double>  Blackbox::VectorProduct( vector<double> x ,vector<double> y){ // product term by term : VectorProduct((a,b),(c,d)) = (ab,cd)
    vector<double> z(_n);
    for(int i=0; i<_n; i++){
        z[i]=x[i]*y[i];
    }
    return z;
}
vector<double> Blackbox::VectorSum( vector<double> x ,vector<double> y){ // inner sum of a vectorial space
    vector<double> sum(_n,0);
    for(int i = 0; i<_n; i++){
        sum[i]= x[i]+y[i];
    }
    return sum;
}

double Blackbox::Norm(vector<double> x){ // euclidian norm
    double norm = 0;
    for(int i=0; i<_n; i++){
        norm += x[i]*x[i];
    }
    return sqrt(norm);
}
vector<double> Blackbox::Lambda(){ // diagonal matrix seen as a vector 
    vector<double> lambda(_n);
    double exponent = 0;
    for(int i=0; i<_n; i++){
        exponent=0.5*float(i-1)/float(_n-1);
        lambda[i] = pow (_alpha, exponent);
    }
    return lambda;
}

vector<double> Blackbox::Lambda(double a){ // diagonal matrix seen as a vector 
    vector<double> lambda(_n);
    double exponent = 0;
    for(int i=0; i<_n; i++){
        exponent=0.5*float(i-1)/float(_n-1);
        lambda[i] = pow (a, exponent);
    }
    return lambda;
}

double Blackbox::Fpen(vector<double> x){ //penalty 
    double fpen = 0;
    double t = 0;
    for(int i=0; i<_n; i++){
        t=abs(x[i])-5;
        if(t>0){fpen += t*t;}
    }
    return fpen;
}
vector<double> Blackbox::Tasy(vector<double> x){ //symetry breaker 
    vector<double> tasy(_n);
    double exponent;
    for(int i=0; i<_n; i++){
        if(x[i]>0){
            exponent=1+_beta*float(i-1)/float(_n-1)*sqrt(x[i]);
            tasy[i]=pow (x[i], exponent);
        }
        else{
            tasy[i]=x[i];
        }
    }
    return tasy;
}
vector<double> Blackbox::Tosz(vector<double> x){ // the input vector can be of any size

    vector<double> tosz(x.size());
    double xhat = 0;
    double signx = 0;
    double c1=0;
    double c2=0;

    for(int i=0; i<_n; i++){
        if(x[i]!=0){ xhat = log(abs(x[i]));}
        else{ xhat = 0;}

        if(x[i]>0){signx=1;}
        if(x[i]<0){signx=-1;}
        else {signx=0;}

        if (x[i]>0){c1=10; c2=7.9;}
        else {c1=5.5;c2=3.1;}

        tosz[i]=signx*exp(xhat+0.049*(sin(c1*xhat)+sin(c2*xhat)));
    }
    return tosz;
}

double Blackbox::f(vector<double> x){ //objective function
    if (funcNum == 1)
        return Norm(VectorSum(x,ExternalProduct(-1.0,_xopt))) + _fopt;
    if (funcNum == 2){
        vector<double> z = Tosz(VectorSum(x,ExternalProduct(-1.0,_xopt)));
        double sum = 0;
        for(int i = 0; i<_n; i++){
            sum += pow(10, 6*i/(_n-1))*z[i]*z[i];
        }
        return sum;
    }
    if (funcNum == 3){
        vector<double> z = VectorProduct(Lambda(),Tasy(Tosz(VectorSum(x,ExternalProduct(-1.0,_xopt)))));
        double sum = 0;
        for(int i = 0; i<_n; i++){
            sum += (double)cos(2*M_PI*z[i]);
        }
        return 10*(_n-sum) + pow(Norm(z),2) + _fopt;

    }
    if (funcNum == 4){
        vector<double> s(_n);
        for(int i = 0; i<_n; i++){
            if (x[i]>0) // i think there is an error in the paper
                s[i] = 10*pow(10, 0.5*i/(_n-1));
            else 
                s[i] = 10*pow(10, 0.5*i/(_n-1));
        }
        vector<double> z = VectorProduct(s,Tosz(VectorSum(x, ExternalProduct(-1.0,_xopt))));
        double sum = 0;
        for(int i = 0; i<_n; i++){
            sum += z[i]*z[i] - 10*cos(2*M_PI*z[i]);
        }
        return 10*_n+sum + 100*Fpen(x) +_fopt;
    }
    if (funcNum == 5){
 
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
    if (funcNum == 6){
        vector<double> z = VectorProduct(LinearApplication(_Q,Lambda()),LinearApplication(_R,VectorSum(x,ExternalProduct(-1,_xopt))));
        vector<double> sum(1,0.0);
        double si= 0 ;
        for(int i = 0; i<_n; i++){
            si =_xopt[i]*z[i];
            if (_xopt[i]*z[i] >0)
                sum[0] += pow(100*z[i],2);
            else
            {
                sum[0] += pow(z[i],2);
            }
        }
        return pow(Tosz(sum)[0],0.9) + _fopt;
    }
    if (funcNum == 7){
        vector<double> hatz = VectorProduct(Lambda(),LinearApplication(_R,VectorSum(x,ExternalProduct(-1,_xopt))));
        vector<double> tildez(_n);
        for(int i = 0; i<_n; i++){
            if (abs(hatz[i])>0.5)
                tildez[i] = floor(0.5+hatz[i]);
            else
                tildez[i] = floor(0.5+10*hatz[i])/10.0;
            
        }
        vector<double> z =  LinearApplication(_Q, tildez);
        double sum = 0.0;
        for(int i = 0; i<_n; i++){
            sum += pow(10, 2*i/double(_n-1))*z[i]*z[i];
        }
        if(sum > abs(z[1])/10000)
            return 0.1*sum + Fpen(x) + _fopt;
        else
            return 0.1*abs(z[1])/10000 + Fpen(x) + _fopt;
    }
    if (funcNum == 8){
        double sum = 0;
        vector<double> z(_n);
        vector<double> I(_n,1.0);
        double t = sqrt(_n)/8;
        if (t>1){
            z=VectorSum(ExternalProduct(t, VectorSum(x, ExternalProduct(-1.0, _xopt))),I);
        }
        else
        {
            z=VectorSum(ExternalProduct(1.0, VectorSum(x, ExternalProduct(-1.0, _xopt))),I);
        }    
        
        for (int i = 0; i<_n-1; i++){
            sum = sum + 100*pow(z[i]*z[i]-z[i+1],2) + pow(z[i]-1,2);
        }
        return sum;
    }
    if (funcNum == 9){
        double sum = 0;
        vector<double> z(_n);
        vector<double> O5(_n,0.5);
        double t = sqrt(_n)/8;
        if (t>1){
            z=VectorSum(ExternalProduct(t,LinearApplication(_R,x)),O5);
        }
        else
        {
            z=VectorSum(LinearApplication(_R,x),O5);
        }    
        
        for (int i = 0; i<_n-1; i++){
            sum = sum + 100*pow(z[i]*z[i]-z[i+1],2) + pow(z[i]-1,2);
        }
        return sum;
    }
    if (funcNum == 10){
        vector<double> z = Tosz(LinearApplication(_R, VectorSum(x, ExternalProduct(-1.0,_xopt))));
        double sum = 0.0;
        for(int i =0; i<_n; i++){
            sum += z[i]*z[i]*pow(10,6*i/(_n-1));
        }
        return sum + _fopt;
    }
    if (funcNum == 11){
        vector<double> z = Tosz(LinearApplication(_R, VectorSum(x, ExternalProduct(-1.0,_xopt))));
        double sum = pow(10,6)*z[0]*z[0];
        for(int i =1; i<_n; i++){
            sum += z[i]*z[i];
        }
        return sum + _fopt;
    }
    if (funcNum == 12){
        vector<double> z = LinearApplication(_R,Tasy(LinearApplication(_R, VectorSum(x, ExternalProduct(-1.0,_xopt)))));
        double sum = z[0]*z[0];
        for(int i =1; i<_n; i++){
            sum += pow(10,6)*z[i]*z[i];
        }
        return sum + _fopt;
    }
    if (funcNum == 13){
        vector<double> z = LinearApplication(_Q,VectorProduct(Lambda(),LinearApplication(_R, VectorSum(x, ExternalProduct(-1.0,_xopt)))));
        double sum = 0.0;
        for(int i =1; i<_n; i++){
            sum += z[i]*z[i];
        }
        return z[0]*z[0]+ 100*sqrt(sum) + _fopt;
    }
    if (funcNum == 14){
        double sum = 0;
        vector<double> z = LinearApplication(_R,VectorSum(x,ExternalProduct(-1.0,_xopt))); //z = R(x-xopt)
        for (int i =0 ; i<_n; i++){
            sum = sum + pow(abs(z[i]),2+4*double(i-1)/double(_n-1));
        }
        return sqrt(sum);
    }
    if (funcNum == 15){
        vector<double> z = LinearApplication(_R, VectorSum(x, ExternalProduct(-1.0,_xopt)));
        z = Tosz(z);
        z = Tasy(z);
        z = LinearApplication(_Q,z);
        z = VectorProduct(Lambda(), z);
        z = LinearApplication(_R, z);
        double sum = 0;
        for(int i = 0; i<_n; i++){
            sum += cos(2*M_PI*z[i]);
        }
        return 10*(_n-sum) + pow(Norm(z),2) + _fopt;
    }
    if (funcNum == 16){
        vector<double> z = LinearApplication(_R, VectorSum(x, ExternalProduct(-1.0,_xopt)));
        z = Tosz(z);
        z = LinearApplication(_Q,z);
        z = VectorProduct(Lambda(), z);
        z = LinearApplication(_R, z);
        // define f0 in constructor
        double f0 = 0;
        for(int k =0; k < 12; k++){
            f0+=cos(M_PI*pow(3,k))/pow(2,k);
        }
        double sum = 0;
        for(int i = 0; i<_n; i++){
            for(int k = 0; k < 12 ; k++){
                sum += cos(2*M_PI*pow(3,k)*(z[i]+0.5));
            }
        }
        return 10*pow(1.0/double(_n)*sum -f0,3) + 10.0/double(_n) * Fpen(x) + _fopt ;
    }
    if (funcNum == 17 || funcNum == 18){ // Only the value for Lambda is changing
        
        vector<double> z = VectorProduct(Lambda(),LinearApplication(_Q,Tasy(LinearApplication(_R,VectorSum(x,ExternalProduct(-1.0,_xopt)))))); //Lambda*Q*Tasy(R*(x-xopt))
        double sum = 0;
        double si = 0;
        
        for(int i=0; i<_n-1; i++){
            si = sqrt(z[i]*z[i]+z[i+1]*z[i+1]);
            sum += sqrt(si)*(1+pow(sin(50*pow(si,0.2)),2));
        }
        sum = pow(1/float(_n-1)*sum,2) + 10*Fpen(x);
        return sum;
    }
    if (funcNum == 19){
        vector<double> z = LinearApplication(_R,x);
        double v = sqrt(_n)/double(8);
        if(v<1.0)
            v=1.0;
        z[0] += v + 0.5;
        double s = 0.0;
        double sum = 0.0;
        for(int i = 1; i<_n; i++){
            z[i] +=  v + 0.5;
            s = 100*pow(z[i-1]*z[i-1]-z[i],2) + pow(z[i-1]-1,2);
            sum += s/4000.0-cos(s);
        }
        return 10.0*sum/(double(_n)-1.0) + 10.0 + _fopt;
    }
    if (funcNum == 20){
        vector<double> hatx = ExternalProduct(2.0,VectorProduct(_ones, x));
        vector<double> hatz(_n,0.0);
        hatz[0] = hatx[1];
        for(int i = 1; i<_n; i++){
            hatz[i]=hatx[i] +0.25*(hatx[i-1]-2*abs(_xopt[i-1]));
        }
        vector<double> absxopt = _xopt; // TODO : set up xopt in constructor
        for( int i = 0; i<_n;i++){
            if (absxopt[i]<0.0)
                absxopt[i] = -absxopt[i];
        } 
        vector<double> z = VectorProduct(Lambda(), VectorSum(hatz,ExternalProduct(2.0, absxopt)));
        z = VectorSum(z, ExternalProduct(2.0, absxopt));
        z = ExternalProduct(100.0,z);
        double sum = 0.0;
        for(int i = 0;i<_n; i++){
            sum += z[i]*sin(sqrt(abs(z[i])));
        }
        return (-1.0/(100.0*double(_n)))*sum + 4.189828872724339 + 100*Fpen(ExternalProduct(1.0/100.0,z)) +_fopt;
    }
    if (funcNum == 21){
        return -1.254;
    }
    if (funcNum == 22){
        return -1.254;
    }
    if (funcNum == 23){
        vector<double> z = LinearApplication(_R, VectorSum(x, ExternalProduct(-1.0,_xopt)));
        z = VectorProduct(Lambda(), z);
        z = LinearApplication(_Q, z);
        double prod = 1.0;
        double sum = 0.0;
        for(int i = 0; i<_n; i++){
            sum = 0.0;
            for(int j = 1; j<33; j++){
                sum += abs(pow(2,j)*z[i]-floor(pow(2,j)*z[i]))/pow(2,j); 
            }
            sum = 1 + (i+1)*sum;
            prod = prod*pow(sum,10.0/pow(_n,1.2));
        }
        return 10.0*(prod - 1.0)/pow(_n,2) + Fpen(x) +_fopt;
    }
    if (funcNum == 24){
        // TODO : set up xopt in constructor
        vector<double> sign(_n,0.0);
        for(int i = 0; i<_n; i++){
            if (_xopt[i]<0)
                sign[i] = -1.0;
            if (_xopt[i]>0)
                sign[i] = 1.0;
        }
        vector<double> hatx = VectorProduct(ExternalProduct(2.0,sign),x);
        vector<double> unit(_n, -2.5);
        vector<double> z = LinearApplication(_R, VectorSum(hatx, unit));
        z = VectorProduct(Lambda(), z);
        z = LinearApplication(_Q, z);
        double s = 1-1/(2*sqrt(_n+20)-8.2);
        double u1 = -sqrt((2.5*2.5-1)/s);
        double sum1=0.0, sum2=0.0, sum3=0.0;
        for(int i = 0; i<_n; i++){
            sum1+= pow(hatx[i]-2.5,2);
            sum2+= pow(hatx[i]-u1,2);
            sum3+= cos(2*M_PI*z[i]);
        }
        if (sum1>sum2)
            return sum2+10*(_n-sum3)+10000*Fpen(x) + _fopt;
        else
            return sum1+10*(_n-sum3)+10000*Fpen(x) + _fopt;
    }
    else{
        return -1.254;
    }
}
