#include "mex.h"

unsigned short int calculateStep(unsigned short int *channel1hist, unsigned short int *channel2hist, int stopFromZero, mwSize numElements) {
	unsigned short int numer = 0;
	if (stopFromZero == 0) {
		for (mwSize i = 0; i < numElements; i++) {
			numer += channel1hist[i] & channel2hist[i];
		}
	}
	else if(stopFromZero < 0) {
		for (mwSize i = 0; i < numElements+stopFromZero; i++) {
			numer += channel1hist[i-stopFromZero] & channel2hist[i];
		}
	}
	else if (stopFromZero > 0) {
		for (mwSize i = 0; i < numElements - stopFromZero; i++) {
			numer += channel1hist[i] & channel2hist[i+stopFromZero];
		}
	}
	return numer;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrgs, const mxArray* prhs[]) {
	//Our channel arrays
	unsigned short int *channel1hist, *channel2hist, *posSteps, *negSteps;
	//Grab data from Matlab
	channel1hist = (unsigned short int *)mxGetData(prhs[0]);
	channel2hist = (unsigned short int *)mxGetData(prhs[1]);
	posSteps = (unsigned short int *)mxGetData(prhs[2]);
	negSteps = (unsigned short int *)mxGetData(prhs[3]);
	//Get number of elements
	mwSize numElements1 = mxGetNumberOfElements(prhs[0]);
	mwSize numElements2 = mxGetNumberOfElements(prhs[1]);
	//Variable to hold our denominator
	plhs[0] = mxCreateNumericMatrix(1, *posSteps + *negSteps + 1, mxINT16_CLASS, mxREAL);
	unsigned short int* numer = (unsigned short int*) mxGetData(plhs[0]);
	if (numElements1 == numElements2) {
		mwSize i;
		for (i = 0; i < *posSteps + *negSteps + 1; i++) {
			numer[i] = calculateStep(channel1hist,channel2hist,i-*negSteps,numElements1);
		}
	}
	else {
		mexPrintf("Two vectors need to be the same length\n");
	}
	return;
}