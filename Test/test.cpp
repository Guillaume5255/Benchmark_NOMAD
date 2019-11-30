//#include "matrice.hpp"
//#include "suite.hpp"
//#include "imageGeneration.hpp"
#include "blackbox.hpp"
//#include <ctime>
//#include <chrono>

//using namespace std;

/*


// #############################fractales parallelisees ###################################
void fractale(const double centerx, 
                const double centery, 
                const double xsize, 
                const double ysize, 
                const size_t xres, 
                const size_t yres, 
                const int itermax){
    unsigned char image[yres][xres][bytesPerPixel];

    double cx = centerx - xsize/2;
    double cy = centery - ysize/2;

    const double xstep = xsize/xres;
    const double ystep = ysize/yres;
    
    Suite* s;
    double a, b, c;
   
    chrono::steady_clock sc;   // create an object of `steady_clock` class
    auto start = sc.now();

    for(size_t j = 0; j< xres ; j++ ){
        for(size_t i = 0 ; i<yres ; i++){

            s = new Suite(cx,cy,itermax); //we compute the sequence with starting point (cx,cy)
            
            a=(s->GetIteration()/itermax); // we get the interesting value
            //b=a;
            //c=a;
            
            //a=a/255;
            b=s->Gety();
            b=b/2;
            c=s->Getx();
            c=c/2;
                             //we build the pixel
            image[i][j][2] = (unsigned char)(a*255); ///red
            image[i][j][1] = (unsigned char)(b*255); ///green
            image[i][j][0] = (unsigned char)(c*255); ///blue

            cy += ystep;
        }
        cy = centery - ysize/2;
        cx += xstep;
    }
    auto end = sc.now();       // end timer (starting & ending is done by measuring the time at the moment the process started & ended respectively)
    auto time_span = static_cast<chrono::duration<double>>(end - start);   // measure time span between start & end
    
    string imageFileName = "Fractale.bmp";
    generateBitmapImage((unsigned char *)image, yres, xres, imageFileName.c_str());

    std::cout<<"Image generated in "<<time_span.count()<<" seconds "<<"frame size : "<< xsize<<std::endl;
}

int main(){
    double xsize = 8;
    double ysize = 8;
    int zoomMax = 48;

    const double centerx = -1.70;  
    const double centery = 0.0; 
    
    const size_t xres = 1600;
    const size_t yres = 1600;

    const int iter = 200;
    for (int i = 1;i<zoomMax; i++){
        fractale(centerx, centery, xsize, ysize, xres, yres, iter);
        xsize = xsize/(1+0.05*i);
        ysize=xsize;
    }
    return 0;
}

*/

int main(){
    Blackbox bb(2, 17);
    vector<double> x(3,0);
    cout<<"OK\n"<<bb.f(x)<<"\n";
    

    return 0;
}

























// ############################# Produit matriciel ################################
/*void Product( Matrice &A,  Matrice &B, Matrice &M ) // computes the product AB
{
    size_t nbRowA = A.getHauteur();
    size_t nbColA = A.getLargeur();

    size_t nbRowB = B.getHauteur();
    size_t nbColB = B.getLargeur();

    size_t nbRowM = M.getHauteur();
    size_t nbColM = M.getLargeur();

    if (nbColA == nbRowB && nbRowM == nbRowA && nbColM == nbColB)
    {
        double v = 0.0;
        for(size_t i = 0 ; i < nbRowA ; i++)
        {
            for (size_t j = 0 ; j < nbColB ; j++)
            {
                for( size_t k = 0 ; k < nbColA ; k++ )
                {
                    v =  v + A.GetValeur(i,k)*B.GetValeur(k,j);
                }
                M.SetValeur(i,j,v);
                v = 0.0;
            }
        }
        
    }
    else{
        cout<< " Erreur : Le nombre de colonne de A est different du nombre de ligne de B \n On renvoie la matrice vide de taille 0,0"<< endl;
    }
}

int test() {
    size_t n = 3;
    size_t m = 5;
    size_t p = 3;
    
    
    Matrice<int> A(n,m);
    Matrice<int> B(m,p);
    for (size_t i = 0; i < n; i++)
    {
        for (size_t j = 0; j < m; j++)
        {
            if (i==j) {A.SetValeur(i,j,-1.0);}
        }
        
    }
    for (size_t i = 0; i < m; i++)
    {
        for (size_t j = 0; j < p; j++)
        {
            if (i>=j) {B.SetValeur(i,j,i+j+1);}
        }
        
    }
    Matrice<int> M(n,p);

    A.printMatrice();
    B.printMatrice();


    //Product(A,B,M);
    M.printMatrice();


    //SquareMatrice D(3);
    //D.printMatrice();

    return 0;
}
*/




//void generateBitmapImage(unsigned char *image, int height, int width, char* imageFileName);
//unsigned char* createBitmapFileHeader(int height, int width, int paddingSize);
//unsigned char* createBitmapInfoHeader(int height, int width);

/*
void ImageGenerator(Matrice<Matrice<double>> M, int height, int width){
    unsigned char image[height][width][bytesPerPixel];
    string imageFileName = "bitmapImage.bmp";
    double a, b, c;
    if (M.GetHauteur()==1 && M.GetLargeur()==3){
        for(int i=0; i<height; i++){
            for(int j=0; j<width; j++){
                s = M.GetValeur(j,i);
                a=s->GetIteration();
                a=a/255;
                b=s->Getx();
                b=b/2;
                c=s->Gety();
                c=c/2;
                image[i][j][2] = (unsigned char)(a*255); ///red
                image[i][j][1] = (unsigned char)(b*255); ///green
                image[i][j][0] = (unsigned char)(c*255); ///blue
            }
        }
        generateBitmapImage((unsigned char *)image, height, width, imageFileName.c_str());
        std::cout<<"Image generated!!"<<std::endl;
    }
    else
        std::cout<<"Something went wrong ! check the size of the matrices"<<std::endl;
    
}
*/