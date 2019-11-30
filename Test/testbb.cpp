#include "blackbox.hpp"

int main(){
    int n = 5, seed;
    vector<double> x(n,3.0);
    cout<< "enter seed\n";    
    cin>> seed; 
    Blackbox* bb;

    for(int i = 1; i< 25; i++){

        bb = new Blackbox(n, i, seed);

        double f=bb->f(x);
        double g=bb->f(x) ;

        cout<<"valeur de f"<< i <<" : \t"<<f<<" | "<<g<<"\n";
    }
    return 0;
}


