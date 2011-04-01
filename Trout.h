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



#import "FishParams.h"
#import "HabitatSpace.h"
#import "FishCell.h"
#import "TimeManagerProtocol.h"
#import "TroutModelSwarmP.h"
#import "InterpolationTableP.h"
#import "LogisticFunc.h"
#include "DEBUGFLAGS.h"
#import "globals.h"

//#define MOVE_REPORT_ON
//#define READY_TO_SPAWN_RPT
//#define SPAWN_CELL_RPT

@interface Trout: SwarmObject
{

  id troutZone;
  id <Symbol> species;
  FishParams* fishParams;
  id <TroutModelSwarm> model;
  id <InterpolationTable> cmaxInterpolator;
  id <InterpolationTable> spawnDepthInterpolator;
  id <InterpolationTable> spawnVelocityInterpolator;

  id <List> destCellList;
  id <List> potentialReddCells;
  id <List> tagDestCellList;

  int speciesNdx;

  // generic Trout properties.
  int   age;
  id <Symbol> ageSymbol;
  double fishLength;  // cm
  double fishWeight;  // grams
  double fishCondition;
  double domValue;
  double searchParameter; // cm/hr
  double territorySize;   // cm2
  double shelterArea; //Doesn't mean that a fish has a shelter


  char* movementRule;

  double prevWeight;
  double prevLength;
  double prevCondition;
  
  double depthLengthRatioForCell;

  //
  // Mortality vars
  //
  char * deadOrAlive;
  char * deathCausedBy;
  id <Symbol> causeOfDeath;
  int yearOfDeath;
  int dateOfDeath;

  int dateLastSpawned; 
  int yearLastSpawned;

  /* Things a trout needs to know about its Cell.  Any given fish
   * is not guaranteed to know it's cell at any given time. */

  id myCell;
  id reach; // The reach in which the cell exists
  id <Symbol> reachSymbol;

  id prevCell;
  id prevReach;

  double fishXDistanceMoved;
  double fishXDistanceLastMoved;

  Color myColor;
  Color myOldColor;
  unsigned myRasterX, myRasterY;
  unsigned transectNumber;
  unsigned cellNumber;



// ENERGETICS VARIABLES
// These are set in move

double dailyDriftFoodIntake;
double dailyDriftNetEnergy;
double dailySearchFoodIntake;
double dailySearchNetEnergy;
double feedTimeForCell;
double standardResp;
double activeResp;
BOOL velocityShelter;
double hourlyDriftConRate;
double hourlySearchConRate;
double reactiveDistance;
double captureSuccess;
double captureArea;
LogisticFunc* captureLogistic;
double maxSwimSpeedForCell;
double detectDistance;
double potentialHourlyDriftIntake;
double potentialHourlySearchIntake;
double cMax;

//FEEDING STRATEGY
#define DRIFT 0
#define SEARCH 1
int fishFeedingStrategy;
int cellFeedingStrategy;
double cellSwimSpeed;      //set in calcNetEnergyForCell; used HiVelocity survival
double cellSwimSpeedForCell;      //set in calcNetEnergyForCell; used HiVelocity survival
double fishSwimSpeed;      //used in probe display; the swim speed for our cell
double expectedMaturity;
double nonStarvSurvival;
double fishFracMature;
double netEnergyForBestCell;
double netEnergyIntake;
double netEnergyForCell; 

char *feedStrategy;
char *inShelter;

double maxMoveDistance;


//
// Starvation Vars
//
double starvPa;
double starvPb;

//
// TIME
//
id <TimeManager> timeManager;
time_t timeLastSpawned;

time_t timeOfDeath;

BOOL imImmortal;
id <List> oldTagDestCellList;

BOOL spawnedThisSeason;
BOOL iAmPiscivorous;

  //
  // This is used to update the habitat survival probs
  // for aquatic predation. Either the last piscivorous 
  // fish xor the last fish on the liveFish list will trigger the update
  //
id toggledFishForHabSurvUpdate;

@public
  id <Symbol> sex;
  double sensoryRadiusFactor; 

  id randGen;
  id dieDist;
  id spawnDist;

  int rasterResolutionX;
  int rasterResolutionY;

}

+ createBegin: aZone;
- setCell: (FishCell *) aCell;
- setReach: aReach;

- createEnd;

- setTimeManager: (id <TimeManager>) aTimeManager;
- setModel: (id <TroutModelSwarm>) aModel;
- setCMaxInterpolator: (id <InterpolationTable>) anInterpolator;
- setSpawnDepthInterpolator: (id <InterpolationTable>) anInterpolator;
- setSpawnVelocityInterpolator: (id <InterpolationTable>) anInterpolator;
- setCaptureLogistic: (LogisticFunc *) aLogisticFunc;


//- setMovementRule: (char *) aRule;
- setSpeciesNdx: (int) anIndex;
- (int) getSpeciesNdx;
- (id <Symbol>) getSpecies;
- (id <Symbol>) getSex;
- setFishParams: (FishParams *) aFishParams;
- (FishParams *) getFishParams;
- setSpecies: (id <Symbol>) aSymbol;

- setAge: (int) anInt;
- (int) getAge;
- updateFishWith: (time_t) aModelTime;
- incrementAge;

- setAgeSymbol: (id <Symbol>) anAgeSymbol;
- (id <Symbol>) getAgeSymbol;


- setFishCondition: (double) aCondition;
- (double) getFishCondition;

- setFishWeightFromLength: (double) aLength 
             andCondition: (double) aCondition;

- setFishLength: (double) aLength;

- toggleFishForHabSurvUpdate;

- (id <Symbol>) getCauseOfDeath;
- (time_t) getTimeOfDeath;

- drawSelfOn: (id <Raster>) aRaster atX: (int) anX Y: (int) aY;
- setFishColor: (Color) aColor;
- tagFish;

- (double) getFishShelterArea;

- (double) getPolyCellDepth;
- (double) getPolyCellVelocity;

- (double) getWeightWithIntake: (double) anEnergyIntake;
- (double) getLengthForNewWeight: (double) aWeight;
- (double) getFracMatureForLength: (double) aLength;

- (double) getConditionForWeight: (double) aWeight 
                       andLength: (double) aLength;

- (double) expectedMaturityAt: (FishCell *) aCell;
- calcStarvPaAndPb;


- (time_t) getCurrentTimeT;
- (double) getSwimSpeedMaxSwimSpeedRatio;
- (double) calcDepthLengthRatioAt: (FishCell *) aCell;
- (double) getDepthLengthRatioForCell;
- (BOOL) getSpawnedThisSeason;
- (double) getFeedTimeForCell;


- setTimeTLastSpawned: (time_t) aTimeT;
- (BOOL) isFemaleReadyToSpawn;
- (BOOL) shouldISpawnWith: aTrout;
- updateMaleSpawner;
- (FishCell *) findCellForNewRedd;
- _createAReddInCell_: (FishCell *) aCell;

- (double) getSpawnQuality: aCell;
- (double) getNonGravelSpawnQuality: aCell;
- (double) getSpawnDepthSuitFor: (double) aDepth;
- (double) getSpawnVelSuitFor: (double) aVel;


//SCHEDULED ACTIVITIES
- spawn;
- move;
- grow;
- die;

- killFish;

- moveToMaximizeExpectedMaturity;
//- moveToMaximizeNetEnergyIntake;
//- moveToMaximizeSurvival;
//- moveToMinimizeRiskGrowth;

- moveToBestDest: bestDest;
- checkVars;





//SURVIVAL 
//- (double) getNonStarvSP: (id) aCell;


- (double) getFishWeight;
- (double) getFishLength;

- (int) getFishCount;

- (int) compare: (Trout *) aFish; //needed for the QSort in TroutModelSwarm



//FISH FEEDING AND ENERGETICS METHODS

// ACTIVITY BUDGET
- (double) calcFeedTimeAt: (FishCell *) aCell;


// FOOD INTAKE: DRIFT FEEDING STRATEGY

- (double) calcDetectDistanceAt: (FishCell *) aCell;
- (double) calcCaptureArea: (FishCell *) aCell;
- (double) calcCaptureSuccess: (FishCell *) aCell;
- (double) calcDriftIntake: (FishCell *) aCell;


//FOOD INTAKE: ACTIVE FEEDING STRATEGY

- (double) calcMaxSwimSpeedAt: (FishCell *) aCell;
- (double) calcSearchIntake: (FishCell *) aCell;


//FOOD INTAKE: MAXIMUM CONSUMPTION

- (double) calcCmax: (double) aTemperature;


// FOOD INTAKE: FOOD AVAILABILITY



//RESPIRATION COSTS

- (double) calcStandardRespirationAt: (FishCell *) aCell;
- (double) calcActivityRespirationAt: (FishCell *) aCell withSwimSpeed: (double) aSpeed;
- (double) calcTotalRespirationAt: (FishCell *) aCell withSwimSpeed: (double) aSpeed; 


// FEEDING STRATEGY SELECTION, NET ENERGY BENEFITS, AND GROWTH

- (double) calcDailyDriftNetEnergy: (FishCell *) aCell;
- (BOOL) getAmIInAShelter;
- (double) calcDailySearchNetEnergy: (FishCell *) aCell; 
- (double) calcNetEnergyForCell: (FishCell *) aCell;
- (double) calcDailySearchFoodIntake: (FishCell *) aCell;
- (double) calcDailyDriftFoodIntake: (FishCell *) aCell;

- (double) getHourlyDriftConRate;
- (double) getHourlySearchConRate;
- (int) getFishFeedingStrategy;

- (double) getSwimSpeedAt: (FishCell *) aCell forStrategy: (int) aFeedStrategy;


- calcMaxMoveDistance;

//
// tag the fish's destination cells
//
- tagCellsICouldMoveTo;
- makeMeImmortal;


//FOR TESTING PURPOSES
- (FishCell *) getCell;



//
// Needed for multiple reaches
//
- getReach;
- (id <Symbol>) getReachSymbol;





//REPORTS
#ifdef MOVE_REPORT_ON
- moveReport: (FishCell *)  aCell;
#endif


#ifdef READY_TO_SPAWN_RPT
- printReadyToSpawnRpt: (BOOL) readyToSpawn;
#endif

#ifdef SPAWN_CELL_RPT
- printSpawnCellRpt: (id <List>) spawnCellList;
#endif


- (void) drop;

@end


