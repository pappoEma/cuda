#include <stdio.h>
#include <iostream>

__global__
void saxpy(int n, float a, float *x, float *y,float *sum)
{
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  if (i < n) sum[i] = a*x[i] + y[i];

//blockIdx variabile di tipo dim3, contiene l'indice del blocco
//threadIdx variabile di tipo dim3, contiene l'indice del thread
}



int main(void){

  float *hy,*hx,*dx,*dy,*hdsum,*sum;
  int N=100;
  hx=(float*)malloc(N*sizeof(float));
  hy=(float*)malloc(N*sizeof(float));
  hdsum=(float*)malloc(N*sizeof(float));
  cudaMalloc(&dx,N*sizeof(float));
  cudaMalloc(&dy,N*sizeof(float));
  cudaMalloc(&sum,N*sizeof(float));
  
  for(int k=0;k<N;k++){
    hx[k]=1.0f;
    hy[k]=2.0f;
  }
  cudaMemcpy(dx,hx, N*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(dy,hy, N*sizeof(float), cudaMemcpyHostToDevice);
  
 
  
  saxpy<<<1, N>>>(N, 1.0f,dx,dy,sum);
  
  cudaMemcpy(hdsum,sum, N*sizeof(float), cudaMemcpyDeviceToHost);
  
  for(int k=0;k<N;k++)std::cout<<hdsum[k]<<" "<<hy[k]<<std::endl;
}
