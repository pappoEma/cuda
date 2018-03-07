#include <stdio.h>
#include <iostream>
#include <vector>

__global__
void sinogram(int *n, double **x, double **y, double **phi, double **sign,double **rsino,int j)
{
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  //  int j = blockIdx.y*blockDim.y + threadIdx.y;

  //  if(j<m && i<n[j]){
  if(i<n[j]){
 rsino[j][i]=-sqrt(x[j][i]*x[j][i]+y[j][i]*y[j][i])*sign[j][i];

  }

//blockIdx variabile di tipo dim3, contiene l'indice del blocco
//threadIdx variabile di tipo dim3, contiene l'indice del thread
}

int main(void ) {


   const int nslice=1;
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

  std::vector<double> hx[nslice];
  std::vector<double> hy[nslice];
  std::vector<double> hz[nslice];
  std::vector<double> hphi[nslice];
  std::vector<double> hsign[nslice];


   int idxslice[nslice];

  for(int j=0;j<nslice;j++){
  idxslice[j]=0;
  
  hx[j].reserve(5);
  hy[j].reserve(5);
  hz[j].reserve(5);
  hphi[j].reserve(5);	
  hsign[j].reserve(5);

 
}
const int Nmaxcoinc=10;

  double ene1[Nmaxcoinc],ene2[Nmaxcoinc],deltat[Nmaxcoinc],x[Nmaxcoinc],y[Nmaxcoinc],z[Nmaxcoinc],sign[Nmaxcoinc],xhit1[Nmaxcoinc],yhit1[Nmaxcoinc],zhit1[Nmaxcoinc],xhit2[Nmaxcoinc],yhit2[Nmaxcoinc],\
zhit2[Nmaxcoinc],phi[Nmaxcoinc],theta[Nmaxcoinc];

   int pad1[Nmaxcoinc],pad2[Nmaxcoinc],cell1[Nmaxcoinc],cell2[Nmaxcoinc],chip1[Nmaxcoinc],chip2[Nmaxcoinc],pix1[Nmaxcoinc],pix2[Nmaxcoinc],samecell1[Nmaxcoinc],sharedcharge1[Nmaxcoinc],samecell2[Nmax\
coinc],sharedcharge2[Nmaxcoinc],gammaID1[Nmaxcoinc],triggered,NEntries;


FILE *filein=std::fopen("./binary_10000_12000_0.bin","r");

std::fread(&NEntries,4,1,filein);

for(int i=0;i<10;i++){
 //std::cout<<NEntries<<std::endl;
  if(i%1000==0)std::cout<<i<<std::endl;
  
  std::fread(&(int&)triggered,4,1,filein);
  
  //std::cout<<triggered<<std::endl;
  
  for(int k=0;k<triggered;k++){
    
    
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
    
    
    for(int j=0;j<nslice;j++){
      
      if(z[k]>zmin+j*voxelsizez && z[k]<zmin+(j+1)*voxelsizez){
	
	hz[j].push_back(z[k]);
	hy[j].push_back(y[k]);
	hx[j].push_back(x[k]);
	hphi[j].push_back(phi[k]);	
	hsign[j].push_back(sign[k]);
	idxslice[j]++;
	
      }
      
    }
  }
 }
 
//end of data sorting




 //copy to device	
 
 double *dx[nslice],*dy[nslice],*dz[nslice],*dphi[nslice],*dsign[nslice],*drsino[nslice];//device arrays
 double *hdx[nslice],*hdy[nslice],*hdz[nslice],*hdphi[nslice],*hdsign[nslice],*hdrsino[nslice],*hdx1[nslice];//host arrays for vector dynamic allocation
 
 for(int j=0;j<nslice;j++){


   hdx[j]=(double*)malloc(idxslice[j]*sizeof(double));
   hdx1[j]=(double*)malloc(idxslice[j]*sizeof(double));
   hdy[j]=(double*)malloc(idxslice[j]*sizeof(double));
   hdz[j]=(double*)malloc(idxslice[j]*sizeof(double));
   hdsign[j]=(double*)malloc(idxslice[j]*sizeof(double));
   hdphi[j]=(double*)malloc(idxslice[j]*sizeof(double));
   hdrsino[j]=(double*)malloc(idxslice[j]*sizeof(double));
   
   for(int k=0;k<idxslice[j];k++){
     
     hdx[j][k]=j+k;//hx[j][k];
     hdy[j][k]=hy[j][k];
     hdz[j][k]=hz[j][k];
     hdsign[j][k]=hx[j][k];
     hdphi[j][k]=hx[j][k];

   }
   
   //allocating memory on device
   cudaMalloc(&dx[j],idxslice[j]*sizeof(double));
   cudaMalloc(&dy[j],idxslice[j]*sizeof(double));
   cudaMalloc(&dz[j],idxslice[j]*sizeof(double));
   cudaMalloc(&dphi[j],idxslice[j]*sizeof(double));
   cudaMalloc(&dsign[j],idxslice[j]*sizeof(double));
   cudaMalloc(&drsino[j],idxslice[j]*sizeof(double));  


   //copying to device
   cudaMemcpy(dx[j],hdx[j], idxslice[j]*sizeof(double), cudaMemcpyHostToDevice);
   cudaMemcpy(dy[j],hdy[j], idxslice[j]*sizeof(double), cudaMemcpyHostToDevice);
   cudaMemcpy(dz[j], hdz[j], idxslice[j]*sizeof(double), cudaMemcpyHostToDevice);
   cudaMemcpy(dphi[j],hdphi[j], idxslice[j]*sizeof(double), cudaMemcpyHostToDevice);
   cudaMemcpy(dsign[j],hdsign[j], idxslice[j]*sizeof(double), cudaMemcpyHostToDevice);
  
 }

 // for(int j=0;j<nslice;j++) sinogram<<<1,idxslice[j]>>>(idxslice,dx,dy,dphi,dsign,drsino,j);

  for(int j=0;j<nslice;j++){
    cudaMemcpy(hdx1[j],dx[j], idxslice[j]*sizeof(double), cudaMemcpyDeviceToHost);
    //  cudaMemcpy(hdrsino[j],drsino[j], idxslice[j]*sizeof(double), cudaMemcpyDeviceToHost);
  }
  for(int j=0;j<nslice;j++){
    for(int k=0;k<idxslice[j];k++){
      // std::cout<<"mortaccitua "<<hdrsino[j][k] <<" "<<hdx1[j][k]<<" "<<hy[j][k]<<std::endl;
       std::cout<<"mortaccitua "<<hdx1[j][k]<<" "<<hdx[j][k]<<std::endl;
    }
  }
 
 for(int j=0;j<nslice;j++){
   cudaFree(dx[j]);
   cudaFree(dy[j]);
   cudaFree(dz[j]);
   cudaFree(dsign[j]);
   cudaFree(dphi[j]);
   cudaFree(drsino[j]);
   free(hdrsino[j]);
   free(hdx[j]);
   free(hdx1[j]);
   free(hdy[j]);
   free(hdz[j]);
   free(hdphi[j]);
   free(hdsign[j]);
   hx[j].clear();
   hy[j].clear();
   hz[j].clear();
   hphi[j].clear();
   hsign[j].clear();
   
 }
 
}		
