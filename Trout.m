/*
inSTREAM Version 5.0, February 2012.
Individual-based stream trout modeling software. 
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Copyright (C) 2004-2012 Lang, Railsback & Associates.

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




#import <math.h>
#import "globals.h"
#import "Redd.h"
#import "Trout.h"



@implementation Trout

///////////////////////////////////////////////////////////////
//
// createBegin
//
/////////////////////////////////////////////////////////////
+ createBegin: aZone 
{
  Trout * newTrout;

  newTrout = [super createBegin: aZone];

  newTrout->troutZone = [Zone create: aZone];
  newTrout->causeOfDeath = nil;
  newTrout->captureLogistic = nil;
  newTrout->imImmortal = NO;
  newTrout->toggledFishForHabSurvUpdate = nil;
  newTrout->fishParams = nil;

  return newTrout;
}

///////////////////////////////////////////////////////////////////////
//
// setCell
//
/////////////////////////////////////////////////////////////////////
- setCell: (FishCell *) aCell 
{
  myCell = aCell;
  return self;
}

/////////////////////////////////////////////////////////////////////////////
//
// setFishID
//
////////////////////////////////////////////////////////////////////////////
- setFishID: (int) anIDNum {
  fishID = anIDNum;
  return self;
}

/////////////////////////////////////////////////////////////////////////////
//
// getFishID
//
////////////////////////////////////////////////////////////////////////////
- (int) getFishID {
  return fishID;
}


///////////////////////////////////////////////
//
// setReach
//
// set the fish's reach and its reach symbol
//
/////////////////////////////////////////////// 
- setReach: aReach
{
   reach = aReach;
   reachSymbol = [reach getReachSymbol];

   return self;
}



- (FishCell *) getCell 
{
  return myCell;
}


- getReach
{
   return reach;
}



///////////////////////////////////
//
// getReachSymbol
//
// reachSymbol is set in setReach
//
//////////////////////////////////
- (id <Symbol>) getReachSymbol
{
   return reachSymbol;
}

//////////////////////////////////////////////////////////////////
//
// createEnd
//
//////////////////////////////////////////////////////////////////
- createEnd {
  //fprintf(stdout, "Trout >>>> createEnd >>>> BEGIN\n");
  //fflush(0);

  [super createEnd];

  if(randGen == nil){
     fprintf(stderr, "ERROR: Trout >>>> createEnd >>>> fish %p doesn't have a randGen.", self);
     fflush(0);
     exit(1);
  }else{
     unifDist = [UniformDoubleDist create: troutZone setGenerator: randGen setDoubleMin: 0.0 setMax: 1.0];
  }

  hourlyDriftConRate = 0.0;
  hourlySearchConRate = 0.0;
  deadOrAlive = "ALIVE";
  spawnedThisSeason = NO;
  destCellList = [List create: troutZone];

  //fprintf(stdout, "Trout >>>> createEnd >>>> END\n");
  //fflush(0);
  return self;
}


////////////////////////////////////////////
//
// setTimeManager
//
///////////////////////////////////////////
- setTimeManager: (id <TimeManager>) aTimeManager
{
     timeManager = aTimeManager;
     return self;
}


///////////////////////////////////////////
//
// setModel
//
//////////////////////////////////////////
- setModel: (id <TroutModelSwarm>) aModel
{
    model = aModel;
    return self;
}



///////////////////////////////////////////////////////////////
//
// setCMaxInterpolator
//
///////////////////////////////////////////////////////////////
- setCMaxInterpolator: (id <InterpolationTable>) anInterpolator
{
   cmaxInterpolator = anInterpolator;
   return self;
}



///////////////////////////////////////////
//
// setSpawnDepthInterpolator
//
//////////////////////////////////////////
- setSpawnDepthInterpolator: (id <InterpolationTable>) anInterpolator
{
   spawnDepthInterpolator = anInterpolator;
   return self;
}



////////////////////////////////////////////
//
// setSpawnVelocityInterpolator
//
///////////////////////////////////////////
- setSpawnVelocityInterpolator: (id <InterpolationTable>) anInterpolator
{
    spawnVelocityInterpolator = anInterpolator;
    return self;
}


////////////////////////////////////////////////////
//
// setCaptureLogistic
//
////////////////////////////////////////////////////
- setCaptureLogistic: (LogisticFunc *) aLogisticFunc
{
   captureLogistic = aLogisticFunc;
   return self;
}


/*
//////////////////////////////////////////////////
//
// setMovementRule
//
//////////////////////////////////////////////////
- setMovementRule: (char *) aRule  {
  movementRule = aRule;
  return self;
}

*/






/////////////////////////////////////////////////////////
//
// setSpeciesIndex
//
////////////////////////////////////////////////////////
- setSpeciesNdx: (int) anIndex {
  speciesNdx = anIndex;

  return self;
}



/////////////////////////////////////////////////////////
//
// getSpeciesIndex
//
////////////////////////////////////////////////////////
- (int) getSpeciesNdx {
  return speciesNdx;

}




/////////////////////////////////////////////////////////////////////////////
//
// setFishColor
//
////////////////////////////////////////////////////////////////////////////
- setFishColor: (Color) aColor 
{
  myColor = aColor;
  return self;
}

/////////////////////////////////////////////////////////////
//
// drawSelfOn
//
/////////////////////////////////////////////////////////////
- drawSelfOn: (id <Raster>) aRaster atX: (int) anX Y: (int) aY 
{
  //fprintf(stdout, "Trout >>>> drawSelfOn >>>> BEGIN\n");
  //fprintf(stdout, "Trout >>>> drawSelfOn >>>> myColor = %ld\n", (long) myColor);
  //fflush(0);

  if (age > 0)
  {
  [aRaster fillRectangleX0: anX - (2 * age) 
                  Y0: aY - age 
                  X1: anX + (2 * age) 
                  Y1: aY + age
           //    Width: 3 
               Color: myColor];  
  }
  else
  {
  [aRaster drawPointX: anX 
                  Y: aY 
              Color: myColor];  
  }

  //fprintf(stdout, "Trout >>>> drawSelfOn >>>> END\n");
  //fflush(0);

  return self;
}



/////////////////////////////////////////////////////////////////////
//
// tagFish
//
/////////////////////////////////////////////////////////////////////
- tagFish 
{
  //fprintf(stdout, "Trout >>>> tagFish >>>> BEGIN\n");
  //fprintf(stdout, "Trout >>>> tagFish >>>> trout = %p\n", self);
  //fflush(0);

  if(reach == nil)
  {
      fprintf(stdout, "ERROR: Trout >>>> tagFish >>>> reach is nil\n");
      fflush(0);
      exit(1);
  }

  [self setFishColor: (Color) TAG_FISH_COLOR];
  [model updateTkEventsFor: reach];

  //fprintf(stdout, "Trout >>>> tagFish >>>> trout = %p\n", self);
  //fprintf(stdout, "Trout >>>> tagFish >>>> END\n");
  //fflush(0);
  return self;
}



//////////////////////////////////////////
//
// setFishParams
//
//////////////////////////////////////////
- setFishParams: (FishParams *) aFishParams
{
    fishParams = aFishParams;
    return self;
}


///////////////////////////////////////////
//
// getFishParams
// 
///////////////////////////////////////////
- (FishParams *) getFishParams
{
    return fishParams;
}
 
/////////////////////////////////////////////////////////////////////////////
//
// setSpecies
//
////////////////////////////////////////////////////////////////////////////
- setSpecies: (id <Symbol>) aSymbol 
{
   species = aSymbol;
   return self;
}


/////////////////////////////////////////////////////////////////////////////
//
// getSpecies
//
////////////////////////////////////////////////////////////////////////////
- (id <Symbol>) getSpecies
{
   return species;
}


//////////////////////////////////////
//
// getSex
//
///////////////////////////////////////
- (id <Symbol>) getSex
{
   return sex;
}



/////////////////////////////////////////////////////////////////////////////
//
// setAge
//
////////////////////////////////////////////////////////////////////////////
- setAge: (int) anInt 
{
   age = anInt;
   return self;
}

///////////////////////////////////////////////////////////
//
// getAge
//
//////////////////////////////////////////////////////////
- (int) getAge 
{
   return age;
}


////////////////////////////////////////////////////////
//
// updateFish
//
// We assume that all fish increment their age
// on Jan 1.
//
////////////////////////////////////////////////////////
- updateFishWith: (time_t) aModelTime
{
   if([timeManager isThisTime: aModelTime onThisDay: "01/1"] == YES)
   {
       [self incrementAge];  
   }
  
   //
   // reset spawnedThisSeason at the start of each spawning season
   //
   if([timeManager isThisTime: aModelTime 
                    onThisDay: (char *) fishParams->fishSpawnStartDate] == YES) 
   {
      spawnedThisSeason = NO;
   }

   toggledFishForHabSurvUpdate = nil;
 
   return self;
}

///////////////////////////////////////////////////////////
//
// incrementAge
//
///////////////////////////////////////////////////////////
- incrementAge 
{
  ++age;
  [self setAgeSymbol: [model getAgeSymbolForAge: age]];
  return self;
}


//////////////////////////////////////
//
// setAgeSymbol
//
//////////////////////////////////////
- setAgeSymbol: (id <Symbol>) anAgeSymbol
{
   ageSymbol = anAgeSymbol;
   return self;
}


////////////////////////////////////
//
// getAgeSymbol
//
////////////////////////////////////
- (id <Symbol>) getAgeSymbol
{
   return ageSymbol;
}

////////////////////////////////////////////////////
//
// setFishCondition
//
/////////////////////////////////////////////////
- setFishCondition: (double) aCondition 
{
  fishCondition = aCondition;
  return self;
}


/////////////////////////////////////////////////////////////////////
//
// setFishWeightFromLength: andCondtion:
// 
////////////////////////////////////////////////////////////////////
- setFishWeightFromLength: (double) aLength andCondition: (double) aCondition 
{

  fishWeight =   aCondition 
               * fishParams->fishWeightParamA 
               * pow(aLength,fishParams->fishWeightParamB);


   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_GROW
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<< METHOD: setFishWeightFromLength speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"fishWeightParamA = %f fishWeightParamB = %f \n", fishParams->fishWeightParamA,  fishParams->fishWeightParamB);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif



  return self;
}

/////////////////////////////////////////////////////////////////
//
// getWeightWithIntake
//
//////////////////////////////////////////////////////////////////
- (double) getWeightWithIntake: (double) anEnergyIntake {
  double deltaWeight;
  double weight;


   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_GROW
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<< METHOD: getWeightWithIntake speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"fishEnergyDensity = %f \n", fishParams->fishEnergyDensity);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif



  deltaWeight = anEnergyIntake/(fishParams->fishEnergyDensity);
  weight = fishWeight + deltaWeight;

  if(weight > 0.0) 
  {
    return weight;
  }
  else 
  {
    return 0.0;
  }
}


/////////////////////////////////////////////////////////////////////
//
// getFishWeight
//
////////////////////////////////////////////////////////////////////
- (double) getFishWeight 
{
  return fishWeight;
}

/////////////////////////////////////////////////////////////////////////////
//
// setFishLength
//
////////////////////////////////////////////////////////////////////////////
- setFishLength: (double) aLength 
{
  fishLength = aLength;
  fishWeightAtK1 = (fishParams->fishWeightParamA) * pow(fishLength, fishParams->fishWeightParamB);

  return self;
}




///////////////////////////////////////
//
// toggleFishForHabSurvUpdate
//
///////////////////////////////////////
- toggleFishForHabSurvUpdate
{
   toggledFishForHabSurvUpdate = self;

   return self;
}

   
////////////////////////////////////////////////////////////////////
//
// getLengthForNewWeight
//
// updated with new method 7 Aug 2014
//////////////////////////////////////////////////////////////////
- (double) getLengthForNewWeight: (double) aWeight 
{
  //double fishWannabeLength;


   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_GROW
   
      
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<< METHOD: getLengthForNewWeight speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"fishWeightParamA = %f fishWeightParamB = %f\n", fishParams->fishWeightParamA, fishParams->fishWeightParamB);
       fprintf(stderr,"\n"); 
        
 
     #endif
   #endif


  //fishWannabeLength = pow((aWeight/fishParams->fishWeightParamA),1/fishParams->fishWeightParamB);

  if(aWeight <=  fishWeightAtK1) 
  {
     return fishLength;
  }
  else 
  {
     return pow((aWeight/fishParams->fishWeightParamA),1/fishParams->fishWeightParamB);
  }
}


/////////////////////////////////////////////////////////////////////////////
//
//  getFishLength
//
////////////////////////////////////////////////////////////////////////////
- (double) getFishLength 
{
  return fishLength;
}



//////////////////////////////////
//
// getFishCount
//
/////////////////////////////////
- (int) getFishCount
{
   return 1;
}

///////////////////////////////////////////////////////////////
//
// getConditionForWeight: andLength:
//
//////////////////////////////////////////////////////////////
- (double) getConditionForWeight: (double) aWeight andLength: (double) aLength 
{
  double condition=LARGEINT;

   //fprintf(stdout, "Trout >>>> getConditionForWeight >>>> aWeight = %f\n", aWeight);
   //fprintf(stdout, "Trout >>>> getConditionForWeight >>>> aLength = %f\n", aLength);
   //fprintf(stdout, "Trout >>>> getConditionForWeight >>>> fishParams->fishWeightParamA = %f\n", fishParams->fishWeightParamA);
   //fprintf(stdout, "Trout >>>> getConditionForWeight >>>> fishParams->fishWeightParamB = %f\n", fishParams->fishWeightParamB);
   //fflush(0);

   condition = aWeight/
        (fishParams->fishWeightParamA*pow(aLength,fishParams->fishWeightParamB)); 

   return condition;
}

- (double) getFishCondition 
{
  return fishCondition;
}

/////////////////////////////////////////////////////////////////
//
// getFracMatureForLength
//
//////////////////////////////////////////////////////////////
- (double) getFracMatureForLength: (double) aLength 
{
   double fmature;

   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_GROW
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<< METHOD: getFracMatureForLength speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"fishSpawnMinLength = %f \n", fishParams->fishSpawnMinLength);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif


  fmature =  aLength/fishParams->fishSpawnMinLength;

  if(fmature < 1.0) 
  {
     return fmature;
  }
  else 
  {
    return 1.0;
  }
}


/////////////////////////////////////////////////////////////////////////////
//
// getFishShelterArea
//
////////////////////////////////////////////////////////////////////////////
- (double) getFishShelterArea 
{
  return fishLength*fishLength;
}



///////////////////////////////////
//
// getPolyCellDepth
//
//////////////////////////////////
- (double) getPolyCellDepth
{
    return [myCell getPolyCellDepth];
}


//////////////////////////////////
//
// getPolyCellVelocity
//
/////////////////////////////////
- (double) getPolyCellVelocity
{
   return [myCell getPolyCellVelocity];
}



////////////////////////////////////////////////////////
//
// TIME_T METHODS
//
////////////////////////////////////////////////////////

- setTimeTLastSpawned: (time_t) aTime_t 
{
  timeLastSpawned = aTime_t;
  return self;
}


- (time_t) getCurrentTimeT 
{
  return [model getModelTime];
}


/////////////////////////////////////////////////
//
// getSwimSpeedMaxSwimSpeedRatio
//
////////////////////////////////////////////////
- (double) getSwimSpeedMaxSwimSpeedRatio
{
   double aSwimSpeedMaxSwimSpeedRatio;

   //
   // maxSwimSpeedForCell is set in the 
   // following methods: moveToBestDest
   //                    expectedMaturityAt
   //
   // cellSwimSpeedForCell is set in: calcNetEnergyForCell
   //
   if(maxSwimSpeedForCell <= 0.0)
   {
       fprintf(stdout, "ERROR: Trout >>>> getSwimSpeedMaxSwimSpeedRatio >>>> maxSwimSpeedForCell is less than or equal to zero\n");  
       fflush(0);
       exit(1);
   }

   aSwimSpeedMaxSwimSpeedRatio = cellSwimSpeedForCell/maxSwimSpeedForCell;


   //
   // FIX ME
   //


   return aSwimSpeedMaxSwimSpeedRatio ;

   //return 1.0;

}


////////////////////////////////////////////////
//
// calcDepthLengthRatioAt
//
///////////////////////////////////////////////// 
- (double) calcDepthLengthRatioAt: (FishCell *) aCell
{
   double depthLengthRatio = [aCell getPolyCellDepth]/fishLength;
   return depthLengthRatio;
}



/////////////////////////////////////////////////////////
//
// getDepthLengthRatioForCell
//
// depthLengthRatioForCell is set in expectedMaturityAt
//
/////////////////////////////////////////////////////////
- (double) getDepthLengthRatioForCell
{
   return depthLengthRatioForCell;
}


/*
- (BOOL) getFishSpawnedThisTime
{
  BOOL didISpawn = NO;
  if(timeLastSpawned == [model getModelTime])
  {
     didISpawn = YES;
  }
  return didISpawn;
}  
*/



- setSpawnedThisSeason: (BOOL) aBool
{
   spawnedThisSeason = aBool;
   return self;
}


- (BOOL) getSpawnedThisSeason
{
   return spawnedThisSeason;
}


/////////////////////////////////////////////////
//
// getFeedTmeForCell
//
// feedTimeForCell is set in: moveToBestDest
//                            expectedMaturityAt  
//
//////////////////////////////////////////////////
- (double) getFeedTimeForCell
{
    return feedTimeForCell;
} 
    

////////////////////////////////////////////////////////////////////
//
//
// Scheduled actions for trout 
//
// There are four scheduled actions: spawn, move, grow, and die 
//
// spawn is the first action taken by fish in their daily routine 
// spawn may result in the fish moving to another cell 
//
////////////////////////////////////////////////////////////////////


/////////////////////////////////////
//
// spawn
//
/////////////////////////////////////
- spawn 
{
  // spawn is executed only by females
  // determine if ready to spawn 
  //    spawning criteria
  //       a) date window
  //       b) not spawned this year
  //       c) age minimum
  //       d) size minimum
  //       e) condition threshold
  // identify Redd location
  //       a) within moving distance
  //       b) pick cell with highest spawnQuality, where
  //           spawnQuality = spawnDepthSuit * spawnVelocitySuit * spawnGravelArea
  // move to spawning cell
  // make Redd
  //       calculate numberOfEggs
  //       set spawnerLength
  // update lastSpawnDate to today
  // select a male that also spawns

  id spawnCell=nil;
  id <List> fishList;
  id <ListIndex> fishLstNdx;
  id anotherTrout = nil;
  //
  // If we're dead or male we can't spawn we can't spawn
  //
  if(sex == Male) {
      return self;
  }
  if(causeOfDeath) {
     return self;
  }
  if(reach == nil) {
      fprintf(stderr, "ERROR: Trout >>>> spawn >>>> reach is nil\n");
      fflush(0);
      exit(1);
  }
  //fprintf(stdout,"Trout >>>> spawn >>>> isFemaleReadyToSpawn = %d\n",[self isFemaleReadyToSpawn]);
  if([self isFemaleReadyToSpawn] == NO){
    if([model getWriteReadyToSpawnReport] == YES){
      [self printReadyToSpawnRpt: NO];
    }
    return self;
  }
  if([model getWriteReadyToSpawnReport] == YES){
      [self printReadyToSpawnRpt: YES];
  }
  if((spawnCell = [self findCellForNewRedd]) == nil) {
     fprintf(stderr, "WARNING: Trout >>>> spawn >>>> No spawning habitat found, making Redd without moving");
     fflush(0);
     spawnCell = myCell;
  }
  [spawnCell addFish: self]; 
  [self _createAReddInCell_: spawnCell];

  //
  // reduce weight of spawners
  //
  fishWeight = fishWeight * (1.0 - fishParams->fishSpawnWtLossFraction);

  // Condition update added 6 Aug 2014
  fishCondition = [self getConditionForWeight: fishWeight andLength: fishLength];

  timeLastSpawned = [self getCurrentTimeT];
  spawnedThisSeason = YES;


  //
  // Now, find male spawner.
  //
  fishList = [model getLiveFishList]; 

  if(fishList == nil){
     fprintf(stderr, "ERROR: Trout >>>> spawn >>>> fishList is nil\n");
     fflush(0);
     exit(1);
  }

  //
  // Search for first (= largest) eligible
  // male, if there is one.
  //
  fishLstNdx = [fishList listBegin: scratchZone];
  while(([fishLstNdx getLoc] != End) && ((anotherTrout = [fishLstNdx next]) != nil)){
       if([self shouldISpawnWith: anotherTrout]){
           [anotherTrout updateMaleSpawner];
           break;
       }
  }
  [fishLstNdx drop];

  return self;
}


///////////////////////////////////////////////////////////
//
// isFemaleReadyToSpawn
//
///////////////////////////////////////////////////////////
- (BOOL) isFemaleReadyToSpawn 
{
  time_t currentTime;
  double currentTemp = -LARGEINT;

  /* ready?
   *    a) age minimum (fish) <branch>
   *    b) size minimum (fish) <branch>
   *    c) spawned already this year  (fish) <branch>
   *    d) date window (cell) <branch> <msg>
   *    e) flow threshhold (cell) <branch> <msg>
   *    f) temperature (cell) <branch> <msg>
   *    g) steady flows (cell) <branch> <msg>
   *    h) condition threshhold (fish) <calc>
   */

   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_SPAWN
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<< METHOD: readyToSpawn speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"fishSpawnEndDate = %s fishSpawnStartDate = %s\n", fishParams->fishSpawnEndDate, fishParams->fishSpawnStartDate);
       fprintf(stderr,"fishSpawnMinAge = %d \n", fishParams->fishSpawnMinAge);
       fprintf(stderr,"fishSpawnMinLength = %f \n", fishParams->fishSpawnMinLength);
       fprintf(stderr,"fishSpawnMinTemp = %f \n", fishParams->fishSpawnMinTemp);
       //fprintf(stderr,"fishSpawnMaxFlow = %f \n", fishParams->fishSpawnMaxFlow);
       fprintf(stderr,"fishSpawnMaxFlowChange = %f \n", fishParams->fishSpawnMaxFlowChange);
       fprintf(stderr,"fishSpawnMinCond = %f \n", fishParams->fishSpawnMinCond);
       fprintf(stderr,"fishSpawnProb = %f \n", fishParams->fishSpawnProb);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif

  currentTime =  [self getCurrentTimeT];

  //
  // IN THE WINDOW FOR THIS YEAR?
  //
  if([timeManager isTimeT: currentTime
              betweenMMDD: (char *) fishParams->fishSpawnStartDate 
                  andMMDD: (char *) fishParams->fishSpawnEndDate] == NO) 
  { 
      return NO;
  }

  //
  // AGE
  //
  if (age < fishParams->fishSpawnMinAge)
  {
      return NO;
  }

  //
  // SIZE
  //
  if (fishLength < fishParams->fishSpawnMinLength) 
  {
      return NO;
  }

  //
  // TEMPERATURE
  //
  //
  currentTemp = [reach getTemperature];

  if(currentTemp == -LARGEINT)
  {
      fprintf(stderr, "ERROR: Trout >>>> readyToSpawn >>>> currentTemp = %f\n", currentTemp);
      fflush(0);
      exit(1);
  }
  if((currentTemp < fishParams->fishSpawnMinTemp) ||
	   (fishParams->fishSpawnMaxTemp < currentTemp))
  {
      return NO;
  }

  //
  // FLOW THRESHHOLD
  //
  if([reach getRiverFlow] > [reach getHabMaxSpawnFlow])
  {
      return NO;
  }

  //
  // STEADY FLOWS
  //
  if(([reach getFlowChange]/[reach getRiverFlow]) > fishParams->fishSpawnMaxFlowChange)
  {
      return NO;
  }


  //
  // CONDITION THRESHHOLD
  //
  if(fishCondition <= fishParams->fishSpawnMinCond)
  {
      return NO;
  }


  //
  // SPAWNED THIS SEASON?
  //
  if(spawnedThisSeason == YES) 
  {
      return NO;
  }

  //
  // FINALLY TEST AGAINST RANDOM DRAW
  //
  if([unifDist getDoubleSample] > fishParams->fishSpawnProb)
  {
      return NO;
  }

  //
  // IF WE FALL THROUGH ALL THE ABOVE, then YES
  // I'M READY TO SPAWN.
  //
  return YES;
   
} // readyToSpawn



/////////////////////////////////////////////
//
// shouldISpawnWith
//
/////////////////////////////////////////////
- (BOOL) shouldISpawnWith: aTrout
{
   if([aTrout getSex] != Male)
   {
       return NO;
   }
   if([aTrout getSpecies] != species)
   {
       return NO;
   }
   if([aTrout getReach] != reach)
   {
       return NO;
   }
   if([aTrout getFishLength] < fishParams->fishSpawnMinLength)
   {
       return NO;
   }
   if([aTrout getAge] < fishParams->fishSpawnMinAge)
   {
       return NO;
   }
   if([aTrout getFishCondition] < fishParams->fishSpawnMinCond) 
   {
       return NO;
   }
   if([aTrout getSpawnedThisSeason] == YES) 
   {
       return NO;
   }

   return YES;
}


////////////////////////////////////
//
// updateMaleSpawner
//
///////////////////////////////////       
- updateMaleSpawner 
{
  if(sex != Male)
  {
     fprintf(stderr, "ERROR: Trout >>>> updateMaleSpawner >>>> fish is not male\n");
     fflush(0);
     exit(1);
  }

  spawnedThisSeason = YES;
  fishWeight = fishWeight * (1.0 - fishParams->fishSpawnWtLossFraction);

  // Condition update added 6 Aug 2014
  fishCondition = [self getConditionForWeight: fishWeight andLength: fishLength];

  return self;
}  
       


/////////////////////////////////////////////
//
// findCellForNewRedd
//
////////////////////////////////////////////
- (FishCell *) findCellForNewRedd
{
  id <ListIndex> cellNdx;
  id bestCell=nil;
  id nextCell=nil;
  double bestSpawnQuality=0.0;
  double spawnQuality=-LARGEINT;

  //fprintf(stdout, "Trout >>>> findCellForNewRedd >>>> BEGIN\n");
  //fflush(0);

  if(potentialReddCells == nil)
  {
     potentialReddCells = [List create: troutZone];
  }

  [myCell getNeighborsWithin: maxMoveDistance
                    withList: potentialReddCells]; 

  if([model getWriteSpawnCellReport] == YES){
     [self printSpawnCellRpt: potentialReddCells];
  }

  cellNdx = [potentialReddCells listBegin: scratchZone];
  while(([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil)) 
  {
    spawnQuality = [self getSpawnQuality: nextCell];

    if(spawnQuality > bestSpawnQuality) 
    {
      bestSpawnQuality = spawnQuality;
      bestCell = nextCell;
    }
  }

  if(bestCell == nil)
  {
      [cellNdx setLoc: Start];
      while (([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil)) 
      {
        spawnQuality = [self getNonGravelSpawnQuality: nextCell];

        if(spawnQuality > bestSpawnQuality) 
        {
          bestSpawnQuality = spawnQuality;
          bestCell = nextCell;
        }
      }
  }

  [cellNdx drop];

  [potentialReddCells removeAll];
  [potentialReddCells drop];
  potentialReddCells = nil;

  //
  // we test for nil in the calling method
  //
  //fprintf(stdout, "Trout >>>> findCellForNewRedd >>>> best depth: %f\n",[bestCell getPolyCellDepth]);

  //fprintf(stdout, "Trout >>>> findCellForNewRedd >>>> END\n");
  //fflush(0);

  return bestCell;
}



///////////////////////////////////////
//
// _createAReddInCell_
//
//////////////////////////////////////
- _createAReddInCell_: (FishCell *) aCell 
{
  id  newRedd;

   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_SPAWN
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<< _createAReddInCell speciesNdx = %d >>>>>\n", speciesNdx);
       fprintf(stderr,"<<<<< _createAReddInCell redd = %p >>>>>\n", self);
       fprintf(stderr,"<<<<< _createAReddInCell myCell = %p >>>>>\n", aCell);
       fprintf(stderr,"fishFecundParamA = %f fishFecundParamB = %f\n", fishParams->fishFecundParamA, fishParams->fishFecundParamB);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif

  newRedd = [Redd createBegin: [model getModelZone]];
  [newRedd setCell: aCell];
  [newRedd setModel];
  [newRedd setFishParams: fishParams];
  [newRedd setTimeManager: timeManager];
  [newRedd setCellNumber: [aCell getPolyCellNumber]];
  [newRedd setReddColor: myColor];
  [newRedd setSpecies: [self getSpecies]];
  [newRedd setSpeciesNdx: [self getSpeciesNdx]];
  [newRedd setNumberOfEggs: fishParams->fishFecundParamA
         * pow(fishLength, fishParams->fishFecundParamB)
         * fishParams->fishSpawnEggViability];
  [newRedd setSpawnerLength: fishLength];
  [newRedd setSpawnerWeight: fishWeight];
  [newRedd setSpawnerAge: age];
  [newRedd setCreateTimeT: [self getCurrentTimeT]];
  [newRedd setReddBinomialDist: [model getReddBinomialDist]];  

  newRedd = [newRedd createEnd];

  [aCell addRedd: newRedd];

  [[model getReddList] addLast: newRedd];

  return self;
}

////////////////////////////////////////////////////////////////////
//
// getSpawnQuality
//
////////////////////////////////////////////////////////////////////
- (double) getSpawnQuality: aCell 
{
  double spawnQuality;

  spawnQuality = [self getSpawnDepthSuitFor: [aCell getPolyCellDepth] ]
               * [self getSpawnVelSuitFor: [aCell getPolyCellVelocity] ]
               * [aCell getPolyCellArea]
               * [aCell getCellFracSpawn]; 

  return spawnQuality;
}


////////////////////////////////////////////////////
//
// getNonGravelSpawnQuality
//
///////////////////////////////////////////////////
- (double) getNonGravelSpawnQuality: aCell
{
    double spawnQuality;
    spawnQuality =   [self getSpawnDepthSuitFor: [aCell getPolyCellDepth]]
                   * [self getSpawnVelSuitFor: [aCell getPolyCellVelocity]];

    return spawnQuality;
}



//////////////////////////////////////////////////////////////////////
//
// getSpawnDepthSuitFor
//
/////////////////////////////////////////////////////////////////////
- (double) getSpawnDepthSuitFor: (double) aDepth 
{
    double sds=LARGEINT;
   
    if(spawnDepthInterpolator == nil)
    {
       fprintf(stderr, "ERROR: Trout >>>> getSpawnDepthSuitFor >>>> spawnDepthInterpolator is nil\n");
       fflush(0);
       exit(1);
    }

    sds = [spawnDepthInterpolator getValueFor: aDepth];

    if(sds < 0.0)
    {
       sds = 0.0;
    }

    return sds;

} 




/////////////////////////////////////////////////////////////////////
//
// getSpawnVelSuitFor 
//
/////////////////////////////////////////////////////////////////////
- (double) getSpawnVelSuitFor: (double) aVel 
{
    double svs=LARGEINT;

    if(spawnVelocityInterpolator == nil)
    {
       fprintf(stderr, "ERROR: Trout >>>> spawnVelocityInterpolator is nil\n");
       fflush(0);
       exit(1);
    }

    svs = [spawnVelocityInterpolator getValueFor: aVel];

    if(svs < 0.0)
    {
        svs = 0.0;
    }

    return svs;
}


//////////////////////////////////////////////////////////////////////
//
// Move 
//
// move is the second action taken by fish in their daily routine 
//
//////////////////////////////////////////////////////////////////////

- move 
{
   //
   // calcMaxMoveDistance sets the ivar
   // maxMoveDistance.
   //
   [self calcMaxMoveDistance];
   [self moveToMaximizeExpectedMaturity];

   return self;

}

///////////////////////////////////////////////////////////////////////
//
// moveToMaximizeExpectedMaturity 
//
///////////////////////////////////////////////////////////////////////
- moveToMaximizeExpectedMaturity 
{
  id <ListIndex> destNdx;
  FishCell *destCell=nil;
  FishCell *bestDest=nil;
  double bestExpectedMaturity=0.0;
  double expectedMaturityAtDest=0.0;

  double temporaryTemperature;

  //fprintf(stderr, "Trout >>>> moveToMaximizeExpectedMaturity >>>> BEGIN >>>> fish = %p\n", self);
  //fflush(0);

  if(myCell == nil) 
  {
    fprintf(stderr, "WARNING: Trout >>>> moveToMaximizeExpectedMaturity >>>> Fish 0x%p has no Cell context.\n", self);
    fflush(0);
    return self;
  }

  //
  // Calculate the variables that depend only on the reach that a fish is in.
  //
  temporaryTemperature = [myCell getTemperature];
  standardResp    = [self calcStandardRespirationAt: myCell];
  cMax            = [self calcCmax: temporaryTemperature];
  detectDistance  = [self calcDetectDistanceAt: myCell]; 

 
  if(destCellList == nil)
  {
      fprintf(stderr, "ERROR: Trout >>>> moveToMaximizeExpectedMaturity >>>> destCellList is nil\n");
      fflush(0);
      exit(1);
  }

  //
  // destCellList must be empty
  // before it is populated.
  //
  [destCellList removeAll];
  
  //
  // Now, let the habitat space populate
  // the destCellList with myCell and its adjacent cells
  // and any other cells that are within
  // maxMoveDistance.

  //  Code modified 5 Dec 2011 because getNeighborsWithin: now includes the
  //  fish's current cell.
  //
  //fprintf(stdout, "Trout >>>> moveToMaximizeExpectedMaturity >>>> maxMoveDistance = %f\n", maxMoveDistance);
   //fflush(0);
  //xprint(myCell);

  if(myCell == nil)
  {
      fprintf(stderr, "ERROR: Trout >>>> moveToMaximizeExpectedMaturity >>>> myCell is nil\n");
      fflush(0);
      exit(1);
  }

  [myCell getNeighborsWithin: maxMoveDistance
                    withList: destCellList];

  destNdx = [destCellList listBegin: scratchZone];
  while (([destNdx getLoc] != End) && ((destCell = [destNdx next]) != nil))
  {
      //
      // SHUNT FOR DEPTH ... it's assumed fish won't jump onto shore
      //
      if([destCell getPolyCellDepth] <= 0.0)
      {
         continue;
      }

      expectedMaturityAtDest = [self expectedMaturityAt: destCell];

      if (expectedMaturityAtDest >= bestExpectedMaturity) 
      {
	  bestExpectedMaturity = expectedMaturityAtDest;
	  bestDest = destCell;
      }

   }  //while destNdx

   if(bestDest == nil) // This can happen if all cells on destCellList are dry
   { 
      // So stay put and suffer
      bestDest = myCell;
   }

   // 
   //  Now, move 
   //

   [self moveToBestDest: bestDest];

   iAmPiscivorous = NO;

   if(fishLength >= fishParams->fishPiscivoryLength) 
   {
      iAmPiscivorous = YES;
      [reach incrementNumPiscivorousFish];
   }

   // The variable updateAqPredSurvProb is set each day by the model swarm
   // method setUpdateAqPredToYes, part of the updateActions.
   // It is set to yes if this fish is either (a) the smallest
   // piscivorous fish or (b) the last fish. The aquatic predation
   // survival probability needs to be updated when this fish moves. 

   if(toggledFishForHabSurvUpdate)
   {
      //fprintf(stdout, "Trout >>>> move ... >>>> toggledFishForHabSurvUpdate >>>> fish = %p self = %p\n", toggledFishForHabSurvUpdate, self);
      //fprintf(stdout, "Trout >>>> move ... >>>> toggledFishForHabSurvUpdate >>>> fishLength = %f\n", fishLength);
      //fflush(0);

      [model updateHabSurvProbs];
   }

   //
   // RESOURCE CLEANUP
   // 
   if(destNdx != nil) 
   {
     [destNdx drop];
   }

   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_MOVE
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<<METHOD: moveToMaximizeExpectedMaturity speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif

  //fprintf(stderr, "Trout >>>> moveToMaximizeExpectedMaturity >>>> END >>>> expectedMaturityAtDest = %f\n", expectedMaturityAtDest);
  //fprintf(stderr, "Trout >>>> moveToMaximizeExpectedMaturity >>>> END >>>> fish = %p\n", self);
  //fflush(0);

  return self;

} // moveToMaximizeExpectedMaturity 


///////////////////////////////////////
//
// movetToBestDest
//
///////////////////////////////////////
- moveToBestDest: bestDest 
{

   //fprintf(stdout, "Trout >>>> moveToBestDest >>>> BEGIN\n");
   //fflush(0);

/*
	The following instance variables are set mainly for testing movement calculations
	by probing the fish. HOWEVER (1) netEnergyForBestCell must be set here because it is used in
	-grow, (2) the feeding strategy, hourly food consumption rates, and velocity shelter use 
	must be set here so the destination cell's food and velocity shelter availability can
	be updated accurately when the fish moves (cell method "eatHere"). 

	These variables show the state of the fish when it made its movement decision
	and will not necessarily be equal to the results of the same methods executed at the
	end of a model time step because there will be different numbers of fish in cells etc.
	after -move is completed for all fish.

	These variables must be set BEFORE the fish actually moves to the new cell, so the
	fish is not included in the destination cell's list of contained fish (so the fish 
	does not compete with itself for food).

	It seems inefficient to re-calculate these variables after finding the best destination
	cell, but it is much cleaner and safer this way! 
*/

  feedTimeForCell = [self calcFeedTimeAt: bestDest];
  standardResp = [self calcStandardRespirationAt: bestDest];
  maxSwimSpeedForCell = [self calcMaxSwimSpeedAt: bestDest];
  detectDistance = [self calcDetectDistanceAt: bestDest];
  captureSuccess = [self calcCaptureSuccess: bestDest];
  captureArea = [self calcCaptureArea: bestDest];
  cMax = [self calcCmax: [bestDest getTemperature] ];
  potentialHourlyDriftIntake = [self calcDriftIntake: bestDest];
  potentialHourlySearchIntake = [self calcSearchIntake: bestDest];
  dailyDriftFoodIntake = [self calcDailyDriftFoodIntake: bestDest];
  dailyDriftNetEnergy = [self calcDailyDriftNetEnergy: bestDest];
  dailySearchFoodIntake = [self calcDailySearchFoodIntake: bestDest];
  dailySearchNetEnergy = [self calcDailySearchNetEnergy: bestDest];
  netEnergyForBestCell = [self calcNetEnergyForCell: bestDest];
  expectedMaturity = [self expectedMaturityAt: bestDest];

  nonStarvSurvival = [bestDest getTotalKnownNonStarvSurvivalProbFor: self];

  fishFeedingStrategy = cellFeedingStrategy; //cellFeedingStrategy is set in -calcNetEnergyForCell
  fishSwimSpeed       = cellSwimSpeedForCell;       // cellSwimSpeedForCell is set in -calcNetEnergyForCell

  activeResp = [self calcActivityRespirationAt: bestDest 
                                 withSwimSpeed: [self getSwimSpeedAt: bestDest forStrategy: fishFeedingStrategy] ];

   switch(fishFeedingStrategy) 
   {
     case DRIFT: if(feedTimeForCell != 0.0) 
                 {
                     hourlyDriftConRate = dailyDriftFoodIntake/feedTimeForCell;
                 }
                 else 
                 {
                     hourlyDriftConRate = 0.0;
                 }
                 hourlySearchConRate = 0.0;
                 feedStrategy = "DRIFT";
         
                 velocityShelter = [bestDest getIsShelterAvailable];

                 if(velocityShelter == YES) 
                 {
                     inShelter = "YES";   //Probe Variable
                 }
                 else 
                 {
                    inShelter = "NO";
                 }
                 break;
     
     case SEARCH: if(feedTimeForCell != 0.0) 
                  {
                     hourlySearchConRate = dailySearchFoodIntake/feedTimeForCell;
                  }
                  else 
                  {
                     hourlySearchConRate = 0.0;
                  } 
                  hourlyDriftConRate  = 0.0;
                  velocityShelter = NO; 
                  inShelter = "NO"; //Probe Variable
                  feedStrategy = "SEARCH";  //Probe Variable
                  break;

     default: fprintf(stderr, "ERROR: Trout >>>> moveToBestDest >>>> Fish has no feeding strategy\n");
              fflush(0);
              exit(1);
              break;

   }

   // Update previous location
   prevCell = myCell;
   prevReach = reach;

  //PRINT THE MOVE REPORT
  if([model getWriteMoveReport] == YES){
    [self moveReport: bestDest];
  }

   //
   // Now, we move...
   // eatHere indirectly sets the fish's cell and the fish's reach
   //
   [bestDest eatHere: self]; 


   //[self checkVars];

   //fprintf(stdout, "Trout >>>> moveToBestDest >>>> END\n");
   //fflush(0);

   return self;
}

- checkVars
{
  fprintf(stdout, "Trout >>>> checkVars >>>> BEGIN\n");
  fflush(0);

  fprintf(stdout, "Trout >>>> checkVars >>>> feedTimeForCell = %f\n", feedTimeForCell);
  fprintf(stdout, "Trout >>>> checkVars >>>> standardResp = %f\n", standardResp);
  fprintf(stdout, "Trout >>>> checkVars >>>> maxSwimSpeedForCell = %f\n", maxSwimSpeedForCell);
  fprintf(stdout, "Trout >>>> checkVars >>>> detectDistance = %f\n", detectDistance);
  fprintf(stdout, "Trout >>>> checkVars >>>> captureSuccess = %f\n", captureSuccess);
  fprintf(stdout, "Trout >>>> checkVars >>>> cMax = %f\n", cMax);
  fprintf(stdout, "Trout >>>> checkVars >>>> potentialHourlyDriftIntake = %f\n", potentialHourlyDriftIntake);
  fprintf(stdout, "Trout >>>> checkVars >>>> potentialHourlySearchIntake = %f\n", potentialHourlySearchIntake);
  fprintf(stdout, "Trout >>>> checkVars >>>> dailyDriftFoodIntake = %f\n", dailyDriftFoodIntake);
  fprintf(stdout, "Trout >>>> checkVars >>>> dailyDriftNetEnergy = %f\n", dailyDriftNetEnergy);
  fprintf(stdout, "Trout >>>> checkVars >>>> dailySearchFoodIntake = %f\n", dailySearchFoodIntake);
  fprintf(stdout, "Trout >>>> checkVars >>>> dailySearchNetEnergy = %f\n", dailySearchNetEnergy);
  fprintf(stdout, "Trout >>>> checkVars >>>> netEnergyForBestCell = %f\n", netEnergyForBestCell);
  fprintf(stdout, "Trout >>>> checkVars >>>> expectedMaturity = %f\n", expectedMaturity);
  fprintf(stdout, "Trout >>>> checkVars >>>> nonStarvSurvival = %f\n", nonStarvSurvival);
  fprintf(stdout, "Trout >>>> checkVars >>>> fishFeedingStrategy = %d\n", (int) fishFeedingStrategy);
  fprintf(stdout, "Trout >>>> checkVars >>>> fishSwimSpeed = %f\n", fishSwimSpeed);
  fprintf(stdout, "Trout >>>> checkVars >>>> activeResp = %f\n", activeResp);
  //fprintf(stdout, "Trout >>>> checkVars >>>> utmCellNumber = %d\n", [myCell getPolyCellNumber]);
  fprintf(stdout, "Trout >>>> checkVars >>>> fishLength = %f\n", fishLength);
  fprintf(stdout, "Trout >>>> checkVars >>>> fishWeight = %f\n", fishWeight);
  fprintf(stdout, "Trout >>>> checkVars >>>> fishCondition = %f\n", fishCondition);

  fprintf(stdout, "Trout >>>> checkVars >>>> END\n");
  fflush(0);

  return self;
}




///////////////////////////////////////////////////////////////////////////
//
// End of Move
//
//////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////
//
// expectedMaturityAt
//
////////////////////////////////////////////////
- (double) expectedMaturityAt: (FishCell *) aCell 
{ 
  double weightAtTForCell;
  double lengthAtTForCell; 
  double conditionAtTForCell; 
  double fracMatureAtTForCell; 
  double T;                    //fishFitnessHorizon
  double Kt, KT, a, b;
  double starvSurvival;
  double expectedMaturityAtACell = 0.0;
  double totalNonStarvSurv = 0.0;

  T = fishParams->fishFitnessHorizon;

  if(aCell == nil)
  {
     fprintf(stderr, "ERROR: Trout >>>> expectedMaturityAt >>>> aCell = nil\n");
     fflush(0);
     exit(1);
  }
  
  netEnergyForCell = [self calcNetEnergyForCell: aCell];
  weightAtTForCell = [self getWeightWithIntake: (T * netEnergyForCell) ]; 
  lengthAtTForCell = [self getLengthForNewWeight: weightAtTForCell];
  conditionAtTForCell = [self getConditionForWeight: weightAtTForCell andLength: lengthAtTForCell];

  fracMatureAtTForCell = [self getFracMatureForLength: lengthAtTForCell];

  //
  // The following variables: maxSwimSpeedForCell, feedTimeForCell, 
  // depthLengthRatioForCell are set here because the depend on
  // both cell and fish. They are then used by the
  // survivalManager via fish get methods.
  //
  maxSwimSpeedForCell = [self calcMaxSwimSpeedAt: aCell];
  feedTimeForCell = [self calcFeedTimeAt: aCell];
  depthLengthRatioForCell = [self calcDepthLengthRatioAt: aCell];

  //
  // Now update the survival manager...
  //
  [aCell updateFishSurvivalProbFor: self];

   //fprintf(stdout, "Trout >>>> expectedMaturityAt >>>> fishCondition = %f\n", fishCondition);
   //fprintf(stdout, "Trout >>>> expectedMaturityAt >>>> conditionAtTForCell = %f\n", conditionAtTForCell);
   //fprintf(stdout, "Trout >>>> expectedMaturityAt >>>> starvPa = %f\n", starvPa);
   //fprintf(stdout, "Trout >>>> expectedMaturityAt >>>> starvPb = %f\n", starvPb);
   //fflush(0);

  if(fabs(fishCondition - conditionAtTForCell) < 0.001) 
  {
      starvSurvival = [aCell getStarvSurvivalFor: self];
  }
  else 
  {
     a = starvPa; 
     b = starvPb; 
     Kt = fishCondition;  //current fish condition
     KT = conditionAtTForCell;
     starvSurvival =  (1/a)*(log((1+exp(a*KT+b))/(1+exp(a*Kt+b))))/(KT-Kt); 
  }  

  if(isnan(starvSurvival) || isinf(starvSurvival))
  {
     fprintf(stderr, "ERROR: Trout >>>> expectedMaturityAt >>>> starvSurvival = %f\n", starvSurvival);
     fflush(0);
     exit(1);
  }

  totalNonStarvSurv = [aCell getTotalKnownNonStarvSurvivalProbFor: self];

  if(isnan(totalNonStarvSurv) || isinf(totalNonStarvSurv))
  {
     fprintf(stderr, "ERROR: Trout >>>> expectedMaturityAt >>>> totalNonStarvSurv = %f\n", totalNonStarvSurv);
     fflush(0);
  }

  expectedMaturityAtACell = fracMatureAtTForCell * pow((starvSurvival * totalNonStarvSurv), T);
  if(isnan(expectedMaturityAtACell) || isinf(expectedMaturityAtACell))
  {
     fprintf(stderr, "ERROR: Trout >>>> expectedMaturityAt >>>> expectedMaturityAtACell = %f\n", expectedMaturityAtACell);
     fflush(0);
     exit(1);
  }

  if(expectedMaturityAtACell < 0.0)
  {
     fprintf(stderr, "ERROR: Trout >>>> expectedMaturityAt >>>> expectedMaturityAtACell = %f is less than ZERO\n", expectedMaturityAtACell);
     fflush(0);
     exit(1);
  }

  return expectedMaturityAtACell;
}

//////////////////////////////////////////////////
//
// calcStarvPaAndPb
//
/////////////////////////////////////////////////
- calcStarvPaAndPb
{

  double x1 = fishParams->mortFishConditionK1;
  double x2 = fishParams->mortFishConditionK9;

  double y1 = 0.1;
  double y2 = 0.9;

  double u, v;

  if(x1 == x2)
  {
      fprintf(stderr, "Trout >>>> calcStarvPaAndPb... >>>> the independent variables mortFishConditionK1 and mortFishConditionK9 are equal\n");
      fflush(0);
      exit(1);
  }
  if((y1 >= 1.0) || (y1 <= 0.0) || (y2 <= 0.0) || (y2 >= 1.0) || (y1 == y2))
  {
      fprintf(stderr, "ERROR: Trout >>>> calcStarvPaAndPb... >>>> the dependent variables UPPER_LOGISTIC_DEPENDENT or LOWER_LOGISTIC_DEPENDENT incorrect\n");
      fflush(0);
      exit(1);
  }


  u = log(y1/(1.0-y1));
  v = log(y2/(1.0-y2));

  starvPa = (u - v)/(x1-x2);
  starvPb = u - starvPa*x1;

  //fprintf(stdout, "Trout >>>> calcStarvPaAndPb >>>> starvPa = %f starvPb = %f\n", starvPa, starvPb);
  //fflush(0);

  return self;

}


//////////////////////////////////////////////////////////////////
//
// grow  
//
// Grow is the third action taken by fish in their daily routine 
//
/////////////////////////////////////////////////////////////////
- grow 
{
  //
  // if we are already dead -- or outmigrated --
  // just return. Important to keep outmigrated fish from growing into
  // the next (wrong) size class.

  if(causeOfDeath != nil) return self;

  prevWeight = fishWeight;
  prevLength = fishLength;
  prevCondition = fishCondition;

  fishWeight = [self getWeightWithIntake: netEnergyForBestCell];
  fishLength = [self getLengthForNewWeight: fishWeight];
  fishCondition = [self getConditionForWeight: fishWeight andLength: fishLength];
  fishFracMature = [self getFracMatureForLength: fishLength];
  if(fishLength > prevLength)
  {
   fishWeightAtK1 = (fishParams->fishWeightParamA) * pow(fishLength, fishParams->fishWeightParamB);
  }
  return self;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// die
// Comment: Die is the fourth action taken by fish in their daily routine 
//
////////////////////////////////////////////////////////////////////////////////////////
- die 
{

    if(imImmortal == YES)
    {
        return self;
    }

    //
    // if we are already dead 
    // just return
    //
    if(causeOfDeath) return self;

    //
    // Survival Manager code
    //
    {
       id <List> listOfSurvProbs;
       id <ListIndex> lstNdx;
       id <SurvProb> aProb;
       
       [myCell updateFishSurvivalProbFor: self];
       
       listOfSurvProbs = [myCell getListOfSurvProbsFor: self]; 

       lstNdx = [listOfSurvProbs listBegin: scratchZone];
     
       while(([lstNdx getLoc] != End) && ((aProb = [lstNdx next]) != nil))
       {
            if([unifDist getDoubleSample] > [aProb getSurvivalProb]) 
            {
                 char* deathName = (char *) [[aProb getProbSymbol] getName];
                 size_t strLen = strlen(deathName) + 1;
                 causeOfDeath = [aProb getProbSymbol];
                 deathCausedBy = (char *) [troutZone alloc: strLen*sizeof(char)];
                 strncpy(deathCausedBy, deathName, strLen);
                 deadOrAlive = "DEAD";
                 timeOfDeath = [self getCurrentTimeT]; 
                 [model addToKilledList: self ];
                 [myCell removeFish: self];
                 
                 //
                 // I don't think we want to kill a fish
                 // more than once so ...
                 //
                 break;
            }
      }
      [lstNdx drop];
  }

  return self;
}

////////////////////////////////////////////////////////
//
// killFish AKA
// deathByDemonicIntrusion
//
////////////////////////////////////////////////////////
- killFish 
{
    causeOfDeath = [model getFishMortalitySymbolWithName: "DemonicIntrusion"];
    deathCausedBy = "DemonicIntrusion";
    deadOrAlive = "DEAD";
    timeOfDeath = [self getCurrentTimeT]; 
    [model addToKilledList: self ];
    [myCell removeFish: self];

    return self;
}



///////////////////////////////////////////////
//
// getCauseOfDeath
//
//////////////////////////////////////////
- (id <Symbol>) getCauseOfDeath 
{
   return causeOfDeath;
}

//////////////////////////////////////////////////
//
// getTimeOfDeath
//
/////////////////////////////////////////////////
- (time_t) getTimeOfDeath 
{
  return timeOfDeath;
}


///////////////////////////////////////////////////////////////////////////////
//
// compare
// Needed by QSort in TroutModelSwarm method: buildTotalTroutPopList
//
///////////////////////////////////////////////////////////////////////////////
- (int) compare: (Trout *) aFish 
{
  double otherFishLength = [aFish getFishLength];

  if(fishLength > otherFishLength)
  {
    return 1;
  }
  else if (fishLength == otherFishLength)
  {
    return 0;
  }
  else
  {
    return -1;
  }
}


////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
//
//FISH FEEDING AND ENERGETICS
//
///////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

// ACTIVITY BUDGET

/////////////////////////////////////////
//
// calcFeedTimeAt
//
/////////////////////////////////////////
- (double) calcFeedTimeAt: (FishCell *) aCell 
{
   double aFeedTime;

   aFeedTime = [aCell getDayLength] + 2.0;

   //
   // Commented out 10/13/06 SKJ
   //
   //if([aCell getTemperature] < fishParams->fishMinFeedTemp)
   //{
      //aFeedTime = 0.0;
   //}

   return aFeedTime;
}



////////////////////////////////////////////////
//
//
// FOOD INTAKE: DRIFT FEEDING STRATEGY
//
//
////////////////////////////////////////////////

//////////////////////////////////////////////////////////////
//
// calcDetectDistanceAt
//
// We do this for each cell because a fish may be looking 
// at cell that is in a reach different than the one a fish
// is currently in
//
// Modified 12/24/04 SFR to make detectDist a linear
// function of fish length
// fishDetectDistParamA is the constant;
// fishDetectDistParamB is the slope
//
//////////////////////////////////////////////////////////////
- (double)  calcDetectDistanceAt: (FishCell *) aCell
{
   double habTurbidity;
   double turbidityFunction = 1.0;
   double aDetectDistance;
   double expFunction = -LARGEINT;
   double fishTurbidThreshold = fishParams->fishTurbidThreshold;

   if(aCell == nil)
   {
      fprintf(stderr, "ERROR: Trout >>>> calcDetectDistance >>>> aCell is nil\n");
      fflush(0);
      exit(1);
   }

   //
   // getTurbidity is a pass through to the habitatSpace 
   //
   habTurbidity = [aCell getTurbidity];

   //
   // The following if block modified 4/13/06 SKJ
   //
   if(habTurbidity > fishTurbidThreshold)
   {
      expFunction = exp(fishParams->fishTurbidExp * (habTurbidity - fishTurbidThreshold));
      
      turbidityFunction = (expFunction >= fishParams->fishTurbidMin) ? expFunction 
                                                                     : fishParams->fishTurbidMin;
   }

   aDetectDistance =   (fishParams->fishDetectDistParamA 
                     + (fishLength * fishParams->fishDetectDistParamB))
                     * turbidityFunction;
 
   return aDetectDistance;
}


///////////////////////////////////////////
//
// calcCaptureArea
//
//////////////////////////////////////////
- (double) calcCaptureArea: (FishCell *) aCell 
{
   double aCaptureArea;
   double depth;
   double minValue=0.0;
   //double aDetectDistance = [self calcDetectDistanceAt: aCell];

   depth = [aCell getPolyCellDepth];
   minValue = (detectDistance < depth) ? detectDistance : depth;
   aCaptureArea = 2.0*detectDistance*minValue;

   return aCaptureArea;
}


///////////////////////////////////////////////
//
// calcCaptureSuccess
//
//////////////////////////////////////////////
- (double) calcCaptureSuccess: (FishCell *) aCell
{
   double aCaptureSuccess;
   double velocity = 0.0;
   double aMaxSwimSpeed = [self calcMaxSwimSpeedAt: aCell];
   
   if(captureLogistic == nil)
   {
      fprintf(stderr, "ERROR: Trout >>>> calcCaptureSuccess >>>> captureLogistic is nil\n");
      fflush(0);
      exit(1);
   }

   if(aCell == nil)
   {
      fprintf(stderr, "ERROR: Trout >>>> calcCaptureSuccess >>>> aCell is nil\n");
      fflush(0);
      exit(1);
   }

   velocity = [aCell getPolyCellVelocity];

   aCaptureSuccess = [captureLogistic evaluateFor: (velocity/aMaxSwimSpeed)];

   return aCaptureSuccess;
}
 

/////////////////////////////////
//
// calcDriftIntake
// Comment: Intake = hourly rate 
//
/////////////////////////////////
- (double) calcDriftIntake: (FishCell *) aCell 
{
  double aDriftIntake;
  double aCaptureArea;
  double aCaptureSuccess;

  aCaptureArea = [self calcCaptureArea: aCell];
  aCaptureSuccess = [self calcCaptureSuccess: aCell];


  aDriftIntake =   [aCell getHabDriftConc] 
                 * [aCell getPolyCellVelocity]
                 * aCaptureArea 
                 * aCaptureSuccess
                 * 3600.0;

  return aDriftIntake;

}



///////////////////////////////////////////
//
//
//FOOD INTAKE: ACTIVE SEARCHING STRATEGY
//
//
///////////////////////////////////////////

////////////////////////////////////////////////
//
// calcMaxSwimSpeedAt
//
// This is done for each cell since fish may be
// considering cells that are different reaches.
//
////////////////////////////////////////////////
- (double) calcMaxSwimSpeedAt: (FishCell *) aCell 
{
  double fMSPA = fishParams->fishMaxSwimParamA;
  double fMSPB = fishParams->fishMaxSwimParamB;
  double fMSPC = fishParams->fishMaxSwimParamC;
  double fMSPD = fishParams->fishMaxSwimParamD;
  double fMSPE = fishParams->fishMaxSwimParamE;
  double T = [aCell getTemperature];
  double aMaxSwimSpeed;

  //fprintf(stdout, "Trout >>>> calcMaxSwimSpeedAt >>>> temperature = %f \n", T);
  //fflush(0);
 


  aMaxSwimSpeed =   (fMSPA*fishLength + fMSPB)
                 * (fMSPC*T*T + fMSPD*T + fMSPE);

  if(aMaxSwimSpeed <= 0.0)
  {
      fprintf(stderr, "ERROR: Trout >>>> calcMaxSwimSpeed >>>> aMaxSwimSpeed is less than or equal to 0\n");
      fflush(0); 
      exit(1); 
  }

  return aMaxSwimSpeed;
} 



///////////////////////////////////////////
//
//calcSearchIntake
//
///////////////////////////////////////////
- (double) calcSearchIntake: (FishCell *) aCell 
{
  double aSearchIntake;
  double fSA;
  double velocity=0.0;
  double habSearchProd=0.0;
  double aMaxSwimSpeed;
  
  if ([aCell getPolyCellDepth] <= 0.0)
  {
     return 0.0;
  }

  else
 {
  aMaxSwimSpeed = [self calcMaxSwimSpeedAt: aCell];
  fSA = fishParams->fishSearchArea;

  velocity = [aCell getPolyCellVelocity];
  habSearchProd = [aCell getHabSearchProd];
 
  if(velocity > aMaxSwimSpeed) 
  {
     aSearchIntake = 0.0;
  }
  else 
  {
     aSearchIntake = habSearchProd * fSA * (aMaxSwimSpeed - velocity)/aMaxSwimSpeed;
  }

  return aSearchIntake;
 }
}


///////////////////////////////////////
//
//
//FOOD INTAKE: MAXIMUM CONSUMPTION
//
//
///////////////////////////////////////

////////////////////////////////////////////
//
//calcCmax
//
////////////////////////////////////////////
- (double) calcCmax: (double) aTemperature 
{
  double aCmax;
  double fCPA,fCPB;
  double cmaxTempFunction;

  fCPA = fishParams->fishCmaxParamA;
  fCPB = fishParams->fishCmaxParamB;

  cmaxTempFunction = [cmaxInterpolator getValueFor: aTemperature];

  aCmax = fCPA * pow(fishWeight,(1+fCPB)) * cmaxTempFunction;

   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_FEEDING
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<<METHOD: calcCMax speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"fishCmaxParamA = %f\n", fishParams->fishCmaxParamA);
       fprintf(stderr,"fishCmaxParamB = %f\n", fishParams->fishCmaxParamB);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif

  if(aCmax < 0.0)
  {
      fprintf(stderr, "ERROR: Trout >>>> calcCmax >>>> Negative cMax calculated\n");
      fflush(0);
      exit(1);
  }


  return aCmax;
}

///////////////////////////////////////////////
//
// FOOD INTAKE: FOOD AVAILABILITY
//
///////////////////////////////////////////////


//
// RESPIRATION COSTS
//
///////////////////////////////////////////////////
//
// calcStandardRespirationAt
//
///////////////////////////////////////////////////
- (double) calcStandardRespirationAt: (FishCell *) aCell
{
  double temperature;
  double aStandardResp;

  if(aCell == nil)
  {
     fprintf(stderr, "ERROR: Trout >>>> calcStandardRespirationAt >>>> aCell is nil\n");
     fflush(0);
     exit(1);
  }

  temperature = [aCell getTemperature];

  aStandardResp =   fishParams->fishRespParamA
                  * pow(fishWeight, fishParams->fishRespParamB) 
                  * exp(fishParams->fishRespParamC * temperature);

  return aStandardResp;
}

  

//////////////////////////////////////////////////////////////////////////////////
//
//calcActivityRespiration
//
///////////////////////////////////////////////////////////////////////////////////
- (double) calcActivityRespirationAt: (FishCell *) aCell withSwimSpeed: (double) aSpeed 
{
  double aRespActivity;
  double aFeedTime;

  //fprintf(stdout, "Trout >>>> calcActivityRespirationAt >>>> BEGIN\n");
  //fflush(0); 

  aFeedTime = [self calcFeedTimeAt: aCell];  

  if(aSpeed > 0.0) 
  {
     aRespActivity = (aFeedTime/24) * (exp(fishParams->fishRespParamD*aSpeed) - 1.0) * standardResp;
  }
  else 
  {
     aRespActivity = 0.0; 
  }

  //fprintf(stdout, "Trout >>>> calcActivityRespirationAt >>>> aFeedTime = %f\n", aFeedTime);
  //fprintf(stdout, "Trout >>>> calcActivityRespirationAt >>>> aRespActivity = %f\n", aRespActivity);
  //fflush(0); 

  //fprintf(stdout, "Trout >>>> calcActivityRespirationAt >>>> END\n");
  //fflush(0); 

  return aRespActivity;

}



//////////////////////////////////////////////////////////////////////////////
//
// calcTotalRespirationAt
//
//////////////////////////////////////////////////////////////////////////////
- (double) calcTotalRespirationAt: (FishCell *) aCell withSwimSpeed: (double) aSpeed 
{
  return [self calcActivityRespirationAt: aCell withSwimSpeed: aSpeed] + standardResp;
}


///////////////////////////////////////////////////////////////
//
//
// FEEDING STRATEGY SELECTION, NET ENERGY BENEFITS, AND GROWTH
//
////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//
//calcDailyDriftFoodIntake
//
/////////////////////////////////////////////////////
- (double) calcDailyDriftFoodIntake: (FishCell *) aCell 
{
   double aDailyPotentialDriftFood;
   double aDailyDriftFoodIntake = 0.0;
   double aDailyAvailableFood;

   //fprintf(stdout, "Trout >>>> calcDailyDriftFoodIntake >>>> BEGIN\n");
   //fflush(0);


   aDailyPotentialDriftFood = [self calcDriftIntake: aCell] * [self calcFeedTimeAt: aCell];
   aDailyAvailableFood = [aCell getHourlyAvailDriftFood] * [self calcFeedTimeAt: aCell]; 
 

   //
   //aDailyDriftFoodIntake is the minimum of aDailyPotentialFood, aDailyAvailbleFood, and cMax
   //

   aDailyDriftFoodIntake = aDailyPotentialDriftFood;
 
   if(aDailyAvailableFood < aDailyDriftFoodIntake)
   {
       aDailyDriftFoodIntake = aDailyAvailableFood;
   }

   if(cMax < aDailyDriftFoodIntake)
   {
      aDailyDriftFoodIntake = cMax;
   }

   /*
   fprintf(stdout, "Trout >>>> calcDailyDriftFoodIntake >>>> aDailyPotentialDriftFood = %f\n", aDailyPotentialDriftFood);
   fprintf(stdout, "Trout >>>> calcDailyDriftFoodIntake >>>> aDailyAvailableFood = %f\n", aDailyPotentialDriftFood);
   fprintf(stdout, "Trout >>>> calcDailyDriftFoodIntake >>>> aDailyDriftFoodIntake = %f\n", aDailyDriftFoodIntake);
   fprintf(stdout, "Trout >>>> calcDailyDriftFoodIntake >>>> cMax = %f\n", cMax);
   fflush(0);
   */

   //fprintf(stdout, "Trout >>>> calcDailyDriftFoodIntake >>>> END\n");
   //fflush(0);

   return aDailyDriftFoodIntake; 
}


////////////////////////////////////////////////////
//
//calcDailyDriftNetEnergy
//
////////////////////////////////////////////////////
- (double) calcDailyDriftNetEnergy: (FishCell *) aCell 
{
  double aDailyDriftNetEnergy;   
 
  aDailyDriftNetEnergy = ( [self calcDailyDriftFoodIntake: aCell] * [aCell getHabPreyEnergyDensity] )
                         - [self calcTotalRespirationAt: aCell withSwimSpeed:
                           [self getSwimSpeedAt: aCell forStrategy: DRIFT] ];

  return aDailyDriftNetEnergy;
}

/////////////////////////////////////////
//
//getSwimSpeedAt
//
///////////////////////////////////////
- (double) getSwimSpeedAt: (FishCell *) aCell forStrategy: (int) aFeedStrategy 
{
 
  if(([aCell getIsShelterAvailable] == YES) && (aFeedStrategy == DRIFT)) 
  {
      return ([aCell getPolyCellVelocity] * [aCell getHabShelterSpeedFrac]); 
  }
  else 
  {
     return [aCell getPolyCellVelocity];
  }

}


/////////////////////////////
//
// getAmIInAShelter
// 
/////////////////////////////
- (BOOL) getAmIInAShelter 
{
   return velocityShelter;
}



/////////////////////////////////////////////////////
//
//calcDailySearchFoodIntake
//
/////////////////////////////////////////////////////
- (double) calcDailySearchFoodIntake: (FishCell *) aCell 
{
   double aDailyPotentialSearchFood;
   double aDailySearchFoodIntake = 0.0;
   double aDailyAvailableSearchFood;
   //double aCmax;

   //aCmax = [self calcCmax: [aCell getTemperature]];

   aDailyPotentialSearchFood = [self calcSearchIntake: aCell] * [self calcFeedTimeAt: aCell];
   aDailyAvailableSearchFood = [aCell getHourlyAvailSearchFood] * [self calcFeedTimeAt: aCell];
 
   //
   // aDailySearchFoodIntake is the minimum 
   // of aDailyPotentialSearchFood, aDailyAvailableSearchFood, cMax
   //
   aDailySearchFoodIntake = aDailyPotentialSearchFood;
 
   if(aDailyAvailableSearchFood < aDailySearchFoodIntake) 
   {
      aDailySearchFoodIntake = aDailyAvailableSearchFood;
   }
   if(cMax < aDailySearchFoodIntake) 
   {
      aDailySearchFoodIntake = cMax;
   }

   return aDailySearchFoodIntake;
}




//////////////////////////////////////////////////
//
//calcDailySearchNetEnergy
//
//////////////////////////////////////////////////
- (double) calcDailySearchNetEnergy: (FishCell *) aCell 
{
   double aDailySearchNetEnergy;   

   aDailySearchNetEnergy = ([self calcDailySearchFoodIntake: aCell] * [aCell getHabPreyEnergyDensity] )
                          - [self calcTotalRespirationAt: aCell withSwimSpeed: [self getSwimSpeedAt: aCell forStrategy: SEARCH]];

   return aDailySearchNetEnergy;
}


/////////////////////////////////////////////////
//
//calcNetEnergyForCell
//
////////////////////////////////////////////////
- (double) calcNetEnergyForCell: (FishCell *) aCell 
{
   double aNetEnergy=0.0;
   double aDailySearchNetEnergy, aDailyDriftNetEnergy;

   aDailyDriftNetEnergy = [self calcDailyDriftNetEnergy: aCell];
   aDailySearchNetEnergy = [self calcDailySearchNetEnergy: aCell];
   
 //
 // Select the most profitable feeding strategy
 //
   if(aDailyDriftNetEnergy >= aDailySearchNetEnergy) 
   {
      aNetEnergy = aDailyDriftNetEnergy;
      cellFeedingStrategy = DRIFT;
   }
   else 
   {
      aNetEnergy = aDailySearchNetEnergy;
      cellFeedingStrategy = SEARCH;
   }   

   //
   // cellSwimSpeedForCell is used by hi velocity survival
   //
   cellSwimSpeedForCell = [self getSwimSpeedAt: aCell forStrategy: cellFeedingStrategy];   
  
   return aNetEnergy;
}




   
- (int) getFishFeedingStrategy 
{
  return fishFeedingStrategy;
}

- (double) getHourlyDriftConRate 
{
   return hourlyDriftConRate;
}

- (double) getHourlySearchConRate 
{
   return  hourlySearchConRate;
}




///////////////////////////////////////////////////
//
// calcMaxMoveDistance
//
///////////////////////////////////////////////////
- calcMaxMoveDistance 
{

  maxMoveDistance =   fishParams->fishMoveDistParamA
                    * pow(fishLength, fishParams->fishMoveDistParamB);


   #ifdef DEBUG_TROUT_FISHPARAMS
     #ifdef DEBUG_MOVE
   
       fprintf(stderr,"\n");
       fprintf(stderr,"<<<<<METHOD: calcMaxMoveDistance speciesNdx = %d >>>>>\n", speciesNdx);
       xprint(self);
       fprintf(stderr,"fishMoveDistParamA = %f\n", fishParams->fishMoveDistParamA);
       fprintf(stderr,"fishMoveDistParamB = %f\n", fishParams->fishMoveDistParamB);
       fprintf(stderr,"\n"); 
    
     #endif
   #endif

  return self;
}


///////////////////////////////////////////////
//
// tagFishDestCells
//
///////////////////////////////////////////////
- tagCellsICouldMoveTo
{
   id <ListIndex> cellNdx;
   id nextCell=nil;

   if(tagDestCellList == nil)
    {
        tagDestCellList = [List create: troutZone];
    }

    [tagDestCellList removeAll];

    [myCell getNeighborsWithin: maxMoveDistance
                      withList: tagDestCellList];

    cellNdx = [tagDestCellList listBegin: scratchZone];

    while(([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil)) 
    {
         [nextCell tagPolyCell];
    } 

    [model updateTkEventsFor:reach];

    [cellNdx drop];

    return self;
}

///////////////////////////////
//
// makeMeImmortal
//
//////////////////////////////
- makeMeImmortal
{
   if(imImmortal == NO)
   {
       imImmortal = YES;
   }

   return self;
}


///////////////////////////////////////////////////////////////
//
// moveReport
//
//////////////////////////////////////////////////////////////
- moveReport: (FishCell *) aCell {
  FILE *mvRptPtr=NULL;
  const char *mvRptFName = "Move_Test_Out.csv";
  static BOOL moveRptFirstTime=YES;     
  double velocity, depth, temp, turbidity, availableDrift, availableSearch;
  double distToHide;
  double piscivDensity;
  char *mySpecies;
  char *fileMetaData;
  char strDataFormat[150];

  velocity = [aCell getPolyCellVelocity];
  depth    = [aCell getPolyCellDepth];
  temp    = [aCell getTemperature];
  turbidity = [aCell getTurbidity];
  availableDrift = [aCell getHourlyAvailDriftFood];
  availableSearch = [aCell getHourlyAvailSearchFood];

  distToHide = [aCell getDistanceToHide];
  piscivDensity = [aCell getPiscivorousFishDensity];

  mySpecies = (char *)[[self getSpecies] getName];

  if(moveRptFirstTime == YES){
     if((mvRptPtr = fopen(mvRptFName,"w+")) != NULL){
       fileMetaData = [BreakoutReporter reportFileMetaData: scratchZone];
       fprintf(mvRptPtr,"\n%s\n\n",fileMetaData);
       [scratchZone free: fileMetaData];
       fprintf(mvRptPtr,"%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,\n",
                                                           "DATE",
							   "FISH-ID",
							   "SPECIES",
							   "AGE",
							   "PrevREACH",
							   "REACH",
							   "PrevCELL",
							   "CELL",
                                                          "VELOCITY",
                                                          "DEPTH",
                                                          "TEMP",
                                                           "TURBIDITY",
                                                          "DIST_HIDE",
                                                          "PISC_DENSITY",
                                                          "AVAIL_DRIFT",
                                                          "AVAIL_SEARCH",
                                                          "fishLength",
                                                          "fishWeight",
                                                          "feedTime",
                                                          "captureSuccess",
                                                          "potHDIntake",
                                                          "potHSIntake",
                                                          "cMax",
                                                          "standardResp",
                                                          "activeResp",
                                                          "inShelter",
                                                          "dailyDrftNetEn",
                                                          "dailySchNetEn",
                                                          "feedStrategy",
                                                          "nonStarvSurv",
                                                          "ntEnrgyFrBstCll",
                                                          "ERMForBestCell");
         fflush(mvRptPtr);
         moveRptFirstTime = NO;
         fclose(mvRptPtr);
     }else{
         fprintf(stderr, "ERROR: Trout >>>> moveReport >>>> Cannot open %s for writing\n", mvRptFName);
         fflush(0);
         exit(1);
     }
  }

  if((mvRptPtr = fopen(mvRptFName,"a")) == NULL){
      fprintf(stderr, "ERROR: Trout >>>> moveReport >>>> Cannot open %s for appending\n", mvRptFName);
      fflush(0);
      exit(1);
  }

  strcpy(strDataFormat,"%s,%d,%s,%d,%s,%s,%d,%d,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%E,%s,%E,%E,%s,%E,%E,%E\n");
  fprintf(mvRptPtr, strDataFormat,[timeManager getDateWithTimeT: [self getCurrentTimeT]],
                                fishID,
				mySpecies,
				age,
				[prevReach getReachName],
				[[aCell getReach] getReachName],
				[prevCell getPolyCellNumber],
				[aCell getPolyCellNumber],
                                velocity,
                                depth,
                                temp,
                                turbidity,
                                distToHide,
                                piscivDensity,
                                availableDrift,
                                availableSearch,
                                fishLength,
                                fishWeight,
                                feedTimeForCell,
                                captureSuccess,
                                potentialHourlyDriftIntake,
                                potentialHourlySearchIntake,
                                cMax,
                                standardResp,
                                activeResp,
                                inShelter,
                                dailyDriftNetEnergy,
                                dailySearchNetEnergy,
                                feedStrategy,
                                nonStarvSurvival,
                                netEnergyForBestCell,
                                expectedMaturity);


  fflush(mvRptPtr);
  fclose(mvRptPtr);
  return self;
}


///////////////////////////////////////////////////////////
//
// printReadyToSpawnRpt
//
///////////////////////////////////////////////////////////
- printReadyToSpawnRpt: (BOOL) readyToSpawn 
{
  FILE * spawnReportPtr=NULL; 
  const char* readyToSpawnFile = "Ready_To_Spawn_Out.csv"; 
  static BOOL firstRTSTime=YES;
  char* readyTSString = "NO";
  time_t currentTime = (time_t) 0;
  double currentTemp;
  double currentFlow;
  double currentFlowChange;
  char *lastSpawnDate = (char *) NULL;  
  char strDataFormat[150];
  char *fileMetaData;

  if(readyToSpawn == YES) readyTSString = "YES";

   if(firstRTSTime == YES){
     if( (spawnReportPtr = fopen(readyToSpawnFile,"w+")) == NULL){
          fprintf(stderr, "ERROR: Trout >>>> printReadyToSpawnRpt >>>> Cannot open %s for writing",readyToSpawnFile);
          fflush(0);
          exit(1);
     }
       fileMetaData = [BreakoutReporter reportFileMetaData: scratchZone];
       fprintf(spawnReportPtr,"\n%s\n\n",fileMetaData);
       [scratchZone free: fileMetaData];
      fprintf(spawnReportPtr,"%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n","Date",
                                                                            "Species",
                                                                            "Age",
                                                                            "Sex",
                                                                            "Reach",
                                                                            "Temperature",
                                                                            "Flow",
                                                                            "FlowChange",
                                                                            "FishLength",
                                                                            "Condition",
                                                                            "LastSpawnDate",
                                                                            "FishSpawnStartDate",
                                                                            "FishSpawnEndDate",
                                                                            "ReadyToSpawn");
  }else if(firstRTSTime == NO){
     if( (spawnReportPtr = fopen(readyToSpawnFile,"a")) == NULL){
          fprintf(stderr, "ERROR: Trout >>>> printReadyToSpawnRpt >>>> Cannot open %s for writing",readyToSpawnFile);
          fflush(0);
          exit(1);
      }
  }
  lastSpawnDate = [[self getZone] alloc: 12*sizeof(char)];
  currentTemp = [myCell getTemperature];
  currentTime = [self getCurrentTimeT];
  currentFlow = [myCell getRiverFlow];
  currentFlowChange = [myCell getFlowChange];

  if(timeLastSpawned > (time_t) 0 ){
    strncpy(lastSpawnDate, [timeManager getDateWithTimeT: timeLastSpawned], 12);
  }else{
     strncpy(lastSpawnDate, "00/00/0000", (size_t) 12);
  }
  strcpy(strDataFormat,"%s,%s,%d,%s,%s,%E,%E,%E,%E,%E,%s,%s,%s,%s\n");
  //pretty print
  //strcpy(strDataFormat,"%s,%s,%d,%s,%s,");
  //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: currentTemp]);
  //strcat(strDataFormat,",");
  //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: currentFlow]);
  //strcat(strDataFormat,",");
  //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: currentFlowChange]);
  //strcat(strDataFormat,",");
  //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: fishLength]);
  //strcat(strDataFormat,",");
  //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: fishCondition]);
  //strcat(strDataFormat,",%s,%s,%s,%s\n");

  fprintf(spawnReportPtr,strDataFormat,[timeManager getDateWithTimeT: currentTime],
                                       [species getName],
                                       age,
                                       [sex getName],
                                       [reach getReachName],
                                       currentTemp,
                                       currentFlow,
                                       currentFlowChange,
                                       fishLength,
                                       fishCondition,
                                       lastSpawnDate,
                                       fishParams->fishSpawnStartDate,
                                       fishParams->fishSpawnEndDate,
                                       readyTSString);


   firstRTSTime = NO;
   fclose(spawnReportPtr);
   return self;
} 


/////////////////////////////////////////////////
//
// printSpawnCellRpt
//
/////////////////////////////////////////////////
- printSpawnCellRpt: (id <List>) spawnCellList 
{
  FILE * spawnCellRptPtr=NULL;
  const char * spawnCellFile = "Spawn_Cell_Out.csv";
  static BOOL spawnCellFirstTime = YES;
  char strDataFormat[150];
  double cellDepth,cellVelocity,cellArea,fracSpawn,depthSuit,velSuit,spawnQuality;
  char * fileMetaData;

  id <ListIndex> cellListNdx=nil;
  id  aCell=nil;

  if(spawnCellFirstTime == YES){
      if((spawnCellRptPtr = fopen(spawnCellFile,"w+")) == NULL){
          fprintf(stderr, "ERROR: Trout >>>> printSpawnCellRpt >>>> Cannot open report file %s for writing", spawnCellFile);
          fflush(0);
          exit(1);
      }
       fileMetaData = [BreakoutReporter reportFileMetaData: scratchZone];
       fprintf(spawnCellRptPtr,"\n%s\n\n",fileMetaData);
       [scratchZone free: fileMetaData];
      fprintf(spawnCellRptPtr,"%s,%s,%s,%s,%s,%s,%s,%s,\n","FishID",
                                                           "Depth",
                                                           "Velocity",
                                                           "Area",
                                                           "fracSpawn",
                                                           "DepthSuit",
                                                           "VelSuit",
                                                           "spawnQuality");
  }
  if(spawnCellFirstTime == NO){
	if((spawnCellRptPtr = fopen(spawnCellFile,"a")) == NULL) 
	{
	    fprintf(stderr, "ERROR: Trout >>>> printSpawnCellRpt >>>> Cannot open report file %s for writing\n", spawnCellFile);
	    fflush(0);
	    exit(1);
	}
  }

  cellListNdx = [spawnCellList listBegin: [self getZone]];

  while(([cellListNdx getLoc] != End) && ((aCell = [cellListNdx next]) != nil)){
    cellDepth	  = [aCell getPolyCellDepth];
    cellVelocity  = [aCell getPolyCellVelocity];
    cellArea	  = [aCell getPolyCellArea];
    fracSpawn	  = [aCell getCellFracSpawn];
    depthSuit	  = [self getSpawnDepthSuitFor: [aCell getPolyCellDepth] ];
    velSuit	  = [self getSpawnVelSuitFor: [aCell getPolyCellVelocity]];
    spawnQuality  = [self getSpawnQuality: aCell];
    strcpy(strDataFormat,"%d,%E,%E,%E,%E,%E,%E,%E\n");
    //pretty print
    //strcpy(strDataFormat,"%p,");
    //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: cellDepth]);
    //strcat(strDataFormat,",");
    //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: cellVelocity]);
    //strcat(strDataFormat,",");
    //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: cellArea]);
    //strcat(strDataFormat,",");
    //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: fracSpawn]);
    //strcat(strDataFormat,",");
    //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: depthSuit]);
    //strcat(strDataFormat,",");
    //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: velSuit]);
    //strcat(strDataFormat,",");
    //strcat(strDataFormat,[BreakoutReporter formatFloatOrExponential: spawnQuality]);
    //strcat(strDataFormat,"\n");
    fprintf(spawnCellRptPtr,strDataFormat,fishID,
					  cellDepth, 
					  cellVelocity, 
					  cellArea, 
					  fracSpawn, 
					  depthSuit, 
					  velSuit, 
					  spawnQuality); 
  }  
  [cellListNdx drop];

  if(spawnCellRptPtr != NULL){
    fclose(spawnCellRptPtr);
  }
  spawnCellFirstTime = NO;
  return self;
}

- (void) drop {

     [unifDist drop]; 
     //[dieDist drop];

     [destCellList drop];
     destCellList = nil; 

     if(causeOfDeath != nil)
     {
         [troutZone free: deathCausedBy];
         deathCausedBy = NULL;
     }

     [troutZone drop];
     troutZone = nil;

     [super drop];
     self = nil;
}


@end



