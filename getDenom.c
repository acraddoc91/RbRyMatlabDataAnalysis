#include "mex.h"

unsigned short int calculateStep(unsigned short int *channel1hist, unsigned short int *channel2hist, int distFromZero, mwSize numElements, int *pulseBinSpacing) {
	unsigned short int denom = 0;
	if (distFromZero == 0) {
		for (int k = -2; k <= 2; k++) {
			if (k < 0) {
				for (mwSize i = 0; i < numElements + k*(*pulseBinSpacing); i++) {
					denom += channel1hist[i - k*(*pulseBinSpacing)] & channel2hist[i];
				}
			}
			else if(k > 0){
				for (mwSize i = 0; i < numElements - k*(*pulseBinSpacing); i++) {
					denom += channel1hist[i] & channel2hist[i+k*(*pulseBinSpacing)];
				}
			}
		} 
	}
	else if (distFromZero < 0) {
		for (int k = -2; k <= 2; k++) {
			if (k < 0) {
				for (mwSize i = 0; i < numElements + k*(*pulseBinSpacing) + distFromZero; i++) {
					denom += channel1hist[i - k*(*pulseBinSpacing) - distFromZero] & channel2hist[i];
				}
			}
			else if (k > 0) {
				for (mwSize i = 0; i < numElements - k*(*pulseBinSpacing) - distFromZero; i++) {
					denom += channel1hist[i] & channel2hist[i + k*(*pulseBinSpacing) + distFromZero];
				}
			}
		}
	}
	else if (distFromZero > 0) {
		for (int k = -2; k <= 2; k++) {
			if (k < 0) {
				for (mwSize i = 0; i < numElements + k*(*pulseBinSpacing) + distFromZero; i++) {
					denom += channel1hist[i - k*(*pulseBinSpacing) - distFromZero] & channel2hist[i];
				}
			}
			else if (k > 0) {
				for (mwSize i = 0; i < numElements - k*(*pulseBinSpacing) - distFromZero; i++) {
					denom += channel1hist[i] & channel2hist[i + k*(*pulseBinSpacing) + distFromZero];
				}
			}
		}
	}
	return denom;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrgs, const mxArray* prhs[]){
	//Our channel arrays
	unsigned short int *channel1hist, *channel2hist, *posSteps, *negSteps;
	int *pulseBinSpacing;
	//Grab data from Matlab
	channel1hist = (unsigned short int *)mxGetData(prhs[0]);
	channel2hist = (unsigned short int *)mxGetData(prhs[1]);
	posSteps = (unsigned short int *)mxGetData(prhs[2]);
	negSteps = (unsigned short int *)mxGetData(prhs[3]); 
	pulseBinSpacing = (int*)mxGetData(prhs[4]);
	//Get number of elements
	mwSize numElements1 = mxGetNumberOfElements(prhs[0]);
	mwSize numElements2 = mxGetNumberOfElements(prhs[1]);
	//Variable to hold our denominator
	plhs[0] = mxCreateNumericMatrix(1, *posSteps+*negSteps+1, mxINT32_CLASS, mxREAL);
	unsigned long int* denom = (unsigned long int*) mxGetData(plhs[0]);
	if(numElements1 == numElements2){
		mwSize i;
		for (i = 0; i < *posSteps + *negSteps + 1; i++) {
			denom[i] = calculateStep(channel1hist, channel2hist, i - *negSteps, numElements1, pulseBinSpacing);
		}
	}
	else {
		mexPrintf("Two vectors need to be the same length\n");
	}
	return;
}