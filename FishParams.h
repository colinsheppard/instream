/*
inSTREAM Version 4.3, October 2006.
Individual-based stream trout modeling software. Developed and maintained by Steve Railsback (Lang, Railsback & Associates, Arcata, California) and
Steve Jackson (Jackson Scientific Computing, McKinleyville, California).
Development sponsored by EPRI, US EPA, USDA Forest Service, and others.
Copyright (C) 2004 Lang, Railsback & Associates.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see file LICENSE); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
*/


#import <defobj.h>

#import <objectbase/SwarmObject.h>
#import <objectbase.h>
#import <objectbase/ProbeMap.h>
#import <objectbase/CompleteProbeMap.h>
#import <string.h>



#undef LARGEINT
#define LARGEINT 2147483647

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif



@interface FishParams: SwarmObject
{

@private

char anInitString[3];
int* anInitInt;
double* anInitFloat;
double* anInitDouble;
id anInitId;
id <CompleteVarMap> probeMap;

char* parameterFileName;

int speciesIndex;

id <Symbol> fishSpecies;

char instanceName[50];

@public

// THE FOLLOWING VARIABLES ARE INITIALIZED BY THE
// FISH .Params FILE.
// ADD NEW CONSTANTS HERE.
// 
// CAUTION: If this file is modified in any way the user
//          MUST "make clean" and then remake the executable 
//

//BEGIN CONSTANTS INITIALIZED BY THE FISH .Params FILE


double fishMoveDistParamA;
double fishMoveDistParamB;

double fishCmaxParamA;
double fishCmaxParamB;
double fishCmaxTempF1;
double fishCmaxTempF2;
double fishCmaxTempF3;
double fishCmaxTempF4;
double fishCmaxTempF5;
double fishCmaxTempF6;
double fishCmaxTempF7;
double fishCmaxTempT1;
double fishCmaxTempT2;
double fishCmaxTempT3;
double fishCmaxTempT4;
double fishCmaxTempT5;
double fishCmaxTempT6;
double fishCmaxTempT7;
double fishEnergyDensity;
double fishFecundParamA;
double fishFecundParamB;
double fishFitnessHorizon;

//
// fishMinFeedTemp deleted 10/13/06 SKJ
//


double fishRespParamA;
double fishRespParamB;
double fishRespParamC;
double fishRespParamD;
double fishSearchArea;
double fishSpawnEggViability;
int   fishSpawnMinAge;
double fishSpawnDSuitD1;
double fishSpawnDSuitD2;
double fishSpawnDSuitD3;
double fishSpawnDSuitD4;
double fishSpawnDSuitD5;
double fishSpawnDSuitS1;
double fishSpawnDSuitS2;
double fishSpawnDSuitS3;
double fishSpawnDSuitS4;
double fishSpawnDSuitS5;
char* fishSpawnEndDate;
double fishSpawnMaxFlowChange;
double fishSpawnMaxTemp;
double fishSpawnMinCond;
double fishSpawnMinLength;
double fishSpawnMinTemp;
double fishSpawnProb;
char* fishSpawnStartDate;
double fishSpawnVSuitS1;
double fishSpawnVSuitS2;
double fishSpawnVSuitS3;
double fishSpawnVSuitS4;
double fishSpawnVSuitS5;
double fishSpawnVSuitS6;
double fishSpawnVSuitV1;
double fishSpawnVSuitV2;
double fishSpawnVSuitV3;
double fishSpawnVSuitV4;
double fishSpawnVSuitV5;
double fishSpawnVSuitV6;

double fishWeightParamA;
double fishWeightParamB;

double fishEMForUnknownCells;

double fishTurbidMin;
double fishTurbidExp;
double fishDetectDistParamA;
double fishDetectDistParamB;
double fishTurbidThreshold;

double mortFishTerrPredT1;
double mortFishTerrPredT9;

double mortFishAqPredMin;
double mortFishAqPredP9;
double mortFishAqPredP1;
double mortFishAqPredD1;
double mortFishAqPredD9;
double mortFishAqPredF1;
double mortFishAqPredF9;
double mortFishAqPredL1;
double mortFishAqPredL9;
double mortFishAqPredT1;
double mortFishAqPredT9;
double mortFishAqPredU1;
double mortFishAqPredU9;


double mortFishConditionK1;
double mortFishConditionK9;
double mortFishHiTT1;
double mortFishHiTT9;
double mortFishStrandD1;
double mortFishStrandD9;

double mortFishTerrPredD1;
double mortFishTerrPredD9;
double mortFishTerrPredF1;
double mortFishTerrPredF9;
double mortFishTerrPredL1;
double mortFishTerrPredL9;
double mortFishTerrPredMin;
double mortFishTerrPredV1;
double mortFishTerrPredV9;
double mortFishVelocityV1;
double mortFishVelocityV9;
double mortFishTerrPredH1;
double mortFishTerrPredH9;

double fishPiscivoryLength;


double mortReddDewaterSurv;
double mortReddHiTT1;
double mortReddHiTT9;
double mortReddLoTT1;
double mortReddLoTT9;

double mortReddScourDepth;


double reddDevelParamA;
double reddDevelParamB;
double reddDevelParamC;
double reddNewLengthMean;
double reddNewLengthStdDev;
double reddSize;

//
// New Parameters
//
double fishSpawnWtLossFraction;

double fishMaxSwimParamA;
double fishMaxSwimParamB;
double fishMaxSwimParamC;
double fishMaxSwimParamD;
double fishMaxSwimParamE;

double fishCaptureParam1;
double fishCaptureParam9;

//END CONSTANTS INITIALIZED BY THE CPM FISH .Params FILE

}


+ createBegin: aZone;
- createEnd;

- setInstanceName: (char *) anInstanceName;
- (char *) getInstanceName;

- setFishSpeciesIndex: (int) aSpeciesIndex;
- setFishSpecies: (id <Symbol>) aFishSpecies;
- (id <Symbol>) getFishSpecies;
- printSelf;

- (void) drop;

@end



