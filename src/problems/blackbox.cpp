#include "blackbox.hpp"

Blackbox::Blackbox(const int dim, const int functionNumber, const int instance ):_n(dim), funcNum(functionNumber), bseed(instance){
    srand (bseed);
    _xopt = std::vector<double>(_n,0.0);
    _ones = RandomOnesvector();
    std::vector<double> u = RandomDirection(1000); // we compute 3 random directions in the box [[-1000,1000]]
    std::vector<double> v = RandomDirection(1000);
    std::vector<double> t = RandomDirection(1000);

    double n_U = Norm(u); // we compute their norms 
    double n_V = Norm(v);
    double n_T = Norm(t);
    
    // with those 3 directions, we generate 3 householder matrix (let's say A, B and C) of determinant -1
    std::vector<std::vector<double>> A = Householder(ExternalProduct(1/n_U,u));
    std::vector<std::vector<double>> B = Householder(ExternalProduct(1/n_V,v));
    std::vector<std::vector<double>> C = Householder(ExternalProduct(1/n_T,t));

    Normalize(A);
    Normalize(B);
    Normalize(C);

    //and we compute the product Q=AB and R=AC that are rotation matrix (det(Q) = det(AB) =det(A)det(B) = -1*-1=1)
    _Q = MatrixProduct(A,C); 
    _R = MatrixProduct(B,C);
    switch (funcNum) {

        case 3: _alpha = 10;    
                _beta = 0.2; 
                break;
        case 5: _xopt = ExternalProduct(5.0,_ones);
                break;

        case 6: _alpha = 10;
                break;
        case 7: _alpha = 10;
                break;

        case 12: _beta = 0.5;
                break;
        case 13: _alpha = 10;
                break;

        case 15: _alpha = 10;
                _beta = 0.2;
                break;
        case 16: _alpha = 0.01;
                break;
        case 17: _alpha = 10;
                _beta = 0.5;
                break;
        case 18: _alpha = 1000;
                _beta = 0.5;
                break;

        case 20: _alpha = 10;
                break;
        case 21: _hi = 101;
                SetUpRandomValue(_hi);
                _xopt = Y[0];
                break;
        case 22: _hi = 21;
                SetUpRandomValue(_hi);
                _xopt = Y[0];
                break;
        case 23: _alpha = 100;
                break;
        case 24: _alpha = 100;
                break;
        default:
                break;
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
            Y[i] = RandomDirection(4);
        else{
            w[i] = 1.1+8*(i-1)/hi;
            Y[i] = RandomDirection(5);
        }
        C[i] = ExternalProduct(1.0/pow(a[i],0.25),Lambda(a[i]));
        random_shuffle(C[i].begin(), C[i].end());
    }
}

std::vector<double> Blackbox::LinearApplication(std::vector<std::vector<double>> M, std::vector<double> x ){ // given a matrix M and a std::vector x, computes the product Mx
//M[i] represnts a line of M
    std::vector<double> y(_n, 0.0);
    for(int i = 0; i<_n ;i++){
    	for(int j = 0; j<_n; j++)
            y[i] += M[i][j]*x[j];
    }
    return y;
}

std::vector<std::vector<double>> Blackbox::MatrixProduct(std::vector<std::vector<double>> A, std::vector<std::vector<double>> B){ // given 2 square matrix A and B, returns the product AB

    std::vector<std::vector<double>> C(_n); //allocating the space for the output 
	for(int j = 0; j<_n;j++)
		C[j]=std::vector<double>(_n);
		
		
    for(int i = 0; i<_n; i++){
    	for(int j = 0; j<_n; j++){
    		double cij = 0;
    		for(int k = 0; k<_n; k++)
    			cij += A[i][k]*B[k][j];
    		C[i][j] = cij;
    	}
    }

    return C;
}

std::vector<double> Blackbox::RandomDirection(int max){ // generates a random std::vector in [[-max, max ]]^n
    std::vector<double> x(_n,0.0);
    for(int i = 0 ; i <_n ;i++ )
        x[i] =  double(rand()%(2*max) -max);
    return x;
}

std::vector<double> Blackbox::RandomOnesvector(){ // generates a random std::vector in {-1,1}^n
    std::vector<double> x(_n,0.0);
    for(int i = 0 ; i <_n ;i++ ){
        x[i] =  double(rand()%2);
        if (x[i]==0.0)
            x[i] = -1.0;
        else 
            x[i] = 1.0;
    }
    return x;
}

std::vector<std::vector<double>> Blackbox::Householder(std::vector<double> direction){ //given a  normalized direction, returns the computation of the associated householder matrix
    std::vector<std::vector<double>> H(_n);
    std::vector<double> Hj(_n);
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

void Blackbox::Normalize(std::vector<std::vector<double>> &M){
    for(int i = 0; i<_n ; i++)
        M[i] = ExternalProduct(Norm(M[i]),M[i]);

}

std::vector<double> Blackbox::ExternalProduct(double y,std::vector<double> x){ // a.(x,y) = (ax,ay) 
    std::vector<double> z(_n);
    for(int i=0; i<_n; i++)
        z[i]=x[i]*y;

    return z;
}

double Blackbox::ScalarProduct(std::vector<double> x ,std::vector<double> y){ // cannonical scalar product
    double z=0.0;
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
    for(int i=0; i<_n; i++)
        norm += x[i]*x[i];

    return sqrt(norm);
}

std::vector<double> Blackbox::Lambda(){ // diagonal matrix seen as a std::vector 
    std::vector<double> lambda(_n);
    double exponent = 0;
    for(int i=0; i<_n; i++){
        exponent=0.5*float(i-1)/float(_n-1);
        lambda[i] = pow (_alpha, exponent);
    }
    return lambda;
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
    double t = 0;
    for(int i=0; i<_n; i++){
        t=abs(x[i])-5;
        if(t>0)
            fpen += t*t;
    }
    return fpen;
}

std::vector<double> Blackbox::Tasy(std::vector<double> x){ //symetry breaker 
    std::vector<double> tasy(_n);
    double exponent;
    for(int i=0; i<_n; i++){
        if(x[i]>0){
            exponent=1+_beta*double(i-1)/double(_n-1)*sqrt(x[i]);
            tasy[i]=pow (x[i], exponent);
        }
        else
            tasy[i]=x[i];
    }
    return tasy;
}

std::vector<double> Blackbox::Tosz(std::vector<double> x){ // the input std::vector can be of any size
    double taille = x.size();
    std::vector<double> tosz(taille,0.0);
    double xhat;
    double signedex=0.0;
    double c1=0;
    double c2=0;

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
        tosz[i]=signedex*exp(xhat+0.049*(sin(c1*xhat)+sin(c2*xhat)));
    }
    return tosz;
}

void Blackbox::DisplayTheoricalOptimal(){
    for(int i = 0; i<_n; i++){
        std::cout<<"(";
        std::cout<<_xopt[i]<<"\t";
        std::cout<<")";
    }
    
}

double Blackbox::f(std::vector<double> x){ //wrapper to be sure x is of the good dimension 
    //usleep(1000000);
    if ((int)x.size() == _n)
        return blackbox(x);
    else
    {
        std::cout<<"x is of dimension "<< x.size() <<"but blackbox takes "<< _n <<" input parameters";
        return -1.0;
    } 
}

double Blackbox::p1(std::vector<double> x){
    return Norm(vectorSum(x,ExternalProduct(-1.0,_xopt))) + _fopt;

}

double Blackbox::p2(std::vector<double> x){
    std::vector<double> z = Tosz(vectorSum(x,ExternalProduct(-1.0,_xopt)));
    double sum = 0;
    for(int i = 0; i<_n; i++){
        sum += pow(10, 6*i/(_n-1))*z[i]*z[i];
    }
    return sum;
}

double Blackbox::p3(std::vector<double> x){
    std::vector<double> z = vectorProduct(Lambda(),Tasy(Tosz(vectorSum(x,ExternalProduct(-1.0,_xopt)))));
    double sum = 0;
    for(int i = 0; i<_n; i++){
        sum += (double)cos(2*M_PI*z[i]);
    }
    return 10*(_n-sum) + pow(Norm(z),2) + _fopt;
}

double Blackbox::p4(std::vector<double> x){
    std::vector<double> s(_n);
    for(int i = 0; i<_n; i++){
        if (x[i]>0) // i think there is an error in the paper
            s[i] = 10*pow(10, 0.5*i/(_n-1));
        else 
            s[i] = 10*pow(10, 0.5*i/(_n-1));
    }
    std::vector<double> z = vectorProduct(s,Tosz(vectorSum(x, ExternalProduct(-1.0,_xopt))));
    double sum = 0;
    for(int i = 0; i<_n; i++){
        sum += z[i]*z[i] - 10*cos(2*M_PI*z[i]);
    }
    return 10*_n+sum + 100*Fpen(x) +_fopt;
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
    std::vector<double> z = vectorProduct(LinearApplication(_Q,Lambda()),LinearApplication(_R,vectorSum(x,ExternalProduct(-1,_xopt))));
    std::vector<double> sum(1,0.0);
    double si= 0 ;
    for(int i = 0; i<_n; i++){
        si =_xopt[i]*z[i];
        if (si >0)
            sum[0] += pow(100*z[i],2);
        else
            sum[0] += pow(z[i],2);
    }
    return pow(Tosz(sum)[0],0.9) + _fopt;
}

double Blackbox::p7(std::vector<double> x){
    std::vector<double> hatz = vectorProduct(Lambda(),LinearApplication(_R,vectorSum(x,ExternalProduct(-1.0,_xopt))));
    std::vector<double> tildez(_n,0.0);
        
    for(int i = 0; i<_n; i++){
        if (abs(hatz[i])>0.5)
            tildez[i] = floor(0.5+hatz[i]);
        else
            tildez[i] = floor(0.5+10*hatz[i])/10.0;        
    }
    std::vector<double> z =  LinearApplication(_Q, tildez);
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
    double t = sqrt(_n)/8;

    if (t>1)
        z=vectorSum(ExternalProduct(t, vectorSum(x, ExternalProduct(-1.0, _xopt))),I);
    else
        z=vectorSum(ExternalProduct(1.0, vectorSum(x, ExternalProduct(-1.0, _xopt))),I); 
        
    for (int i = 0; i<_n-1; i++)
        sum = sum + 100*pow(z[i]*z[i]-z[i+1],2) + pow(z[i]-1,2);
    
    return sum;
}

double Blackbox::p9(std::vector<double> x){
    double sum = 0;
    std::vector<double> z(_n);
    std::vector<double> O5(_n,0.5);
    double t = sqrt(_n)/8;
    if (t>1)
        z=vectorSum(ExternalProduct(t,LinearApplication(_R,x)),O5);
    else
        z=vectorSum(LinearApplication(_R,x),O5); 
    
    for (int i = 0; i<_n-1; i++)
        sum = sum + 100*pow(z[i]*z[i]-z[i+1],2) + pow(z[i]-1,2);
    
    return sum;
}

double Blackbox::p10(std::vector<double> x){
    std::vector<double> z = Tosz(LinearApplication(_R, vectorSum(x, ExternalProduct(-1.0,_xopt))));
    double sum = 0.0;
    for(int i =0; i<_n; i++){
        sum += z[i]*z[i]*pow(10,6*i/(_n-1));
    }
    return sum + _fopt;
}

double Blackbox::p11(std::vector<double> x){
    std::vector<double> z = Tosz(LinearApplication(_R, vectorSum(x, ExternalProduct(-1.0,_xopt))));
    double sum = pow(10,6)*z[0]*z[0];
    for(int i =1; i<_n; i++){
        sum += z[i]*z[i];
    }
    return sum + _fopt;
}

double Blackbox::p12(std::vector<double> x){
    std::vector<double> z = LinearApplication(_R,Tasy(LinearApplication(_R, vectorSum(x, ExternalProduct(-1.0,_xopt)))));
    double sum = z[0]*z[0];
    for(int i =1; i<_n; i++){
        sum += pow(10,6)*z[i]*z[i];
    }
    return sum + _fopt;
}

double Blackbox::p13(std::vector<double> x){
    std::vector<double> z = LinearApplication(_Q,vectorProduct(Lambda(),LinearApplication(_R, vectorSum(x, ExternalProduct(-1.0,_xopt)))));
    double sum = 0.0;
    for(int i =1; i<_n; i++){
        sum += z[i]*z[i];
    }
    return z[0]*z[0]+ 100*sqrt(sum) + _fopt;
}

double Blackbox::p14(std::vector<double> x){
    double sum = 0;
    std::vector<double> z = LinearApplication(_R,vectorSum(x,ExternalProduct(-1.0,_xopt))); //z = R(x-xopt)
    for (int i =0 ; i<_n; i++){
        sum = sum + pow(abs(z[i]),2+4*double(i-1)/double(_n-1));
    }
    return sqrt(sum);
}

double Blackbox::p15(std::vector<double> x){
    std::vector<double> z = LinearApplication(_R, vectorSum(x, ExternalProduct(-1.0,_xopt)));
    z = Tosz(z);
    z = Tasy(z);
    z = LinearApplication(_Q,z);
    z = vectorProduct(Lambda(), z);
    z = LinearApplication(_R, z);
    double sum = 0;
    for(int i = 0; i<_n; i++){
        sum += cos(2*M_PI*z[i]);
    }
    return 10*(_n-sum) + pow(Norm(z),2) + _fopt;
}

double Blackbox::p16(std::vector<double> x){
    std::vector<double> z = LinearApplication(_R, vectorSum(x, ExternalProduct(-1.0,_xopt)));
    z = Tosz(z);
    z = LinearApplication(_Q,z);
    z = vectorProduct(Lambda(), z);
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
    return 10*pow(1.0/double(_n)*(sum -f0),2) + 10.0/double(_n) * Fpen(x) + _fopt ; //it should be a cube power but with a square it ensures that all problems are bounded below by 0 
}

double Blackbox::p17(std::vector<double> x){ // Only the value for Lambda is changing between p17 and p18
    
    std::vector<double> z = vectorProduct(Lambda(),LinearApplication(_Q,Tasy(LinearApplication(_R,vectorSum(x,ExternalProduct(-1.0,_xopt)))))); //Lambda*Q*Tasy(R*(x-xopt))
    double sum = 0;
    double si = 0;
    
    for(int i=0; i<_n-1; i++){
        si = sqrt(z[i]*z[i]+z[i+1]*z[i+1]);
        sum += sqrt(si)*(1+pow(sin(50*pow(si,0.2)),2));
    }
    sum = pow(1/float(_n-1)*sum,2) + 10*Fpen(x) + _fopt;
    return sum;
}

double Blackbox::p19(std::vector<double> x){
    std::vector<double> z = LinearApplication(_R,x);
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

double Blackbox::p20(std::vector<double> x){
    std::vector<double> hatx = ExternalProduct(2.0,vectorProduct(_ones, x));
    std::vector<double> hatz(_n,0.0);
    hatz[0] = hatx[1];
    for(int i = 1; i<_n; i++){
        hatz[i]=hatx[i] +0.25*(hatx[i-1]-2*abs(_xopt[i-1]));
    }
    std::vector<double> absxopt = _xopt; // TODO : set up xopt in constructor
    for( int i = 0; i<_n;i++){
        if (absxopt[i]<0.0)
            absxopt[i] = -absxopt[i];
    } 
    std::vector<double> z = vectorProduct(Lambda(), vectorSum(hatz,ExternalProduct(2.0, absxopt)));
    z = vectorSum(z, ExternalProduct(2.0, absxopt));
    z = ExternalProduct(100.0,z);
    double sum = 0.0;
    for(int i = 0;i<_n; i++){
        sum += z[i]*sin(sqrt(abs(z[i])));
    }
    return (-1.0/(100.0*double(_n)))*sum + 4.189828872724339 + 100*Fpen(ExternalProduct(1.0/100.0,z)) +_fopt;
}

double Blackbox::p21(std::vector<double> x){ //only the fixed values are changing between 21 and 22
    // all the values of y, c, and alpha must be set in the constructor otherwise they will be set at each evaluation 
    double val=0.0, expo;
    std::vector<double> quad(_n,0.0),diff(_n,0.0);
    for(int i = 0; i< _hi; i++){
        diff = LinearApplication(_R,vectorSum(x,Y[i]));
        quad = vectorProduct(C[i],diff);  // the minus sign is already in the std::vector y
        expo = w[i]*exp(-ScalarProduct(diff,quad)/(2*double(_n)));
        if (expo>val)
            val=expo;
    }
    val=10.0-val;
    std::vector<double> obj(1,val);
    obj = Tosz(obj);
    return pow(obj[0],2)+Fpen(x)+_fopt;
}
double Blackbox::p23(std::vector<double> x){
    std::vector<double> z = LinearApplication(_R, vectorSum(x, ExternalProduct(-1.0,_xopt)));
    z = vectorProduct(Lambda(), z);
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
double Blackbox::p24(std::vector<double> x){
    // TODO : set up xopt in constructor
    std::vector<double> sign(_n,0.0);
    for(int i = 0; i<_n; i++){
        if (_xopt[i]<0)
            sign[i] = -1.0;
        if (_xopt[i]>0)
            sign[i] = 1.0;
    }
    std::vector<double> hatx = vectorProduct(ExternalProduct(2.0,sign),x);
    std::vector<double> unit(_n, -2.5);
    std::vector<double> z = LinearApplication(_R, vectorSum(hatx, unit));
    z = vectorProduct(Lambda(), z);
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


double Blackbox::blackbox(std::vector<double> x) { //raw computation
    switch (funcNum)
    {
    case 1:
        return p1(x);
        break;
    case 2:
        return p2(x);
        break;
    case 3:
        return p3(x);
        break;
    case 4:
        return p4(x);
        break;
    case 5:
        return p5(x);
        break;
    case 6:
        return p6(x);
        break;
    case 7:
        return p7(x);
        break;
    case 8:
        return p8(x);
        break;
    case 9:
        return p9(x);
        break;
    case 10:
        return p10(x);
        break;
    case 11:
        return p11(x);
        break;
    case 12:
        return p12(x);
        break;
    case 13:
        return p13(x);
        break;
    case 14:
        return p14(x);
        break;
    case 15:
        return p15(x);
        break;
    case 16:
        return p16(x);
        break;
    case 17:
        return p17(x); 
        break;
    case 18:
        return p17(x);//only the constant values set in the constructor are changing
        break;
    case 19:
        return p19(x);
        break;
    case 20:
        return p20(x);
        break;
    case 21:
        return p21(x);
        break;
    case 22:
        return p21(x); //only the constant values set in the constructor are changing
        break;
    case 23:
        return p23(x);
        break;
    case 24:
        return p24(x);
        break;

    default:
        std::cout<<"problem no "<< funcNum <<"not yet implemented.\n";
        return -1.0;
        break;
    }

}
