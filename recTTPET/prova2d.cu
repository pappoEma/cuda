#include <stdio.h>
#include <iostream>
#include <vector>

__global__
void sum(int n, double *x, double *y, double *z)
{
  
 
  int i = blockIdx.x*blockDim.x + threadIdx.x;

  if(i<n){
    z[i]=x[i]+y[i];
    printf("check from function i= %d %f + %f = %f\n",i,x[i],y[i],z[i]);
  }
  //blockIdx variabile di tipo dim3, contiene l'indice del blocco
  //threadIdx variabile di tipo dim3, contiene l'indice del thread
}




int main(void ) {

  const int Nfix=10;//fixed dimension
  double *a[Nfix],*b[Nfix],*c[Nfix]; //for the host
  double *da[Nfix],*db[Nfix],*dc[Nfix]; //for the device

    
  int Nvar[Nfix]; //dynamic dimension
  
  //then I allocate the memory
  
  for(int i=0;i<Nfix;i++){

    Nvar[i]=3*(i+1);
    
    a[i]=(double*)malloc(Nvar[i]*sizeof(double));
    b[i]=(double*)malloc(Nvar[i]*sizeof(double));
    c[i]=(double*)malloc(Nvar[i]*sizeof(double));
    
  

    for(int k=0;k<Nvar[i];k++){
      a[i][k]=k+(i+1);
      b[i][k]=k+2*(i+1);
    } 
    
    //and for the device
    cudaMalloc(&da[i],Nvar[i]*sizeof(double));
    cudaMalloc(&db[i],Nvar[i]*sizeof(double));
    cudaMalloc(&dc[i],Nvar[i]*sizeof(double));
    
    //the I copy the memory 
    
    cudaMemcpy(da[i],a[i],Nvar[i]*sizeof(double),cudaMemcpyHostToDevice);
    cudaMemcpy(db[i],b[i],Nvar[i]*sizeof(double),cudaMemcpyHostToDevice);

    sum<<<1,Nvar[i]>>>(Nvar[i],da[i],db[i],dc[i]);
    cudaMemcpy(c[i],dc[i],Nvar[i]*sizeof(double),cudaMemcpyDeviceToHost);

    for(int k=0;k<Nvar[i];k++)std::cout<<"i= "<<k<<" "<<a[i][k]<<" + "<<b[i][k]<<" = "<<c[i][k]<<std::endl;

    cudaFree(da[i]);
    cudaFree(db[i]);
    cudaFree(dc[i]);
    free(a[i]);
    free(b[i]);
    free(c[i]);

    
  }
  
}


