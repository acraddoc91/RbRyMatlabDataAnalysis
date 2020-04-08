#include "mex.h"
#include <omp.h>

void mexFunction(int nlhs, mxArray* plhs[], int nrgs, const mxArray* prhs[]) {
	//Our channel arrays
	unsigned long int *channel1bins, *channel2bins, *channel3bins;
	unsigned short int *posSteps, *negSteps;
	int *pulseBinSpacing;
	//Grab data from Matlab
	channel1bins = (unsigned long int *)mxGetData(prhs[0]);
	channel2bins = (unsigned long int *)mxGetData(prhs[1]);
	channel3bins = (unsigned long int *)mxGetData(prhs[2]);
	posSteps = (unsigned short int *)mxGetData(prhs[3]);
	negSteps = (unsigned short int *)mxGetData(prhs[4]);
	pulseBinSpacing = (int*)mxGetData(prhs[5]);
	//Get number of elements
	mwSize numElements1 = mxGetNumberOfElements(prhs[0]);
	mwSize numElements2 = mxGetNumberOfElements(prhs[1]);
	mwSize numElements3 = mxGetNumberOfElements(prhs[2]);
	//Variable to hold our denominator
	plhs[0] = mxCreateNumericMatrix(*posSteps + *negSteps + 1, *posSteps + *negSteps + 1, mxINT32_CLASS, mxREAL);
	unsigned long int* numer = (unsigned long int*) mxGetData(plhs[0]);
	int t1;
	//Loop over all tau steps
	#pragma omp parallel for
	for (t1 = -*negSteps; t1 <= *posSteps; t1++) {
		for (int t2 = -*negSteps; t2 <= *posSteps; t2++) {
			//Keep a running total of the coincidence counts
			unsigned long int runningTot = 0;
			for (int T1 = -2; T1 <= 2; T1++) {
				for (int T2 = -2; T2 <= 2; T2++) {
					if ((T1 != T2) & (T1 != 0) & (T2 != 0)) {
						mwSize i = 0;
						mwSize j = 0;
						mwSize k = 0;
						//Loop until we hit the end of one of our vectors
						while ((i < numElements1) & (j < numElements2) & (k < numElements3)) {
							//Check if the bin shift will cause an undeflow and increment till it does not
							if ((t1 + T1*(*pulseBinSpacing) > channel2bins[j]) & (t1 + T1*(*pulseBinSpacing) > 0)) {
								j++;
							}
							else if ((t2 + T2*(*pulseBinSpacing) > channel3bins[k]) & (t2 + T2*(*pulseBinSpacing)  > 0)) {
								k++;
							}
							else {
								//Check if we have a coincidence
								if ((channel1bins[i] == (channel2bins[j] - t1 - T1*(*pulseBinSpacing))) & (channel1bins[i] == (channel3bins[k] - t2 - T2*(*pulseBinSpacing)))) {
									runningTot++;
									i++;
									j++;
									k++;
								}
								//Else try and figure out which vector is lagging and increment its pointer
								//First check if channel 1 is smaller (or equal) than channel 2
								// c1 <= c2
								else if (channel1bins[i] <= (channel2bins[j] - t1 - T1*(*pulseBinSpacing))) {
									//Then check if channel 1 is the smallest
									// c1 <= c2 & c1 < c3
									if (channel1bins[i] < (channel3bins[k] - t2 - T2*(*pulseBinSpacing))) {
										i++;
									}
									//Channel 3 is smallest
									// c3 < c1 <= c2
									else if (channel1bins[i] > (channel3bins[k] - t2 - T2*(*pulseBinSpacing))) {
										k++;
									}
									// Remember if c1 = c2 = c3 code doesn't reach here so we don't worry about the possibility that c1 = c2
									// c1 = c3 < c2
									else if (channel1bins[i] == (channel3bins[k] - t2 - T2*(*pulseBinSpacing))) {
										i++;
										k++;
									}
								}
								// c2 < c1
								else {
									//Channel 2 is smallest
									// c2 < c1, c3
									if ((channel2bins[j] - t1 - T1*(*pulseBinSpacing)) < (channel3bins[k] - t2 - T2*(*pulseBinSpacing))) {
										j++;
									}
									//Channel 3 is smallest
									// c3 < c2 < c1
									else if ((channel2bins[j] - t1 - T1*(*pulseBinSpacing)) > (channel3bins[k] - t2 - T2*(*pulseBinSpacing))) {
										k++;
									}
									//Channel 2 and Channel 3 are equal
									// c2 = c3 < c1
									else if ((channel2bins[j] - t1 - T1*(*pulseBinSpacing)) == (channel3bins[k] - t2 - T2*(*pulseBinSpacing))) {
										j++;
										k++;
									}
								}
							}
						}
					}
				}
			}
			numer[t1 + *negSteps + (t2 + *negSteps)*(*posSteps + *negSteps + 1)] = runningTot;
		}
	}
}