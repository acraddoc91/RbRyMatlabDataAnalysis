#include "mex.h"

void mexFunction(int nlhs, mxArray* plhs[], int nrgs, const mxArray* prhs[]) {
	//Our channel arrays
	unsigned long int *channel1bins, *channel2bins, *channel3bins;
	unsigned short int *posSteps, *negSteps;
	//Grab data from Matlab
	channel1bins = (unsigned long int *)mxGetData(prhs[0]);
	channel2bins = (unsigned long int *)mxGetData(prhs[1]);
	channel3bins = (unsigned long int *)mxGetData(prhs[2]);
	posSteps = (unsigned short int *)mxGetData(prhs[3]);
	negSteps = (unsigned short int *)mxGetData(prhs[4]);
	//Get number of elements
	mwSize numElements1 = mxGetNumberOfElements(prhs[0]);
	mwSize numElements2 = mxGetNumberOfElements(prhs[1]);
	mwSize numElements3 = mxGetNumberOfElements(prhs[2]);
	//Variable to hold our denominator
	plhs[0] = mxCreateNumericMatrix(*posSteps + *negSteps + 1, *posSteps + *negSteps + 1, mxINT16_CLASS, mxREAL);
	unsigned short int* numer = (unsigned short int*) mxGetData(plhs[0]);
	//Loop over all tau steps
	for (int t1 = -*negSteps; t1 <= *posSteps; t1++) {
		for (int t2 = -*negSteps; t2 <= *posSteps; t2++) {
			//Keep a running total of the coincidence counts
			int runningTot = 0;
			mwSize i = 0;
			mwSize j = 0;
			mwSize k = 0;
			//Loop until we hit the end of one of our vectors
			while ((i < numElements1) & (j < numElements2) & (k < numElements3)) {
				//Check if the bin shift will cause an undeflow and increment till it does not
				if ((t1 > channel2bins[j]) & (t1 > 0)) {
					j++;
				}
				else if ((t2 > channel3bins[k]) & (t2 > 0)) {
					k++;
				}
				else {
					//Check if we have a coincidence
					if ((channel1bins[i] == (channel2bins[j] - t1)) & (channel1bins[i] == (channel3bins[k] - t2))) {
						runningTot++;
						i++;
						j++;
						k++;
					}
					//Else try and figure out which vector is lagging and increment its pointer
					//First check if channel 1 is smaller (or equal) than channel 2
					// c1 <= c2
					else if (channel1bins[i] <= (channel2bins[j] - t1)) {
						//Then check if channel 1 is the smallest
						// c1 <= c2 & c1 < c3
						if (channel1bins[i] < (channel3bins[k] - t2)) {
							i++;
						}
						//Channel 3 is smallest
						// c3 < c1 <= c2
						else if (channel1bins[i] > (channel3bins[k] - t2)) {
							k++;
						}
						// Remember if c1 = c2 = c3 code doesn't reach here so we don't worry about the possibility that c1 = c2
						// c1 = c3 < c2
						else if (channel1bins[i] == (channel3bins[k] - t2)) {
							i++;
							k++;
						}
					}
					// c2 < c1
					else {
						//Channel 2 is smallest
						// c2 < c1, c3
						if ((channel2bins[j] - t1) < (channel3bins[k] - t2)) {
							j++;
						}
						//Channel 3 is smallest
						// c3 < c2 < c1
						else if ((channel2bins[j] - t1) > (channel3bins[k] - t2)) {
							k++;
						}
						//Channel 2 and Channel 3 are equal
						// c2 = c3 < c1
						else if ((channel2bins[j] - t1) == (channel3bins[k] - t2)) {
							j++;
							k++;
						}
					}
				}
			}
			numer[t1 + *negSteps + (t2 + *negSteps)*(*posSteps + *negSteps + 1)] = runningTot;
		}
	}
}