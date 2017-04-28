#include "mex.h"

void mexFunction(int nlhs, mxArray* plhs[], int nrgs, const mxArray* prhs[]) {
	//Our channel arrays
	unsigned long int *channeltags, *startTags, *endTags;
	//Grab data from Matlab
	channeltags = (unsigned long int *)mxGetData(prhs[0]);
	startTags = (unsigned long int *)mxGetData(prhs[1]);
	endTags = (unsigned long int *)mxGetData(prhs[2]);
	//Get number of elements
	mwSize numTags = mxGetNumberOfElements(prhs[0]);
	mwSize numWindows = mxGetNumberOfElements(prhs[1]);
	mwSize numWindows2 = mxGetNumberOfElements(prhs[2]);
	//Create our output vector
	plhs[0] = mxCreateNumericMatrix(1, numTags, mxINT32_CLASS, mxREAL);
	unsigned long int* outTags = (unsigned long int*) mxGetData(plhs[0]);
	//Check if the start and end tag vectors are the same length
	if (numWindows == numWindows2) {
		//Dummy pointer
		int j = 0;
		//Loop over all tags
		for (int i = 0; i < numTags; i++) {
			//Dummy boolean
			bool valid = true;
			while (valid) {
				//Increment dummy pointer if channel tag is greater than current start tag
				if ((channeltags[i] >= startTags[j]) & (j < numWindows)) {
					j++;
				}
				//Make sure j is greater than 0, preventing an underflow error
				else if (j > 0){
					//Check if tag is lower than previous end tag i.e. startTags[j-1] < channeltags[i] < endTags[j-1]
					if (channeltags[i] <= endTags[j-1]) {
						outTags[i] = channeltags[i];
					}
					//If it doesn't lie in a window then just set its value to 0
					else {
						outTags[i] = 0;
					}
					//Break the valid loop
					valid = false;
				}
				// If tag is smaller than startTag[0]
				else {
					valid = false;
				}
			}
		}
	}
}