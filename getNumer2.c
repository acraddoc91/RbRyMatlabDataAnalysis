#include "mex.h"

void mexFunction(int nlhs, mxArray* plhs[], int nrgs, const mxArray* prhs[]) {
	//Our channel arrays
	unsigned long int *channel1bins, *channel2bins;
	unsigned short int *posSteps, *negSteps;
	//Grab data from Matlab
	channel1bins = (unsigned long int *)mxGetData(prhs[0]);
	channel2bins = (unsigned long int *)mxGetData(prhs[1]);
	posSteps = (unsigned short int *)mxGetData(prhs[2]);
	negSteps = (unsigned short int *)mxGetData(prhs[3]);
	//Get number of elements
	mwSize numElements1 = mxGetNumberOfElements(prhs[0]);
	mwSize numElements2 = mxGetNumberOfElements(prhs[1]);
	//Variable to hold our denominator
	plhs[0] = mxCreateNumericMatrix(1, *posSteps + *negSteps + 1, mxINT16_CLASS, mxREAL);
	unsigned short int* numer = (unsigned short int*) mxGetData(plhs[0]);
	//Loop over all tau steps
	for (int k = -*negSteps; k <= *posSteps; k++) {
		//Keep a running total of the coincidence counts
		int runningTot = 0;
		mwSize i = 0;
		mwSize j = 0;
		//Loop until we hit the end of one of our vectors
		while ((i < numElements1) & (j < numElements2)) {
			//Check if the bin shift will cause an undeflow and increment till it does not
			if ((k > channel2bins[j]) & (k > 0)) {
				j++;
			}
			else {
				//Abuse the fact that each vector is chronologically ordered to help find common elements quickly
				if (channel1bins[i] > (channel2bins[j] - k)) {
					j++;
				}
				else if (channel1bins[i] < (channel2bins[j] - k)) {
					i++;
				}
				//If there is a common elements increment coincidence counts
				else if (channel1bins[i] == (channel2bins[j] - k)) {
					i++;
					j++;
					runningTot++;
				}
			}
		}
		numer[k+*negSteps] = runningTot;
	}
}