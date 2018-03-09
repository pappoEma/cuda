#include <stdio.h>
#include <iostream>
#include <vector>
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <time.h>
#include <helper_cuda.h>
#include <helper_functions.h>


__global__
void reco3d(int n, double *r, double *s,double *phi,double *z)
{
  
  // printf("check %d\n",n);
  
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  
  if(i<n){
    
    //  printf("%f %f %f %f\n",r[i],s[i],phi[i],z[i]);

    double a=r[i]*cos(phi[i]);
   
  }
}

__global__
void copy(int *n,int *dummy,int nslice)
{
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  
  
  if(i<nslice){
    
    dummy[i]=n[i];
    printf("check %d %d\n",i,n[i]);
  }
  
  //blockIdx variabile di tipo dim3, contiene l'indice del blocco
  //threadIdx variabile di tipo dim3, contiene l'indice del thread
}

int main(void ) {
    
  time_t Start, Stop;
  
  const int nslice=100;
  int Nevents=1000000;
  double xmin=-20;
  double xmax=20;
  double zmin=-25;
  double zmax=25;
  double ymin=-20;
  double ymax=20;
  double voxelsize=0.125;
  
  int Nvoxelz=nslice;
  double voxelsizez=(zmax-zmin)/Nvoxelz;
  int Nvoxel=(xmax-xmin)/voxelsize;//512;
  //double **hx=(double**)malloc(nslice*sizeof(double));
  
  
  thrust::host_vector<double> hs[nslice];
  thrust::host_vector<double> hr[nslice];
  thrust::host_vector<double> hz[nslice];
  thrust::host_vector<double> hphi[nslice];
  
  
  int idxslice[nslice];
  
  for(int j=0;j<nslice;j++){
    idxslice[j]=0;
    
    hr[j].reserve(5);
    hs[j].reserve(5);
    hz[j].reserve(5);
    hphi[j].reserve(5);	
 
    
  }
  const int Nmaxcoinc=10;
  
  double ene1[Nmaxcoinc],ene2[Nmaxcoinc],deltat[Nmaxcoinc],x[Nmaxcoinc],y[Nmaxcoinc],z[Nmaxcoinc],sign[Nmaxcoinc],xhit1[Nmaxcoinc],yhit1[Nmaxcoinc],zhit1[Nmaxcoinc],xhit2[Nmaxcoinc],yhit2[Nmaxcoinc],zhit2[Nmaxcoinc],phi[Nmaxcoinc],theta[Nmaxcoinc];
  
  int pad1[Nmaxcoinc],pad2[Nmaxcoinc],cell1[Nmaxcoinc],cell2[Nmaxcoinc],chip1[Nmaxcoinc],chip2[Nmaxcoinc],pix1[Nmaxcoinc],pix2[Nmaxcoinc],samecell1[Nmaxcoinc],sharedcharge1[Nmaxcoinc],samecell2[Nmaxcoinc],sharedcharge2[Nmaxcoinc],gammaID1[Nmaxcoinc],triggered,NEntries;
  
  
  FILE *filein=std::fopen("./binary_10000_11000_0.bin","r");
  
  std::fread(&NEntries,4,1,filein);
  
  for(int i=0;i<Nevents;i++){
    //std::cout<<NEntries<<std::endl;
    if(i%1000==0)std::cout<<i<<std::endl;
    
    std::fread(&(int&)triggered,4,1,filein);
    
    //std::cout<<triggered<<std::endl;
  
    for(int k=0;k<triggered;k++){
      
      std::fread(&(double&)xhit1[k],8,1,filein);
      std::fread(&(double&)xhit2[k],8,1,filein);
      std::fread(&(double&)yhit1[k],8,1,filein);
      std::fread(&(double&)yhit2[k],8,1,filein);
      std::fread(&(double&)ene1[k],8,1,filein);
      std::fread(&(double&)ene2[k],8,1,filein);
      std::fread(&(int&)cell1[k],4,1,filein);
      std::fread(&(int&)cell2[k],4,1,filein);
      std::fread(&(int&)pad1[k],4,1,filein);
      std::fread(&(int&)pad2[k],4,1,filein);
      std::fread(&(int&)chip1[k],4,1,filein);
      std::fread(&(int&)chip2[k],4,1,filein);
      std::fread(&(int&)pix1[k],4,1,filein);
      std::fread(&(int&)pix2[k],4,1,filein);
      std::fread(&(double&)deltat[k],8,1,filein);
      std::fread(&(double&)sign[k],8,1,filein); //for sinogram
      std::fread(&(double&)x[k],8,1,filein);
      std::fread(&(double&)y[k],8,1,filein);
      std::fread(&(double&)z[k],8,1,filein);
      std::fread(&(double&)phi[k],8,1,filein);
      std::fread(&(double&)theta[k],8,1,filein);
      double c=299.792458;//mm/ns
      
      for(int j=0;j<nslice;j++){
      
	if(z[k]>zmin+j*voxelsizez && z[k]<zmin+(j+1)*voxelsizez){

	  double s1=xhit1[k]*cos(phi[k])+yhit1[k]*sin(phi[k]);
	  double s2=xhit2[k]*cos(phi[k])+yhit2[k]*sin(phi[k]);
	  double sm=(s1+s2)/2.;
	  
	  double ssino=sm-(c*deltat[k]*0.5)*sin(theta[k]);
	  hz[j].push_back(z[k]);
	  hs[j].push_back(ssino);
	  hr[j].push_back(-sqrt(x[k]*x[k]+y[k]*y[k])*sign[k]);
	  hphi[j].push_back(phi[k]); 
	  idxslice[j]++;
	}
      }
    }
  }
  
  //end of data sorting
  
  
  
  //copy to device	
  
  
 thrust::device_vector<double> ds[nslice];
 thrust::device_vector<double> dr[nslice];
 thrust::device_vector<double> dz[nslice];
 thrust::device_vector<double> dphi[nslice];
 
 cudaEvent_t start;
 cudaEvent_t stop;
 checkCudaErrors(cudaEventCreate(&start));
 checkCudaErrors(cudaEventCreate(&stop));
 
 
 
 for(int j=0;j<nslice;j++){
   
   
   ds[j].reserve(idxslice[j]);
   dr[j].reserve(idxslice[j]);
   dz[j].reserve(idxslice[j]);
   dphi[j].reserve(idxslice[j]);	
   
   ds[j]=hs[j];
   dr[j]=hr[j];
   dz[j]=hz[j];
   dphi[j]=hphi[j];

   
 }
 
 checkCudaErrors(cudaEventRecord(start, NULL)); //start
 
 int Nthreads=1000;
 
 double *ps[nslice],*pr[nslice],*pz[nslice],*pphi[nslice];
 
 for(int j=0;j<nslice;j++){
   
   ps[j]=thrust::raw_pointer_cast(ds[j].data());
   pr[j]=thrust::raw_pointer_cast(dr[j].data());
   pz[j]=thrust::raw_pointer_cast(dz[j].data());
   pphi[j]=thrust::raw_pointer_cast(dphi[j].data());

   reco3d<<<(idxslice[j]+(Nthreads-1))/Nthreads,Nthreads>>>(idxslice[j],ps[j],pr[j],pphi[j],pz[j]);
   
   
 }

 
 
 checkCudaErrors(cudaEventRecord(stop, NULL));//stop
 checkCudaErrors(cudaEventSynchronize(stop));
 float msecTotal = 0.0f;
 checkCudaErrors(cudaEventElapsedTime(&msecTotal, start, stop));
 
 
 time(&Start);
 checkCudaErrors(cudaEventRecord(start, NULL)); //start

 for(int j=0;j<nslice;j++){

   for(int k=0;k<idxslice[j];k++)double a=hr[j][k]*cos(hphi[j][k]);

 }
   
   checkCudaErrors(cudaEventRecord(stop, NULL));//stop
   checkCudaErrors(cudaEventSynchronize(stop));
   float msecTotal1 = 0.0f;
 checkCudaErrors(cudaEventElapsedTime(&msecTotal1, start, stop));
 time(&Stop);
 printf("Processing time cpu: %d (sec)\n", Stop - Start);
 printf("Processing time cpu: %f (msec)\n", msecTotal1);
 printf("Processing time gpu: %f (msec)\n", msecTotal);

 for(int j=0;j<nslice;j++){
   hr[j].clear();
   hs[j].clear();
   hz[j].clear();
   hphi[j].clear();
   dr[j].clear();
   ds[j].clear();
   dz[j].clear();
   dphi[j].clear();
   }


}	       

