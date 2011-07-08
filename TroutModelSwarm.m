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




#import <math.h>
#import <simtools.h>
#import <random.h>
#import "FishParams.h"
#import "TroutModelSwarm.h"

/*
@protocol Observer 
- (id <Raster>) getWorldRaster;
@end
*/


id <Symbol> *mySpecies;
id <Symbol> Female, Male;  // sex of fish
Class *MyTroutClass; 
char **speciesName;
char **speciesColor;

@implementation TroutModelSwarm

+ create: aZone 
{
  TroutModelSwarm* troutModelSwarm;

  troutModelSwarm = [super create: aZone];

  troutModelSwarm->popInitDate = (char *) nil;
  troutModelSwarm->observerSwarm = nil;
  troutModelSwarm->initialDay=YES;
  troutModelSwarm->updateFish=NO;
  troutModelSwarm->numberOfSpecies=0;
  troutModelSwarm->timeManager = nil;
  troutModelSwarm->fishColorMap = nil;

  troutModelSwarm->printFishParams = NO;

  troutModelSwarm->minSpeciesMinPiscLength = (double) LARGEINT; 


  return troutModelSwarm;

}



//////////////////////////////////////////////////////////////
//
// instantiateObjects
//
/////////////////////////////////////////////////////////////
- instantiateObjects 
{
   int numspecies;

   modelZone = [Zone create: globalZone];

  #ifdef DEBUG_TROUT_FISHPARAMS

     fprintf(stdout,"TroutModelSwarm instantiateObjects \n");
     fflush(0);

  #endif

  if(numberOfSpecies == 0)
  {
     fprintf(stderr, "ERROR: TroutModelSwarm >>>> instantiateObjects >>>> numberOfSpecies is zero\n"); 
     fflush(0);
     exit(1);
  }

  [self readSpeciesSetup];

  //
  // Create list of species symbols
  //
  mySpecies = (id *) [modelZone alloc: numberOfSpecies*sizeof(Symbol)];
  for(numspecies = 0; numspecies < numberOfSpecies; numspecies++ )
  {
     mySpecies[numspecies] = [Symbol create: modelZone setName: speciesName[numspecies] ];
  }

  speciesSymbolList = [List create: modelZone];
  for(numspecies = 0; numspecies < numberOfSpecies; numspecies++ )
  {
    [speciesSymbolList addLast: mySpecies[numspecies] ];
  }

  //
  // The mortality symbol lists
  // 
  listOfMortalityCounts = [List create: modelZone];

  fishMortSymbolList = [List create: modelZone];
  reddMortSymbolList = [List create: modelZone];

  [self getFishMortalitySymbolWithName: "DemonicIntrusion"];

  fishParamsMap = [Map create: modelZone];

  [self createFishParameters];
  [self findMinSpeciesPiscLength];

  //
  // To create additional age classes, add more symbols to this list.
  // Then modify the code in getAgeSymbolForAge 
  // that assigns symbols to fish.
  // 
  ageSymbolList = [List create: modelZone];

  Age0     = [Symbol create: modelZone setName: "Age0"];
  [ageSymbolList addLast: Age0];
  Age1     = [Symbol create: modelZone setName: "Age1"];
  [ageSymbolList addLast: Age1];
  Age2     = [Symbol create: modelZone setName: "Age2"];
  [ageSymbolList addLast: Age2];
  Age3Plus = [Symbol create: modelZone setName: "Age3Plus"];
  [ageSymbolList addLast: Age3Plus];


  reachSymbolList = [List create: modelZone];

  fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>> instantiateObjects >>>> BEFORE HabitatManager\n");
  fflush(0);

  habitatManager = [HabitatManager createBegin: modelZone];
  [habitatManager instantiateObjects];

  //
  // Moved to buildObjects
  //
  //[habitatManager  setPolyRasterResolution:  polyRasterResolution
                  //setPolyRasterResolutionX:  polyRasterResolutionX
                  //setPolyRasterResolutionY:  polyRasterResolutionY
                   //setRasterColorVariable:   polyRasterColorVariable
                          //setShadeColorMax:  shadeColorMax];

  [habitatManager setSiteLatitude: siteLatitude];
  [habitatManager createSolarManager];
  [habitatManager setModel: self];
  [habitatManager readReachSetupFile: "Reach.Setup"];
  [habitatManager setNumberOfSpecies: numberOfSpecies];
  [habitatManager setFishParamsMap: fishParamsMap];
  [habitatManager instantiateHabitatSpacesInZone: modelZone];

  fprintf(stdout, "TroutModelSwarm >>>> instantiateObjects >>>> AFTER HabitatManager\n");
  fflush(0);

  return self;

}

/////////////////////////////////////////////////////////////
//
// setPolyRasterResolution
//
/////////////////////////////////////////////////////////////
-   setPolyRasterResolutionX:  (int) aRasterResolutionX
    setPolyRasterResolutionY:  (int) aRasterResolutionY
  setPolyRasterColorVariable:  (char *) aRasterColorVariable
{
     polyRasterResolutionX = aRasterResolutionX;
     polyRasterResolutionY = aRasterResolutionY;
     strncpy(polyRasterColorVariable, aRasterColorVariable, 35);


     return self;
}

/////////////////////////////////////
//
// setObserverSwarm
//
////////////////////////////////////
- setObserverSwarm: anObserverSwarm
{
    observerSwarm = anObserverSwarm;
    return self;
}

//////////////////////////////////////////////////////////////////
//
// buildObjects
//
/////////////////////////////////////////////////////////////////
- buildObjectsWith: theColormaps
          andWith: (double) aShadeColorMax
{
  int genSeed;
  time_t newYearTime = (time_t) 0;

  fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> BEGIN\n");
  fflush(0);

  shadeColorMax = aShadeColorMax;

  firstTime = YES;

  if(popInitDate == (char *) nil) 
  {
     fprintf(stderr, "\n\nERROR: popInitDate is a NULL value\n"
                                "Check the \"Model Setup\" file\n"
                                "or the \"Experiment Setup\" file\n");
     fflush(0);
     exit(1);
  }



  //
  // if we're a sub-swarm, then run our super's buildObjects first
  //
  [super buildObjects];

  timeManager = [TimeManager create: modelZone
                      setController: self
                        setTimeStep: (time_t) 86400
             setCurrentTimeWithDate: runStartDate
                           withHour: 12
                         withMinute: 0
                         withSecond: 0];

 [timeManager setDefaultHour: 12
            setDefaultMinute: 0
            setDefaultSecond: 0];


 timeManager = [timeManager createEnd];

 runStartTime = [timeManager getTimeTWithDate: runStartDate];

 runEndTime = [timeManager getTimeTWithDate: runEndDate];

  modelDate = (char *) [modelZone alloc: 15*sizeof(char)];

  modelTime = runStartTime; 

  if(runStartTime > runEndTime)
  {
     fprintf(stderr, "ERROR: TroutModelSwarm >>>> buildObjects >>>> Check runStartDate and runEndDate in Model.Setup\n");
     fflush(0);
     exit(1);
  }

  //
  // set up the random number generator to be used throughout the model
  //
  if(replicate != 0) 
  {
      genSeed = randGenSeed * replicate;
  }
  else
  {
      genSeed = randGenSeed;
  }

  randGen = [MT19937gen create: modelZone 
              setStateFromSeed: genSeed];

  //
  // coinFlip used to decide the sex of a new fish
  //
  coinFlip = [RandomBitDist create: modelZone
                      setGenerator: randGen];

  //
  // Create the Classes that instantiate the fish
  //
  [self buildFishClass];

  numSimDays = [timeManager getNumberOfDaysBetween: runStartTime and: runEndTime] + 1;
  simCounter = 1;

  if(shuffleYears == YES)
  {
     //
     // Create the year shuffler and the data start and end times.
     //
     [self createYearShuffler];
      newYearTime = [yearShuffler checkForNewYearAt: modelTime];

      if (newYearTime != modelTime)
      {
         [timeManager setCurrentTime: newYearTime];
         modelTime = newYearTime;
      }
  }
  else
  {
      modelTime = runStartTime;
      dataStartTime = runStartTime;
      dataEndTime = runEndTime + 86400;
  }

  fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> scenario = %d\n", scenario);
  fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> replicate = %d\n", replicate);
  fflush(0);


  //
  // Create the space in which the fish will live
  //
  [habitatManager setTimeManager: timeManager];

  [habitatManager setModelStartTime: (time_t) runStartTime
                         andEndTime: (time_t) runEndTime];

  [habitatManager setDataStartTime: (time_t) dataStartTime
                        andEndTime: (time_t) dataEndTime];

  //
  // Moved from instantiateObjects 
  //
  [habitatManager setPolyRasterResolutionX:  polyRasterResolutionX
                  setPolyRasterResolutionY:  polyRasterResolutionY
                    setRasterColorVariable:   polyRasterColorVariable
                          setShadeColorMax:  shadeColorMax];

  [habitatManager buildObjects];
  
  #ifdef PRINT_CELL_FISH_REPORT
      [habitatManager buildHabSpaceCellFishInfoReporter];
  #endif

  [habitatManager updateHabitatManagerWithTime: modelTime
                         andWithModelStartFlag: initialDay];

  numberOfReaches = [habitatManager getNumberOfHabitatSpaces];
  reachList = [habitatManager getHabitatSpaceList];

  //
  // set up fish lists
  //
  liveFish = [List create: modelZone];
  killedFish = [List create: modelZone];
  deadFish = [List create: modelZone];

  Male = [Symbol create: modelZone setName: "Male"];
  Female = [Symbol create: modelZone setName: "Female"];

  if(numberOfSpecies == 0)
  {
     fprintf(stderr, "ERROR: TroutModelSwarm >>>> buildObjects numberOfSpecies is ZERO!\n"); 
     fflush(0);
     exit(1);
  }

  reddList = [List create: modelZone];
  reddRemovedList = [List create: modelZone];
  emptyReddList = [List create: modelZone];

  if(theColormaps != nil) {
      [self setFishColormap: theColormaps];
  }


  //
  // This can only be done once the fish parameter objects have been created
  // and initialized
  //
  cmaxInterpolatorMap = [Map create: modelZone];
  spawnDepthInterpolatorMap = [Map create: modelZone];
  spawnVelocityInterpolatorMap = [Map create: modelZone];
  captureLogisticMap = [Map create: modelZone];
  [self createCMaxInterpolators];
  [self createSpawnDepthInterpolators];
  [self createSpawnVelocityInterpolators];
  [self createCaptureLogistics];

  fishInitializationRecords = [List create: modelZone];
  popInitTime = [timeManager getTimeTWithDate: popInitDate];

  [self createInitialFish];
  [self sortLiveFish];
  [self toggleFishForHabSurvUpdate];

  reddBinomialDist = [BinomialDist create: modelZone setGenerator: randGen];

  [self openReddSummaryFilePtr];
  [self openReddReportFilePtr];

  [self createBreakoutReporters];


  fprintf(stdout, "TroutModelSwarm >>> buildObjects >>>> runStartTime = %ld\n", (long) runStartTime);
  fprintf(stdout, "TroutModelSwarm >>> buildObjects >>>> runStartDate = %s\n", [timeManager getDateWithTimeT: runStartTime]);
  fprintf(stdout, "TroutModelSwarm >>> buildObjects >>>> modelTime = %ld\n", (long) modelTime);
  fprintf(stdout, "TroutModelSwarm >>> buildObjects >>>> modelTime = %s\n", [timeManager getDateWithTimeT: modelTime]);
  fflush(0);

  if(printFishParams)
  {
     int speciesNdx;
     for(speciesNdx = 0; speciesNdx < numberOfSpecies; speciesNdx++) 
     {
        [[fishParamsMap at: mySpecies[speciesNdx]] printSelf]; 
     }
  }

  fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> END\n");
  fflush(0);

  return self;

}  // buildObjects  


//////////////////////////////////////////////////////
//
// createFishParameters
//
// Create parameter objects for the fish
// parameters
//
/////////////////////////////////////////////////////
- createFishParameters
{
   int speciesNdx;

   fprintf(stdout, "TroutMOdelSwarm >>>> createFishParameters >>>> BEGIN\n");
   fflush(0);


   for(speciesNdx = 0; speciesNdx < numberOfSpecies; speciesNdx++) 
   {
      FishParams* fishParams = [FishParams createBegin:  modelZone];
      [ObjectLoader load: fishParams fromFileNamed: speciesParameter[speciesNdx]];
 
      [fishParams setFishSpeciesIndex: speciesNdx]; 
      [fishParams setFishSpecies: mySpecies[speciesNdx]]; 

      [fishParams setInstanceName: (char *) [mySpecies[speciesNdx] getName]];

      fishParams = [fishParams createEnd];

      #ifdef DEBUG_TROUT_FISHPARAMS
         [fishParams printSelf];
      #endif

      [fishParamsMap at: [fishParams getFishSpecies] insert: fishParams]; 
   }


   fprintf(stdout, "TroutMOdelSwarm >>>> createFishParameters >>>> END\n");
   fflush(0);
   return self;

}  // createFishParameters


//////////////////////////////////////////////
//
// findMinSpeciesPiscLength 
//
//////////////////////////////////////////////
- findMinSpeciesPiscLength
{
  int speciesNdx;
  FishParams* fishParams = nil;

  fprintf(stdout, "TroutModelSwarm >>>> findMinSpeciesPiscLength >>>> BEGIN\n");
  fprintf(stdout, "TroutModelSwarm >>>> findMinSpeciesPiscLength >>>> numberOfSpecies = %d\n", numberOfSpecies);
  fflush(0);

  if(numberOfSpecies > 1)
  {
      for(speciesNdx = 0; speciesNdx < numberOfSpecies; speciesNdx++) 
      {
         fishParams = [fishParamsMap at: mySpecies[speciesNdx]]; 
         minSpeciesMinPiscLength =  (minSpeciesMinPiscLength > fishParams->fishPiscivoryLength) ?
                                    fishParams->fishPiscivoryLength  
                                  : minSpeciesMinPiscLength;
      }
  }
  else
  {
      fishParams = [fishParamsMap at: mySpecies[0]]; 
      minSpeciesMinPiscLength =   fishParams->fishPiscivoryLength;
  }


  fprintf(stdout, "TroutModelSwarm >>>> minSpeciesMinPiscLength = %f\n", minSpeciesMinPiscLength);
  fflush(0);

  fprintf(stdout, "TroutModelSwarm >>>> findMinSpeciesPiscLength >>>> END\n");
  fflush(0);

  return self;
}


/////////////////////////////////////////////////////////
//
// setFishColormap
//
//////////////////////////////////////////////
- setFishColormap: theColormaps 
{
  id <ListIndex> speciesNdx;
  int speciesIDX=0;
  id nextSpecies= nil;
  int FISH_COLOR= (int) FISHCOLORSTART;
  id <MapIndex> clrMapNdx = [theColormaps mapBegin: scratchZone];
  id <Colormap> aColorMap = nil;

  //fprintf(stdout, "TroutModelSwarm >>>> setFishColormap >>>> BEGIN\n");
  //fprintf(stdout, "TroutModelSwarm >>>> setFishColormap >>>> tagFishColor = %s \n", tagFishColor);
  //xprint(theColormaps);
  //fflush(0);

  while(([clrMapNdx getLoc] != End) && ((aColorMap = [clrMapNdx next]) != nil))
  {
     [aColorMap setColor: FISH_COLOR 
                  ToName: "white"];
  }

  fishColorMap = [Map create: modelZone];

  FISH_COLOR++;

  //fprintf(stdout, "TroutModelSwarm >>>> setFishColormap >>>> FISH_COLOR = %d\n", FISH_COLOR);
  //fflush(0);

  speciesNdx = [speciesSymbolList listBegin: scratchZone];
  while(([speciesNdx getLoc] != End) && ((nextSpecies = [speciesNdx next]) != nil)) 
  {
      long* thisFishColor = [modelZone alloc: sizeof(long)];
      *thisFishColor = FISH_COLOR++;
  //fprintf(stdout, "TroutModelSwarm >>>> setFishColormap >>>> in while >>>> FISH_COLOR = %d\n", FISH_COLOR);
  //fflush(0);

      [clrMapNdx setLoc: Start];
     
      while(([clrMapNdx getLoc] != End) && ((aColorMap = [clrMapNdx next]) != nil))
      {
	//xprint(aColorMap);
            [aColorMap setColor: FISH_COLOR 
                         ToName: speciesColor[speciesIDX]];
      }

      *thisFishColor = FISH_COLOR;

      FISH_COLOR++;

      [fishColorMap at: nextSpecies insert: (void *) thisFishColor];

      speciesIDX++;
  }

  [speciesNdx drop];
  [clrMapNdx drop];

  //fprintf(stdout, "TroutModelSwarm >>>> setFishColormap >>>> END\n");
  //fflush(0);


   //exit(0);

  return self;
}


/////////////////////////////////////////
//
// createCMaxInterpolators
//
/////////////////////////////////////////
- createCMaxInterpolators
{
  id <MapIndex> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
     id <InterpolationTable> cmaxInterpolationTable = [InterpolationTable create: modelZone];

     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT1 Y: fishParams->fishCmaxTempF1];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT2 Y: fishParams->fishCmaxTempF2];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT3 Y: fishParams->fishCmaxTempF3];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT4 Y: fishParams->fishCmaxTempF4];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT5 Y: fishParams->fishCmaxTempF5];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT6 Y: fishParams->fishCmaxTempF6];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT7 Y: fishParams->fishCmaxTempF7];

     [cmaxInterpolatorMap at: [fishParams getFishSpecies] insert: cmaxInterpolationTable]; 
  }

  return self;
}

////////////////////////////////////////////////
//
// createSpawnDepthInterpolators
//
////////////////////////////////////////////////
- createSpawnDepthInterpolators
{
  id <Index> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
     id <InterpolationTable> spawnDepthInterpolationTable = [InterpolationTable create: modelZone];

     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD1 Y: fishParams->fishSpawnDSuitS1];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD2 Y: fishParams->fishSpawnDSuitS2];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD3 Y: fishParams->fishSpawnDSuitS3];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD4 Y: fishParams->fishSpawnDSuitS4];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD5 Y: fishParams->fishSpawnDSuitS5];

     [spawnDepthInterpolatorMap at: [fishParams getFishSpecies] insert: spawnDepthInterpolationTable]; 
  }

  return self;
}


////////////////////////////////////////////
//
// createSpawnVelocityInterpolators
//
///////////////////////////////////////////
- createSpawnVelocityInterpolators
{
  id <Index> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
     id <InterpolationTable> spawnVelocityInterpolationTable = [InterpolationTable create: modelZone];

     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV1 Y: fishParams->fishSpawnVSuitS1];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV2 Y: fishParams->fishSpawnVSuitS2];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV3 Y: fishParams->fishSpawnVSuitS3];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV4 Y: fishParams->fishSpawnVSuitS4];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV5 Y: fishParams->fishSpawnVSuitS5];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV6 Y: fishParams->fishSpawnVSuitS6];

     [spawnVelocityInterpolatorMap at: [fishParams getFishSpecies] insert: spawnVelocityInterpolationTable]; 
  }

  return self;
}


/////////////////////////////////////////////////
//
// createCaptureLogistics
//
/////////////////////////////////////////////////
- createCaptureLogistics
{
  id <Index> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
      //
      // getCellVelocity is not actually used;
      // it is there because the logistic
      // needs an input method. The fish
      // evaluates for velocity/aMaxSwimSpeed
      //
      LogisticFunc* aCaptureLogistic = [LogisticFunc createBegin: modelZone 
                                                 withInputMethod: M(getPolyCellVelocity) 
                                                      usingIndep: fishParams->fishCaptureParam1
                                                             dep: 0.1
                                                           indep: fishParams->fishCaptureParam9
                                                             dep: 0.9];

     [captureLogisticMap at: [fishParams getFishSpecies] insert: aCaptureLogistic]; 
  }

  return self;
}
//////////////////////////////////////////
//
// createInitialFish
//
// Create the initial lists of trout
//
//////////////////////////////////////////
- createInitialFish
{
   int MAX_COUNT=10000;
   int counter=0;
   id randSelectedCell = nil;
   id <Symbol> species = nil;

   //
   // This is new, don't forget tot tell SteveR about it.
   //
   id randCellDist = nil;
   id <List> polyCellList = nil;

   id <ListIndex> fishInitNdx = [fishInitializationRecords listBegin: scratchZone];
   TroutInitializationRecord* fishInitRecord = (TroutInitializationRecord *) nil;

   id <Symbol> newSpecies = nil;

   id aHabitatSpace;

   int numFishThisAge = 0;
   int fishNdx = 0;

   BOOL INIT_DATE_FOUND = NO;

   fprintf(stdout,"TroutModelSwarm >>>> createInitialFish >>>> BEGIN\n");
   fflush(0);

   //
   // Read the population files for each species
   // and create the fish initialization records
   //
   [self readFishInitializationFiles];

   numFish = 0;

   //
   // Now, read the fish initialization records and create the fish.
   //
   while(([fishInitNdx getLoc] != End) && ((fishInitRecord = (TroutInitializationRecord *) [fishInitNdx next]) != (TroutInitializationRecord *) nil))
   {
       if(fishInitRecord->mySpecies != (species = [speciesSymbolList atOffset: fishInitRecord->speciesNdx]))
       {
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> createInitialFish >>>> incorrect speciesNdx\n");
            fflush(0);
            exit(1);
       }
            
       if(![timeManager checkDateFormat: popInitDate]) 
       {
           fprintf(stderr, "ERROR: troutModelSwarm >>>> buildInitialFish >>>> popInitDate = %s\n"
                           "       Date improperlyFormatted see the \"Model Setup\" file\n"
                           "       or the \"Experiment Setup\" file\n", popInitDate); 
           fflush(0);
           exit(1);
       }
	    
       if(fishInitRecord->initTime == [timeManager getTimeTWithDate: popInitDate])
       {
           //
           // If we don't make it here, no fish will be initialized
           //
           INIT_DATE_FOUND = YES;
       }
       else 
       {
           continue;
       }

     
       aHabitatSpace = nil;
       aHabitatSpace = [habitatManager getReachWithName: fishInitRecord->reach];
        
       if(aHabitatSpace == nil)
       {
            //
            // Then skip it and move on
            //
            fprintf(stderr, "WARNING: TroutModelSwarm >>>> createInitialFish >>>> no habitat space with name %s\n", fishInitRecord->reach);
            fflush(0);
            continue;
       }



       polyCellList = [aHabitatSpace getPolyCellList];

       randCellDist = [UniformIntegerDist create: modelZone
                                    setGenerator: randGen
                                   setIntegerMin: 0
                                          setMax: [polyCellList getCount] - 1];

       if(aHabitatSpace == nil)
       {
            //
            // Then skip it and move on
            //
            fprintf(stderr, "WARNING: TroutModelSwarm >>>> createInitialFish >>>> creating no fish for reach %s\n", fishInitRecord->reach);
            fflush(0);
            continue;
       }
   
       if(fishInitRecord->number != 0) 
       {
          //
          // This distribution will only be used in this routine
          // and then goes out of scope.
          //
          id doubleNormDist1; 

          doubleNormDist1 = [NormalDist create: modelZone setGenerator: randGen
                                       setMean: fishInitRecord->meanLength
                                     setStdDev: fishInitRecord->stdDevLength];

          numFishThisAge = fishInitRecord->number;
 
          //
          //  build the population list for this species in this reach
          //
          for(fishNdx=0; fishNdx<numFishThisAge; fishNdx++)
          {
             id newFish;
	     double length = 0.0;
             FishParams* fishParams;
             double aMortFishVelocityV9;
  
             //
	     // set properties of the new Trout
             //
	     while((length = [doubleNormDist1 getDoubleSample]) <= (0.5)*[doubleNormDist1 getMean])
             {
                 ; 
             }

	     newFish = [self createNewFishWithSpeciesIndex: fishInitRecord->speciesNdx  
                                                   Species: fishInitRecord->mySpecies 
                                                       Age: fishInitRecord->age
                                                    Length: length ];

	     [liveFish addLast: newFish];

             fishParams = [newFish getFishParams];
             aMortFishVelocityV9 = fishParams->mortFishVelocityV9;

             //
	     // need to draw for random cell
             //
	     for(counter=0; counter <= MAX_COUNT; counter++) 
             {
	         randSelectedCell = [polyCellList atOffset: [randCellDist getIntegerSample]];

	         if(randSelectedCell != nil)
	         {
                     if([randSelectedCell getPolyCellDepth] > 0.0)
		     {
                        if([randSelectedCell getPolyCellVelocity] > [newFish calcMaxSwimSpeedAt: randSelectedCell] * aMortFishVelocityV9)
                        {
                             continue;
                        }

		        [randSelectedCell addFish: newFish];
		        numFish++;
		        break;
		     }
	         }
	         else
	         {
	            continue;
	         }

	     } //for MAX_COUNT

	     if(counter >= MAX_COUNT)
             {
	         fprintf(stderr, "WARNING: TroutModelSwarm >>>> createInitialFish >>>> Failed to put fish in cell with acceptable depth and velocity after %d attempts, for fish with length %f\nWill put fish in any cell with non-zero depth\n", counter, length);
                 fflush(0);
             }
 
             //
             // So..., if we can't find a cell with BOTH non-zero depth and acceptable velocity
             // just find a cell with non-zero depth and put the fish in it...
             //
             //
	     for(counter=0; counter <= MAX_COUNT; counter++) 
             {
	         randSelectedCell = [polyCellList atOffset: [randCellDist getIntegerSample]];

	         if(randSelectedCell != nil)
	         {
                     if([randSelectedCell getPolyCellDepth] > 0.0)
		     {
		        [randSelectedCell addFish: newFish];
		        numFish++;
		        break;                      //break out of the for MAX_COUNT statement
		     }
	         }
	         else
	         {
	            continue;
	         }

	     } //for MAX_COUNT

	     if(counter >= MAX_COUNT)
             {
	         fprintf(stderr, "ERROR: TroutModelSwarm >>>> createInitialFish >>>> Failed to put fish in cell with non-zero depth after %d attempts\n", counter);
                 fflush(0);
                 exit(1);
             }
             
             //
             // calculate instance variables here to start things rolling...
             //
             if(randSelectedCell == nil)
             {
                  fprintf(stderr, "ERROR: TroutModelSwarm >>>> createInitialFish >>>> randSelectedCell is nil\n");
                  fflush(0);
                  exit(1);
             }
             //fprintf(stderr, "TroutModelSwarm >>>> createInitialFish >>>> newFish moveToBestDest Fish = %p\n", newFish);
             //fprintf(stderr, "TroutModelSwarm >>>> createInitialFish >>>> newFish moveToBestDest randSelectedCell = %p\n", randSelectedCell);
             //fflush(0);
             //
             // now set the ivars in newFish...
             //
             [newFish moveToBestDest: randSelectedCell];

         } // end numFish/Age loop



	  // cleanup
	  [doubleNormDist1 drop];


      }  //if fishInitRecord->number != 0
   


      if(INIT_DATE_FOUND == NO)
      {
          fprintf(stderr, "ERROR: TroutModelSwarm >>>> createInitialFish >>>> No fish were initialized\n \
                           check the fish initialization dates in the Initial Fish, Model.Setup and the Experiment.Setup files\n");
          fflush(0);
          exit(1);
      }

      if(newSpecies != species)
      {
         INIT_DATE_FOUND = NO;
      }

      [randCellDist drop];
      randCellDist = nil;

    } //while fishInitRecord

  //[randCellDist drop];
  //randCellDist = nil;

  fprintf(stdout,"TroutModelSwarm >>>> createInitialFish >>>> [liveFish getCount] = %d\n", [liveFish getCount]);
  fprintf(stdout,"TroutModelSwarm >>>> createInitialFish >>>> END\n");
  fflush(0);

  return self;
}


///////////////////////////////////////
//
// readFishInitializationFiles
//
//////////////////////////////////////
- readFishInitializationFiles
{
  FILE * speciesPopFP=NULL;
  int numSpeciesNdx;
  char * header1=(char *) NULL;
  int prevAge = -1;
  char date[11];
  char prevDate[11];
  int age;
  int number;
  double meanLength;
  double stdDevLength;
  char reach[35];
  char prevReach[35];

  int numRecords;
  int recordNdx;

  BOOL POPINITDATEOK = NO;

  fprintf(stderr,"TroutModelSwarm >>>> readFishInitializationFiles >>>> BEGIN\n");
  fflush(0);

  for(numSpeciesNdx=0; numSpeciesNdx<numberOfSpecies; numSpeciesNdx++)
  {
      if((speciesPopFP = fopen(speciesPopFile[numSpeciesNdx], "r")) == NULL) 
      {
          fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> Error opening %s \n", speciesPopFile[numSpeciesNdx]);
          fflush(0);
          exit(1);
      }

      header1 = (char *)[scratchZone alloc: HCOMMENTLENGTH*sizeof(char)];

      fgets(header1,HCOMMENTLENGTH,speciesPopFP);
      fgets(header1,HCOMMENTLENGTH,speciesPopFP);
      fgets(header1,HCOMMENTLENGTH,speciesPopFP);

      strcpy(prevDate,"00/00/0000");
      strcpy(prevReach,"NOREACH");

      while(fscanf(speciesPopFP,"%11s %d %d %lf %lf %35s", date, &age, &number, &meanLength, &stdDevLength, reach) != EOF)
      {
           TroutInitializationRecord*  fishRecord;

           fishRecord = (TroutInitializationRecord *) [modelZone alloc: sizeof(TroutInitializationRecord)];

           if(strcmp(prevDate, "00/00/0000") == 0)
           {
              strcpy(prevDate, date);
           }
           if(strcmp(prevReach, "NOREACH") == 0)
           {
              strcpy(prevReach, reach);
           }


           fishRecord->speciesNdx = numSpeciesNdx;
           fishRecord->mySpecies = mySpecies[numSpeciesNdx];
           strncpy(fishRecord->date, date, 11);
           fishRecord->initTime = [timeManager getTimeTWithDate: date];
           if(fishRecord->initTime == popInitTime)
           {
               POPINITDATEOK = YES;
           }
           fishRecord->age = age;
           fishRecord->number = number;
           fishRecord->meanLength = meanLength;
           fishRecord->stdDevLength = stdDevLength;
           strcpy(fishRecord->reach, reach);
           
           fprintf(stdout, "TroutModelSwarm >>>> checking fish records >>>>>\n");
           fprintf(stdout, "speciesNdx = %d speciesName = %s date = %s initTime = %ld age = %d number = %d meanLength = %f stdDevLength = %f reach = %s\n",
                                           fishRecord->speciesNdx,
                                           [fishRecord->mySpecies getName],
                                           fishRecord->date,
                                           (long) fishRecord->initTime,
                                           fishRecord->age,
                                           fishRecord->number,
                                           fishRecord->meanLength,
                                           fishRecord->stdDevLength,
                                           fishRecord->reach);
           fflush(0);


          if(strcmp(prevReach, reach) == 0)
          {
              if(strcmp(prevDate, date) == 0)
              {
                  if(prevAge >= age) 
                  {
                     fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> Check %s and ensure that fish ages are in increasing order\n",speciesPopFile[numSpeciesNdx]);
                     fflush(0);
                     exit(1);
                  }
 
                  prevAge = age;
              }
              else
              {
                 strcpy(prevDate, date);
                 prevAge = age;
              }
          }
          else
          {
               strcpy(prevReach, reach);
               prevAge = -1;
          }

          [fishInitializationRecords addLast: (void *) fishRecord];

      }

      if(POPINITDATEOK == NO)
      {
           fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> popInitDate not found\n");
           fflush(0);
           exit(1);
      }

     prevAge = -1;

     fclose(speciesPopFP);
  } //for numberOfSpecies

  [scratchZone free: header1];

  numRecords = [fishInitializationRecords getCount];

  for(recordNdx = 0; recordNdx < numRecords; recordNdx++)
  {
       int chkRecordNdx; 

       TroutInitializationRecord* fishRecord = (TroutInitializationRecord *) [fishInitializationRecords atOffset: recordNdx]; 

       for(chkRecordNdx = 0; chkRecordNdx < numRecords; chkRecordNdx++)
       {
       
           TroutInitializationRecord* chkFishRecord = (TroutInitializationRecord *) [fishInitializationRecords atOffset: chkRecordNdx]; 

                   if(fishRecord == chkFishRecord)
                   {
                       continue;
                   }
                   else if(    (fishRecord->mySpecies == chkFishRecord->mySpecies)
                            && (strcmp(fishRecord->date, chkFishRecord->date) == 0) 
                            && (fishRecord->age == chkFishRecord->age)
                            && (strcmp(fishRecord->reach, chkFishRecord->reach) == 0))
                   {
                         fprintf(stderr, "\n\n");
                         fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles\n");
                         fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> Multiple records for the following record\n");
                         fprintf(stderr, "speciesName = %s date = %s age = %d number = %d  reach = %s\n",
                                       [fishRecord->mySpecies getName],
                                       fishRecord->date,
                                       fishRecord->age,
                                       fishRecord->number,
                                       fishRecord->reach);
                         fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles\n");
                         fflush(0);
                         exit(1);
                   }

       }

       fprintf(stdout, "speciesNdx = %d speciesName = %s date = %s initTime = %ld age = %d number = %d meanLength = %f stdDevLength = %f reach = %s\n",
                                       fishRecord->speciesNdx,
                                       [fishRecord->mySpecies getName],
                                       fishRecord->date,
                                       (long) fishRecord->initTime,
                                       fishRecord->age,
                                       fishRecord->number,
                                       fishRecord->meanLength,
                                       fishRecord->stdDevLength,
                                       fishRecord->reach);
       fflush(0);

   }
           

  fprintf(stderr,"TroutModelSwarm >>>> readFishInitializationFiles >>>> END\n");
  fflush(0);

  return self;
} 


//////////////////////////////////////////////////////////////////////
//
// buildActions
//
///////////////////////////////////////////////////////////////////////
- buildActions 
{
 
  [super buildActions];

  fprintf(stdout,"TroutModelSwarm >>>> buildActions >>>> BEGIN\n");
  fflush(0);

  // create the action group with sequential ordering --the only ordering
  // available now, anyway

  updateActions = [ActionGroup createBegin: modelZone];
  updateActions = [updateActions createEnd];

  initAction = [ActionGroup createBegin: modelZone];
  initAction = [initAction createEnd];

  fishActions = [ActionGroup createBegin: modelZone];
  fishActions = [fishActions createEnd];

  reddActions = [ActionGroup createBegin: modelZone];
  reddActions = [reddActions createEnd];

  #ifdef PRINT_CELL_FISH_REPORT
      printCellFishAction = [ActionGroup createBegin: modelZone];
      printCellFishAction = [printCellFishAction createEnd];
  #endif
  modelActions = [ActionGroup createBegin: modelZone];
  modelActions = [modelActions createEnd];

  // create the action group that performs maintenance overhead for the model
  overheadActions = [ActionGroup createBegin: modelZone];
  overheadActions = [overheadActions createEnd];

  // UPDATE ACTIONS
  //
  // Now, put the actions executed each time step
  // into the action groups
  //
  [updateActions createActionTo: self message: M(updateModelTime)];
  [updateActions createActionTo: self message: M(updateFish)];
  [updateActions createActionTo: self message: M(updateHabitatManager)]; 


  // INITACTION
  [initAction createActionTo: self message: M(initialDayAction)];


  //
  // MODEL ACTIONS
  //
  // Fish Actions
  //

  
  [fishActions createActionTo: self message: M(toggleFishForHabSurvUpdate)];
  [fishActions createActionForEach: liveFish message: M(spawn)];
  [fishActions createActionForEach: liveFish message: M(move)];
  [fishActions createActionForEach: liveFish message: M(grow)];
  [fishActions createActionForEach: liveFish message: M(die)];

  //
  // Redd Actions
  //
  [reddActions createActionForEach: [self getReddList]
	       message: M(survive)];

  [reddActions createActionForEach: [self getReddList]
	       message: M(develop)];

  [reddActions createActionForEach: [self getReddList]
               message: M(emerge)];


  #ifdef PRINT_CELL_FISH_REPORT
      [printCellFishAction createActionTo: habitatManager message: M(outputCellFishInfoReport)];
  #endif

  [modelActions createAction: fishActions];
  [modelActions createAction: reddActions];

  //#ifdef PRINT_CELL_FISH_REPORT
     //[modelActions createAction: printCellFishAction];
  //#endif

  // designate the OVERHEAD ACTIONS
  [overheadActions createActionTo: self message: M(processEmptyReddList)];
  [overheadActions createActionTo: self message: M(removeKilledFishFromLiveFishList)];
  [overheadActions createActionTo: self message: M(sortLiveFish)];
  [overheadActions createActionTo: self message: M(updateKilledFishList)];
  [overheadActions createActionTo: self message: M(outputInfoToTerminal)];

  //
  // This is the main model schedule
  //

  // create the SCHEDULE that will be iterated over for the entire
  // model

  modelSchedule = [Schedule createBegin: modelZone];
  [modelSchedule setRepeatInterval: 1];
  modelSchedule = [modelSchedule createEnd];

  printSchedule = [Schedule createBegin: modelZone];
  [printSchedule setRepeatInterval: fileOutputFrequency];
  printSchedule = [printSchedule createEnd];
  [printSchedule createActionTo: self message: M(outputBreakoutReports)];
  #ifdef PRINT_CELL_FISH_REPORT
     [printSchedule createAction: printCellFishAction];
  #endif

  //
  // Put the Actions in the schedule
  //
              [modelSchedule at: 0 createAction: updateActions];
 oneAction =  [modelSchedule at: 0 createAction: initAction];
              [modelSchedule at: 0 createAction: modelActions];
              [modelSchedule at: 0 createAction: overheadActions];

  fprintf(stdout,"TroutModelSwarm >>>> buildActions >>>> END\n");
  fflush(0);

  return self;

}  // buildActions


///////////////////////////////////
//
// updateTkEvents
//
///////////////////////////////////
- updateTkEventsFor: aReach
{
    //
    // Passes message to the observer
    // which in turn passes the message
    // to the experSwarm.
    //
    [observerSwarm updateTkEventsFor: aReach];
    return self;
}

//////////////////////////////////////////////////////
//
// activateIn
//
/////////////////////////////////////////////////////
- activateIn: swarmContext 
{

  [super activateIn: swarmContext];
  [modelSchedule activateIn: self];
  [printSchedule activateIn: self];

  fprintf(stderr, "TROUT MODEL SWARM >>>> activateIn\n");
  fflush(0);

  return [self getActivity];
}

/////////////////////////////////////////////////////////
//
// addAFish
//
////////////////////////////////////////////////////////////
- addAFish: (Trout *) aTrout 
{
  numFish++;
  [liveFish addLast: aTrout];
  return self;
}


///////////////////////////////
//
// getRandGen
//
//////////////////////////////
- getRandGen 
{
   return randGen;
}


//////////////////////////////////
//
// getReddList
//
//////////////////////////////////
- (id <List>) getReddList 
{
  return reddList;
}


////////////////////////////////////
//
// getReddremovedList
//
///////////////////////////////////
- (id <List>) getReddRemovedList 
{
  return reddRemovedList;
}



///////////////////////////////////////
//
// addToKilledList
//
///////////////////////////////////////
- addToKilledList: (Trout *) aFish 
{
  [deadFish addLast: aFish];
  [killedFish addLast: aFish];

  [self updateMortalityCountWith: aFish];

  return self;
}


/////////////////////////////////
//
// addToEmptyReddList
//
////////////////////////////////
- addToEmptyReddList: aRedd 
{
  [emptyReddList addLast: aRedd];
  return self;
}


//////////////////////////////////////////////
//
// getHabitatManager
//
//////////////////////////////////////////////
- (HabitatManager *) getHabitatManager
{
    return habitatManager;
}



//////////////////////////////////////////////////////////
//
// whenToStop
//
// This is where any methods called at the end of 
// the model run are performed
//
// Called from the observer swarm 
//
////////////////////////////////////////////////////////
- (BOOL) whenToStop 
{ 
   BOOL STOP = NO;

   if(simCounter >= numSimDays)
   {
       STOP = YES;

       #ifdef REDD_SURV_REPORT
          [self printReddSurvReport];
       #endif

       fprintf(stdout,"TroutModelSwarm >>>> whenToStop >>>> STOPPING\n");
       fflush(0);

   }
   else 
   {
       STOP = NO;
       simCounter++;
   }

   return STOP;
}



///////////////////////////////////////////////////////
//
// updateFish
//
//////////////////////////////////////////////////////
- updateFish 
{
    if(updateFish == YES)
    {
        id <ListIndex> ndx;
        id fish=nil;
        ndx = [liveFish listBegin: scratchZone];
        while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil))
        {
            [fish updateFishWith: modelTime];
        }
        [ndx drop];
    }

    updateFish = YES;

    return self;
}


///////////////////////////////////
//
// initialDayAction
//
// This is done only on the first day
//
////////////////////////////////////

- initialDayAction 
{
  initialDay = 0;
  [modelSchedule remove: oneAction];
  return self;
}



/////////////////////////////////////////////////////////
//
// updateHabitatManager
//
//////////////////////////////////////////////////////////
- updateHabitatManager 
{
  [habitatManager updateHabitatManagerWithTime: modelTime
                         andWithModelStartFlag: initialDay];
  return self;
}


/////////////////////////////////////////////////
//
// setShadeColorMax
//
/////////////////////////////////////////////////
- setShadeColorMax: (double) aShadeColorMax
          inHabitatSpace: aHabitatSpace
{
    shadeColorMax = aShadeColorMax;
    [habitatManager setShadeColorMax: shadeColorMax
                      inHabitatSpace: aHabitatSpace];
    return self;
}


///////////////////////////////////////////////////////
//
// switchColorRepFor 
//
///////////////////////////////////////////////////////
- switchColorRepFor: aHabitatSpace
{
    fprintf(stdout, "TroutModelSwarm >>>> switchColorRepFor >>>> BEGIN\n");
    fflush(0);

    if(observerSwarm == nil)
    {
       fprintf(stderr, "WARNING: TroutModelSwarm >>>> switchColorRepFor >>>> observerSwarm is nil >>>> Cannot handle your request\n");
       fflush(0);
    }

    [observerSwarm switchColorRepFor: aHabitatSpace];  


    fprintf(stdout, "TroutModelSwarm >>>> switchColorRepFor >>>> END\n");
    fflush(0);

    return self;
}


/////////////////////////////////////////////////////////
//
// toggleCellsColorRepIn
//
//////////////////////////////////////////////////////////
- toggleCellsColorRepIn: aHabitatSpace
{
      [habitatManager setShadeColorMax: shadeColorMax
                       inHabitatSpace:  aHabitatSpace];
      [habitatManager toggleCellsColorRepIn: aHabitatSpace];
      return self;
}


////////////////////////////////////////////////////////////////
//
// getLiveFishList
//
////////////////////////////////////////////////////////////////
- (id <List>) getLiveFishList 
{
  return liveFish;
}


////////////////////////////////////////////////////////////
//
// getDeadTroutList
//
////////////////////////////////////////////////////////////
- (id <List>) getDeadTroutList 
{
    return deadFish;
}

///////////////////////////////////
//
// removeKilledFishFromLiveFishList
//
//////////////////////////////////
- removeKilledFishFromLiveFishList
{

   id <ListIndex> ndx = [killedFish listBegin: scratchZone];
   id aFish = nil;

   [ndx setLoc: Start];

   while(([ndx getLoc] != End) && ((aFish = [ndx next]) != nil))
   {
      [liveFish remove: aFish];
   }

   [ndx drop];

   return self;

}


///////////////////////////////////
//
// updateKilledFishList
//
//////////////////////////////////
- updateKilledFishList
{
   [killedFish removeAll];
   return self;
}



////////////////////////////////////////
//
// sortLiveFish
//
///////////////////////////////////////
- sortLiveFish
{
  [QSort sortObjectsIn:  liveFish];
  [QSort reverseOrderOf: liveFish];

  return self;
}


//////////////////////////////////////////
//
// processEmptyReddList
//
///////////////////////////////////////////
- processEmptyReddList 
{
    id <ListIndex> emptyReddNdx;
    id nextRedd = nil;

    emptyReddNdx = [emptyReddList listBegin: scratchZone];

    while (([emptyReddNdx getLoc] != End) && ((nextRedd = [emptyReddNdx next]) != nil)) 
    {
       if([reddList contains: nextRedd] == YES)
       {
          [reddList remove: nextRedd];
       }
       else
       {
           fprintf(stderr, "ERROR: TroutModelSwarm >>>> processEmptyReddList >>>> attempting to remove a nonexistant redd from redd list\n");
           fflush(0);
           exit(1);
       }       

       [reddRemovedList addLast: nextRedd];
    }

    [emptyReddNdx drop];
    [emptyReddList removeAll];

    return self;
}




//////////////////////////////////////////////////////
//
// createNewFishWithSpeciesIndex
//
/////////////////////////////////////////////////////
- (Trout *) createNewFishWithSpeciesIndex: (int) speciesNdx  
                                  Species: (id <Symbol>) species
                                      Age: (int) age
                                   Length: (double) fishLength 
{

  id newFish;
  id <Symbol> ageSymbol = nil;
  id <InterpolationTable> aCMaxInterpolator = nil;
  id <InterpolationTable> aSpawnDepthInterpolator = nil;
  id <InterpolationTable> aSpawnVelocityInterpolator = nil;
  LogisticFunc* aCaptureLogistic = nil;

  //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithSpeciesIndex >>>> BEGIN\n");
  //fflush(0);

  //
  // The newFish color is currently being set in the observer swarm
  //

  newFish = [MyTroutClass[speciesNdx] createBegin: modelZone];

  [newFish setFishParams: [fishParamsMap at: species]];

  //
  // set properties of the new Trout
  //

  ((Trout *)newFish)->sex = ([coinFlip getCoinToss] == YES ?  Female : Male);

  ((Trout *)newFish)->randGen = randGen;

  ((Trout *)newFish)->rasterResolutionX = polyRasterResolutionX;
  ((Trout *)newFish)->rasterResolutionY = polyRasterResolutionY;

  [newFish setSpecies: species];
  [newFish setSpeciesNdx: speciesNdx];
  [newFish setAge: age];

  ageSymbol = [self getAgeSymbolForAge: age];
   
  [newFish setAgeSymbol: ageSymbol];

  [newFish setFishLength: fishLength];
  [newFish setFishCondition: 1.0];
  [newFish setFishWeightFromLength: fishLength andCondition: 1.0]; 
  [newFish setTimeTLastSpawned: 0];    //Dec 31 1969

  [newFish calcStarvPaAndPb];

  if(fishColorMap != nil)
  {
     [newFish setFishColor: (Color) *((long *) [fishColorMap at: [newFish getSpecies]])];
  }

  [newFish setTimeManager: timeManager];
  [newFish setModel: (id <TroutModelSwarm>) self];

  aCMaxInterpolator = [cmaxInterpolatorMap at: species];
  aSpawnDepthInterpolator = [spawnDepthInterpolatorMap at: species];
  aSpawnVelocityInterpolator = [spawnVelocityInterpolatorMap at: species];
  aCaptureLogistic = [captureLogisticMap at: species];
  
  [newFish setCMaxInterpolator: aCMaxInterpolator];
  [newFish setSpawnDepthInterpolator: aSpawnDepthInterpolator];
  [newFish setSpawnVelocityInterpolator: aSpawnVelocityInterpolator];
  [newFish setCaptureLogistic: aCaptureLogistic];

  newFish = [newFish createEnd];

  //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithSpeciesIndex >>>> END\n");
  //fflush(0);
        
  return newFish;
}

///////////////////////////////////////////////////////////////////////////////
//
// readSpeciesSetup
//
////////////////////////////////////////////////////////////////////////////////
- readSpeciesSetup 
{
  FILE* speciesFP=NULL;
  const char* speciesFile="Species.Setup";
  int speciesIDX;
  char* headerLine;

  int checkNumSpecies=0;

  if(numberOfSpecies > 10)
  {
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> readSpeciesSetup >>>> numberOfSpecies greater than 10");
      fflush(0);
      exit(1);
  }

  speciesName  = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  speciesParameter  = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  speciesPopFile = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  speciesColor = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];

  headerLine = (char *) [modelZone alloc: HCOMMENTLENGTH*sizeof(char)];

  if((speciesFP = fopen( speciesFile, "r")) == NULL) 
  {
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> readSpeciesSetup >>>> Cannot open speciesFile %s",speciesFile);
      fflush(0);
      exit(1);
  }

  fgets(headerLine,HCOMMENTLENGTH,speciesFP);  
  fgets(headerLine,HCOMMENTLENGTH,speciesFP);  
  fgets(headerLine,HCOMMENTLENGTH,speciesFP);  

  for(speciesIDX=0;speciesIDX<numberOfSpecies;speciesIDX++) 
  {

      speciesName[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];
      speciesParameter[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];
      speciesPopFile[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];
      speciesColor[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];

      if(fscanf(speciesFP,"%s%s%s%s",speciesName[speciesIDX],
                              speciesParameter[speciesIDX],
                              speciesPopFile[speciesIDX],
                              speciesColor[speciesIDX]) != EOF)
      {
          checkNumSpecies++;

          fprintf(stdout, "TroutModelSwarm >>>> readSpeciesSetup >>>> Myfiles are: %s %s %s \n", speciesName[speciesIDX],speciesParameter[speciesIDX], speciesPopFile[speciesIDX]);
          fflush(0);
      }

   }

   if((checkNumSpecies != numberOfSpecies) || (checkNumSpecies == 0))
   {
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> readSpeciesSetup >>>> Please check the Species.Setup file and the Model.Setup file and\n ensure that the numberOfSpecies is consistent with the Species.Setup data\n");
      fflush(0);
      exit(1);
   
   } 

   fclose(speciesFP);
   [modelZone free: headerLine];

   return self;
} 


//////////////////////////////////////////////////////
//
// buildFishClass
//
/////////////////////////////////////////////////////
- buildFishClass 
{
   int i;

   MyTroutClass = (Class *) [modelZone alloc: numberOfSpecies*sizeof(Class)];

   speciesClassList = [List create: modelZone]; 

   for(i=0;i<numberOfSpecies;i++) 
   {
        if(objc_lookup_class(speciesName[i]) == Nil)
        {
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> buildFishClass >>>> can't find class for %s\n", speciesName[i]);
            fflush(0);
            exit(1);
        }  

       MyTroutClass[i] = [objc_get_class(speciesName[i]) class];
       [speciesClassList addLast: MyTroutClass[i]];
   }

   return self;
}


- (id <List>) getSpeciesClassList 
{
  return speciesClassList;
}

- (int) getNumberOfSpecies 
{
  return numberOfSpecies;
}


////////////////////////////////////////////
//
// getSpeciesSymbolWithName
//
////////////////////////////////////////////
- (id <Symbol>) getSpeciesSymbolWithName: (char *) aName
{
   id <Symbol> speciesSymbol = nil;
   id <ListIndex> ndx = nil;
   BOOL speciesNameFound = NO;
   char* speciesName = NULL;

   if(speciesSymbolList != nil)
   {
       ndx = [speciesSymbolList listBegin: scratchZone];
   }
   else
   {
      fprintf(stderr, "TroutModelSwarm >>>> getSpeciesSymbolWithName >>>> method invoked before instantiateObjects\n");
      fflush(0);
      exit(1);
   }

   while(([ndx getLoc] != End) && ((speciesSymbol = [ndx next]) != nil))  
   {
        speciesName = (char *)[speciesSymbol getName];
        if(strncmp(aName, speciesName, strlen(speciesName)) == 0)
        {
            speciesNameFound = YES;
            [scratchZone free: speciesName];
            speciesName = NULL; 
            break;
        }

        if(speciesName != NULL)
        { 
            [scratchZone free: speciesName];
            speciesName = NULL;
        }
   } 

   if(!speciesNameFound)
   {
       fprintf(stderr, "TroutModelSwarm >>>> getSpeciesSymbolWithName >>>> no species symbol for name %s\n", aName);
       fflush(0);
       exit(1);
   } 

   return speciesSymbol;
}

/////////////////////////////////////////////////
//
// openReddReportFilePtr
//
//////////////////////////////////////////////////
- openReddReportFilePtr 
{

  if(reddRptFilePtr == NULL) 
  {

     if ((appendFiles == NO) && (scenario == 1) && (replicate == 1))
     {
        if((reddRptFilePtr = fopen(reddMortalityFile,"w")) == NULL ) 
        {
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n",reddMortalityFile);
            fflush(0);
            exit(1);
        }
        fprintf(reddRptFilePtr,"\n\n");
        fprintf(reddRptFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
     }
     else if((scenario == 1) && (replicate == 1) && (appendFiles == YES))
     {
        if((reddRptFilePtr = fopen(reddMortalityFile,"a")) == NULL)
        {
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n",reddMortalityFile);
            fflush(0);
            exit(1);
        }
        fprintf(reddRptFilePtr,"\n\n");
        fprintf(reddRptFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
     }
     else // Not the first replicate or scenario, so no header 
     {
         if((reddRptFilePtr = fopen(reddMortalityFile,"a")) == NULL) 
         {
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for appending\n",reddMortalityFile);
            fflush(0);
            exit(1);
         }
     }

  }

   if(reddRptFilePtr == NULL)
   {
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> File %s is not open\n",reddMortalityFile);
       fflush(0);
       exit(1);
   }


  return self;

}


/////////////////////////////////////////////////
//
// getReddReportFilePtr
//
//////////////////////////////////////////////////
- (FILE *) getReddReportFilePtr
{

   if(reddRptFilePtr == NULL)
   {
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> getReddReportFilePtr >>>> File %s is not open\n", reddMortalityFile);
       fflush(0);
       exit(1);
   }

   return reddRptFilePtr;
}



#ifdef REDD_SURV_REPORT

//////////////////////////////////////////////////////////
//
// printReddSurvReport
//
/////////////////////////////////////////////////////////
- printReddSurvReport { 
    FILE *printRptPtr=NULL;
    const char * reddSurvFile = "Redd_Survival_Test_Out.csv";
    id <ListIndex> reddListNdx;
    id redd;

    if((printRptPtr = fopen(reddSurvFile,"w+")) != NULL){
        if([[self getReddRemovedList] getCount] != 0){
            reddListNdx = [reddRemovedList listBegin: modelZone];

            while(([reddListNdx getLoc] != End) && ((redd = [reddListNdx next]) != nil)){
               [redd printReddSurvReport: printRptPtr];
            }
            [reddListNdx drop];
        }
   }else{
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> printReddSurvReport >>>> Couldn't open %s\n", reddSurvFile);
       fflush(0);
       exit(1);
   }
   fclose(printRptPtr);
   return self;
}

#endif



///////////////////////////////////////////////////
//
// openReddSummaryFilePtr
//
//////////////////////////////////////////////////
- openReddSummaryFilePtr {
  char * formatString = "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n";
  char * fileMetaData;

  if(reddSummaryFilePtr == NULL) {
    if ((appendFiles == NO) && (scenario == 1) && (replicate == 1)){
      if((reddSummaryFilePtr = fopen(reddOutputFile,"w")) == NULL ){
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for writing\n",reddOutputFile);
            fflush(0);
            exit(1);
       }
       fileMetaData = [BreakoutReporter reportFileMetaData: scratchZone];
       fprintf(reddSummaryFilePtr,"\n%s\n\n",fileMetaData);
       [scratchZone free: fileMetaData];

	fprintf(reddSummaryFilePtr,formatString, "Scenario",
						 "Replicate",
						 "ReddID",
						 "SpawnerLength",
						 "SpawnerWeight",
						 "SpawnerAge",
						 "Species",
						 "Reach",
						 "CellNo",
						 "CreateDate",
						 "InitialNumberOfEggs",
						 "EmptyDate",
						 "Dewatering",
						 "Scouring",
						 "LowTemp",
						 "HiTemp",
						 "Superimp",
						 "FryEmerged"); 
    }else if ((scenario == 1) && (replicate == 1) && (appendFiles == YES)){
      if( (reddSummaryFilePtr = fopen(reddOutputFile,"a")) == NULL ) {
	fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for writing\n",reddOutputFile);
	fflush(0);
	exit(1);
      }
      fileMetaData = [BreakoutReporter reportFileMetaData: scratchZone];
      fprintf(reddSummaryFilePtr,"\n%s\n\n",fileMetaData);
      [scratchZone free: fileMetaData];

      fprintf(reddSummaryFilePtr,formatString, "Scenario",
					   "Replicate",
					   "ReddID",
					   "SpawnerLength",
					   "SpawnerWeight",
					   "SpawnerAge",
					   "Species",
					   "Reach",
					   "CellNo",
					   "CreateDate",
					   "InitialNumberOfEggs",
					   "EmptyDate",
					   "Dewatering",
					   "Scouring",
					   "LowTemp",
					   "HiTemp",
					   "Superimp",
					   "FryEmerged"); 
    }else{ // Not the first replicate or scenario, so no header
	   if((reddSummaryFilePtr = fopen(reddOutputFile,"a")) == NULL ){
	       fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for appending\n",reddOutputFile);
	       fflush(0);
	       exit(1);
	   }
    }
  }
  if(reddSummaryFilePtr == NULL){
     fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for writing\n",reddOutputFile);
     fflush(0);
     exit(1);
  }
  return self;
}

///////////////////////////////////
//
// getReddSummaryFilePtr 
//
/////////////////////////////////// 
- (FILE *) getReddSummaryFilePtr {
   if(reddSummaryFilePtr == NULL){
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>>  file %s is not open\n",reddOutputFile);
       fflush(0);
       exit(1);
   }
   return reddSummaryFilePtr;
}

//////////////////////////////////////////////////////////
//
////
//////           MODEL TIME_T METHODS
////////
//////////
////////////
/////////////////////////////////////////////////////////

- updateModelTime 
{
  time_t newYearTime = (time_t) 0;

  if(shuffleYears == NO)
  {
      if(initialDay == YES)
      {
          initialDay = NO;
      }
      else 
      {
         modelTime = [timeManager stepTimeWithControllerObject: self];
      }

  }
  else
  {
      if(initialDay == YES)
      {
          initialDay = NO;
      }
      else
      {
          modelTime = [timeManager stepTimeWithControllerObject: self];

          newYearTime = [yearShuffler checkForNewYearAt: modelTime];

          if(newYearTime != modelTime)
          {
              [timeManager setCurrentTime: newYearTime];
              modelTime = newYearTime;
          }
      } // else initial day = NO
  } 

  strcpy(modelDate, [timeManager getDateWithTimeT: modelTime]);

  return self;
}



/////////////////////////////////////////////////////////
//
// getModelTime
//
/////////////////////////////////////////////////////////
- (time_t) getModelTime 
{
   return modelTime;
}


- (id <Zone>) getModelZone 
{
    return modelZone;
}

- (BOOL) getAppendFiles 
{
  return appendFiles;
}

- (int) getScenario 
{
  return scenario;
}


- (int) getReplicate 
{
  return replicate;
}


////////////////////////////////////
//
// getSpeciesSymbolList
//
////////////////////////////////////
- (id <List>) getSpeciesSymbolList
{
   return speciesSymbolList;
}


///////////////////////////////////
//
// getAgeSymbolList
//
///////////////////////////////////
- (id <List>) getAgeSymbolList
{
   return ageSymbolList;
}



///////////////////////////////////////
//
// outputInfoToTerminal
//
///////////////////////////////////////
- outputInfoToTerminal
{
  fprintf(stdout, "%s Scenario %d Replicate %d Number of live fish = %d\n", 
                             [timeManager getDateWithTimeT: modelTime], 
                             scenario, 
                             replicate, 
                             [liveFish getCount]);
  fflush(0);

  return self;
}


//////////////////////////////////////////////////////////
//
// getFishMortalitySymbolWithName
//
//////////////////////////////////////////////////////////
- (id <Symbol>) getFishMortalitySymbolWithName: (char *) aName
{

    id <ListIndex> lstNdx;
    id aSymbol = nil;
    id mortSymbol = nil;
    TroutMortalityCount* mortalityCount = nil;
    char* mortName = NULL;

    lstNdx = [fishMortSymbolList listBegin: scratchZone]; 

    while(([lstNdx getLoc] != End) && ((aSymbol = [lstNdx next]) != nil))
    {
       mortName = (char *) [aSymbol getName];  
        if(strncmp(aName, mortName, strlen(aName)) == 0) 
        {
           mortSymbol = aSymbol;
           [scratchZone free: mortName];
           mortName = NULL;
           break;
        }

        if(mortName != NULL)
        {
            [scratchZone free: mortName];
            mortName = NULL;
        }
    }
  
    [lstNdx drop];

    if(mortSymbol == nil)
    {
        mortSymbol = [Symbol create: modelZone setName: aName];
        [fishMortSymbolList addLast: mortSymbol];

        mortalityCount = [TroutMortalityCount createBegin: modelZone
                                       withMortality: mortSymbol];

        [listOfMortalityCounts addLast: mortalityCount];

        if(mortalityCountLstNdx != nil)
        {
            [mortalityCountLstNdx drop];
        }
    
        mortalityCountLstNdx = [listOfMortalityCounts listBegin: modelZone];
  
    }

    return mortSymbol;
}


//////////////////////////////////////////////////////////
//
// getReddMortalitySymbolWithName
//
//////////////////////////////////////////////////////////
- (id <Symbol>) getReddMortalitySymbolWithName: (char *) aName
{

    id <ListIndex> lstNdx;
    id aSymbol = nil;
    id mortSymbol = nil;
    char* mortName = NULL;

    lstNdx = [reddMortSymbolList listBegin: scratchZone]; 

    while(([lstNdx getLoc] != End) && ((aSymbol = [lstNdx next]) != nil))
    {
        mortName = (char *) [aSymbol getName];
        if(strncmp(aName, mortName, strlen(aName)) == 0) 
        {
           mortSymbol = aSymbol;
           [scratchZone free: mortName];
           mortName = NULL;
           break;
        }

        if(mortName != NULL)
        {
            [scratchZone free: mortName];
            mortName = NULL;
        }
    }
  
    [lstNdx drop];

    if(mortSymbol == nil)
    {
        mortSymbol = [Symbol create: modelZone setName: aName];
        [reddMortSymbolList addLast: mortSymbol];
    }

    return mortSymbol;
}


/////////////////////////////////////////
//
// getAgeSymbolForAge
//
/////////////////////////////////////////
- (id <Symbol>) getAgeSymbolForAge: (int) anAge
{
   int fishAge = anAge;

   if(fishAge >= 3)
   { 
      fishAge = 3;
   }

   return [ageSymbolList atOffset: fishAge];
}


////////////////////////////////////////////
//
// getReachSymbolWithName
//
////////////////////////////////////////////
- (id <Symbol>) getReachSymbolWithName: (char *) aName
{
    id <ListIndex> lstNdx;
    id aSymbol = nil;
    id reachSymbol = nil;
    char* reachName = NULL;

    //fprintf(stdout, "TroutModelSwarm >>>> getReachSymbolWithName >>>> BEGIN\n");
    //fflush(0);

    lstNdx = [reachSymbolList listBegin: scratchZone]; 

    while(([lstNdx getLoc] != End) && ((aSymbol = [lstNdx next]) != nil))
    {
        reachName = (char *) [aSymbol getName];
        if(strncmp(aName, reachName, strlen(aName)) == 0) 
        {
           reachSymbol = aSymbol;
           [scratchZone free: reachName];
           reachName = NULL;
           break;
        }

        if(reachName != NULL) 
        {
           [scratchZone free: reachName];
           reachName = NULL;
        }
    }
  
    [lstNdx drop];

    if(reachSymbol == nil)
    {
        reachSymbol = [Symbol create: modelZone setName: aName];
        [reachSymbolList addLast: reachSymbol];
    }


    //fprintf(stdout, "TroutModelSwarm >>>> getReachSymbolWithName >>>> END\n");
    //fflush(0);


    return reachSymbol;

}

/////////////////////////////////////////////
//
// getReddBinomialDist
//
////////////////////////////////////////////
- (id <BinomialDist>) getReddBinomialDist
{
   return reddBinomialDist;
}


//////////////////////////////////////////////////////
//
// createBreakoutReporters
//
/////////////////////////////////////////////////////
- createBreakoutReporters
{

  BOOL fileOverWrite = TRUE;
  BOOL suppressBreakoutColumns = NO;

  if(appendFiles == TRUE)
  {
     fileOverWrite = FALSE;
  }

  if((scenario != 1) || (replicate != 1))
  {
      suppressBreakoutColumns = YES;
      fileOverWrite = FALSE;
  }
      
  //
  // Fish mortality reporter
  //
  fishMortalityReporter = [BreakoutReporter   createBeginWithCSV: modelZone
                                                  forList: deadFish
                                       //withOutputFilename: "FishMortality.rpt"
                                       withOutputFilename: (char *) fishMortalityFile
                                        withFileOverwrite: fileOverWrite];
					//withColumnWidth: 25];


  [fishMortalityReporter addColumnWithValueOfVariable: "scenario"
                                        fromObject: self
                                          withType: "int"
                                         withLabel: "Scenario"];

  [fishMortalityReporter addColumnWithValueOfVariable: "replicate"
                                        fromObject: self
                                          withType: "int"
                                         withLabel: "Replicate"];

  [fishMortalityReporter addColumnWithValueOfVariable: "modelDate"
                                        fromObject: self
                                          withType: "string"
                                         withLabel: "ModelDate"];

  [fishMortalityReporter breakOutUsingSelector: @selector(getReachSymbol)
                                withListOfKeys: reachSymbolList];

  [fishMortalityReporter breakOutUsingSelector: @selector(getSpecies)
                                withListOfKeys: speciesSymbolList];

  [fishMortalityReporter breakOutUsingSelector: @selector(getAgeSymbol)
                                withListOfKeys: ageSymbolList];

  [fishMortalityReporter breakOutUsingSelector: @selector(getCauseOfDeath)
                                withListOfKeys: fishMortSymbolList];

  [fishMortalityReporter createOutputWithLabel: "Count"
                                  withSelector: @selector(getFishCount)
                              withAveragerType: "Count"];

  [fishMortalityReporter suppressColumnLabels: suppressBreakoutColumns];

  fishMortalityReporter = [fishMortalityReporter createEnd];


  //
  // Live fish reporter
  //
  liveFishReporter = [BreakoutReporter   createBeginWithCSV: modelZone
                                             forList: liveFish
                                  //withOutputFilename: "LiveFish.rpt"
                                  withOutputFilename: (char *) fishOutputFile
                                   withFileOverwrite: fileOverWrite];
  //withColumnWidth: 25];


  [liveFishReporter addColumnWithValueOfVariable: "scenario"
                                      fromObject: self
                                        withType: "int"
                                       withLabel: "Scenario"];

  [liveFishReporter addColumnWithValueOfVariable: "replicate"
                                      fromObject: self
                                        withType: "int"
                                       withLabel: "Replicate"];

  [liveFishReporter addColumnWithValueOfVariable: "modelDate"
                                      fromObject: self
                                        withType: "string"
                                       withLabel: "ModelDate"];

  [liveFishReporter breakOutUsingSelector: @selector(getReachSymbol)
                           withListOfKeys: reachSymbolList];

  [liveFishReporter breakOutUsingSelector: @selector(getSpecies)
                           withListOfKeys: speciesSymbolList];

  [liveFishReporter breakOutUsingSelector: @selector(getAgeSymbol)
                           withListOfKeys: ageSymbolList];

  [liveFishReporter createOutputWithLabel: "Count"
                             withSelector: @selector(getFishCount)
                         withAveragerType: "Count"];

  [liveFishReporter createOutputWithLabel: "MeanLength"
                             withSelector: @selector(getFishLength)
                         withAveragerType: "Average"];

  [liveFishReporter createOutputWithLabel: "TotalWeight"
                             withSelector: @selector(getFishWeight)
                         withAveragerType: "Total"];

  [liveFishReporter createOutputWithLabel: "MeanWeight"
                             withSelector: @selector(getFishWeight)
                         withAveragerType: "Average"];

  [liveFishReporter suppressColumnLabels: suppressBreakoutColumns];

  liveFishReporter = [liveFishReporter createEnd];

  return self;
}





//////////////////////////////////////////////////
//
// outputBreakoutReports
//
/////////////////////////////////////////////////
- outputBreakoutReports
{
  //  fprintf(stderr, "TroutModelSwarm >>>> outputBreakoutReports >>> BEGIN\n");
  //  fflush(0);

   [fishMortalityReporter updateByReplacement];
   [fishMortalityReporter output];

   [liveFishReporter updateByReplacement];
   [liveFishReporter output];

   [deadFish deleteAll];

  //  fprintf(stderr, "TroutModelSwarm >>>> outputBreakoutReports >>> END\n");
  //  fflush(0);

   return self;
}


///////////////////////////////////////////////
//
// createYearShuffler
//
///////////////////////////////////////////////
- createYearShuffler
{
   startDay = [timeManager getDayOfMonthWithTimeT: runStartTime];
   startMonth = [timeManager getMonthWithTimeT: runStartTime];
   startYear = [timeManager getYearWithTimeT: runStartTime];

   endDay = [timeManager getDayOfMonthWithTimeT: runEndTime];
   endMonth = [timeManager getMonthWithTimeT: runEndTime];
   endYear = [timeManager getYearWithTimeT: runEndTime];

   if(shuffleYearSeed < 0.0)
   {
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> createYearShuffler >>> shuffleYearSeed less than 0\n");
      fflush(0);
      exit(1);
   }

   yearShuffler = [YearShuffler   createBegin: modelZone 
                                withStartTime: runStartTime
                                  withEndTime: runEndTime
                              withReplacement: shuffleYearReplace
                              withRandGenSeed: shuffleYearSeed
                              withTimeManager: timeManager];

   yearShuffler = [yearShuffler createEnd];

   if([[yearShuffler getListOfRandomizedYears] getCount] <= 1)
   {
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> createYearShuffler >>>> Cannot use year shuffler for simulations of one year or less\n");
       fflush(0);
       exit(1);
   }

   //
   // Now calculate dataStartTime and dataEndTime
   //
   {
       int numSimYears = [[yearShuffler getListOfRandomizedYears] getCount];
       int dataEndYear = [timeManager getYearWithTimeT: runStartTime] + numSimYears;
       int dataEndMonth = startMonth;
       int dataEndDay = startDay;

       sprintf(dataEndDate, "%d/%d/%d", dataEndMonth, dataEndDay, dataEndYear);
       dataStartTime = runStartTime;
       dataEndTime = [timeManager getTimeTWithDate: dataEndDate
                                          withHour: 12
                                        withMinute: 0
                                        withSecond: 0];

       dataEndTime = dataEndTime + 86400;

       fprintf(stdout, "TroutModelSwarm >>>> createYearShuffler >>>> numSimYears %d\n", numSimYears);
       fprintf(stdout, "TroutModelSwarm >>>> createYearShuffler >>>> startYear %d endYear %d\n", startYear, endYear);
       fflush(0);
   }

   return self;
}


///////////////////////////////////////////////
//
// updateMortalityCountWith
//
///////////////////////////////////////////////
- updateMortalityCountWith: aDeadFish
{
   TroutMortalityCount* mortalityCount = nil;
   id <Symbol> causeOfDeath = [aDeadFish getCauseOfDeath];
   BOOL ERROR = YES;


   [mortalityCountLstNdx setLoc: Start];
    while(([mortalityCountLstNdx getLoc] != End) && ((mortalityCount = [mortalityCountLstNdx next]) != nil))
    {
         if(causeOfDeath == [mortalityCount getMortality])
         {
             [mortalityCount incrementNumDead];
             ERROR = NO;
             break;
         }
    }

    if(ERROR)
    {
        fprintf(stderr, "TroutModelSwarm >>>> updateMortalityCountWith >>>> mortality source not found in object TroutMortalityCount\n");
        fflush(0);
        exit(1);
    }

   return self;
}


- (id <List>) getListOfMortalityCounts
{
   return listOfMortalityCounts;
}


///////////////////////////////////////
//
// toggleFishForHabSurvUpdate
//
/////////////////////////////////////
- toggleFishForHabSurvUpdate
{
    id <ListIndex> ndx = nil;
    id fish = nil;
    id prevFish = nil;
    BOOL fishGTEMinPiscLength = NO;
    BOOL fishLTMinPiscLength = NO;
    
     
//    fprintf(stdout, "TroutModelsSwarm >>>> toggleFishForHabSurvUpdate >>>> BEGIN\n");
//    fflush(0);

    // The variable toggleFishForHabSurvUpdate is set each day by the model swarm
    // method toggleFishForHabSurvUpdate, part of the updateActions.
    // It is set to yes if this fish is either (a) the smallest
    // piscivorous fish or (b) the last fish. The aquatic predation
    // survival probability needs to be updated when this fish moves. 

  if([liveFish getCount] > 0)
  {
    if((fish = [liveFish getFirst]) != nil)
    {
        if([fish getFishLength] >= minSpeciesMinPiscLength) 
        {
            fishGTEMinPiscLength = YES; 
        }
    }
    if((fish = [liveFish getLast]) != nil)
    {
        if([fish getFishLength] < minSpeciesMinPiscLength) 
        {
            fishLTMinPiscLength = YES; 
        }
    }

    if((fishGTEMinPiscLength == YES) && (fishLTMinPiscLength == YES))
    { 
        ndx = [liveFish listBegin: scratchZone];
        while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil))
        {
            if([fish getFishLength] < minSpeciesMinPiscLength) 
            {
                //fprintf(stdout, "TroutModelsSwarm >>>> toggleFishForHabSurvUpdate >>>> fish getFishLength = %f\n", [fish getFishLength]);
                //fprintf(stdout, "TroutModelsSwarm >>>> toggleFishForHabSurvUpdate >>>> prevFish getFishLength = %f\n", [prevFish getFishLength]);
                //fflush(0);

                [prevFish toggleFishForHabSurvUpdate];
                break;
            }
            prevFish = fish;
        }
        [ndx drop];
    }
    else
    {
        //
        // Let the last fish regardless of length update the 
        // habitat aq pred survival probs -- needed in die
        //

        if((fish = [liveFish getLast]) != nil)
        {
           //fprintf(stdout, "TroutModelsSwarm >>>> toggleFishForHabSurvUpdate >>>> LAST fish getFishLength = %f\n", [fish getFishLength]);
           //fflush(0);

           [fish toggleFishForHabSurvUpdate];
        }
    }

  }  // if count > 0
//    fprintf(stdout, "TroutModelsSwarm >>>> toggleFishForHabSurvUpdate >>>> END\n");
//    fflush(0);

    return self;
}


////////////////////////////////////
//
// updateHabSurvProbs
//
////////////////////////////////////
- updateHabSurvProbs
{
   [reachList forEach: M(updateHabSurvProbForAqPred)];
   return self;
}



//////////////////////////////////////////////////////////
//
// drop
//
//////////////////////////////////////////////////////////
- (void) drop 
{
  //fprintf(stderr, "TroutModelSwarm >>>> drop >>>> BEGIN\n");
  //fflush(0);

  if(reddSummaryFilePtr != NULL){
      fclose(reddSummaryFilePtr);
  }
  if(reddRptFilePtr != NULL){
      fclose(reddRptFilePtr);
  }
  if(timeManager){
    //  fprintf(stderr, "TroutModelSwarm >>>> drop >>>> dropping timeManager\n");
    //  fflush(0);

      [timeManager drop];
      timeManager = nil;
  }

  if(fishColorMap)
  {
       id <MapIndex> mapNdx = [fishColorMap mapBegin: scratchZone];
       long* aFishColor = (long *) nil;
 
       while(([mapNdx getLoc] != End) && ((aFishColor = (long *) [mapNdx next]) != (long *) nil))
       {
            [modelZone free: aFishColor];
       }

       [mapNdx drop];
       [fishColorMap drop];
    
       [speciesSymbolList deleteAll];
       [speciesSymbolList drop];
       speciesSymbolList = nil;
  }
  if(randGen){
      [randGen drop]; 
      randGen = nil;
  }
  if(modelZone != nil){
      int speciesIDX = 0;
      //fprintf(stderr, "TroutModelSwarm >>>> drop >>>> dropping objects in  modelZone >>>> BEGIN\n");
      //fflush(0);
 
      [modelZone free: mySpecies];
      [modelZone free: modelDate];

      for(speciesIDX=0;speciesIDX<numberOfSpecies;speciesIDX++) {
          [modelZone free: speciesName[speciesIDX]];
          [modelZone free: speciesParameter[speciesIDX]];
          [modelZone free: speciesPopFile[speciesIDX]];
          [modelZone free: speciesColor[speciesIDX]];
      }
      [modelZone free: speciesName];
      [modelZone free: speciesParameter];
      [modelZone free: speciesPopFile];
      [modelZone free: speciesColor];

      [modelZone free: MyTroutClass];

      //
      // drop interpolation tables
      //
    [spawnVelocityInterpolatorMap deleteAll];
    [spawnVelocityInterpolatorMap drop];
    spawnVelocityInterpolatorMap = nil;
    [spawnDepthInterpolatorMap deleteAll];
    [spawnDepthInterpolatorMap drop];
    spawnDepthInterpolatorMap = nil;
    [cmaxInterpolatorMap deleteAll];
    [cmaxInterpolatorMap drop];
    cmaxInterpolatorMap = nil;
     //
     // End drop interpolation tables
     //
    //fprintf(stdout, "After drop interpolationTables\n");
    //fflush(0);


    //fprintf(stdout, "Before drop capture logistic\n");
    //fflush(0);
     //
     // drop capture logistics
     //
    [captureLogisticMap deleteAll];
    [captureLogisticMap drop];
    captureLogisticMap = nil;
     //
     // drop capture logistics
     //
    //fprintf(stdout, "After drop capture logistic\n");
    //fflush(0);

     [mortalityCountLstNdx drop];
     mortalityCountLstNdx = nil;
  
     [listOfMortalityCounts deleteAll];
     [listOfMortalityCounts drop];
      listOfMortalityCounts = nil; 

     [liveFish deleteAll];
     [liveFish drop];
     liveFish = nil;
     [updateActions drop];
     updateActions = nil;
     [initAction drop];
     initAction = nil;
     [fishActions drop];
     fishActions = nil;
     [reddActions drop];
     reddActions = nil;
     [modelActions drop];
     modelActions = nil;
     [overheadActions drop];
     overheadActions = nil;
  #ifdef PRINT_CELL_FISH_REPORT
     [printCellFishAction drop];
     printCellFishAction = nil;
  #endif

     [modelSchedule drop];
     modelSchedule = nil;
     [printSchedule drop];
     printSchedule = nil;
      
     // The following produces error: FallChinook does not recognize drop
     //[speciesClassList deleteAll];
     //[speciesClassList drop];
     //speciesClassList = nil;
        
     [reddBinomialDist drop];
     reddBinomialDist = nil;
        
     [deadFish deleteAll];
     [deadFish drop];
     deadFish = nil;

     [killedFish deleteAll];
     [killedFish drop];
     killedFish = nil;


     [reddRemovedList deleteAll];
     [reddRemovedList drop];
     reddRemovedList = nil;
   
     [emptyReddList deleteAll];
     [emptyReddList drop];
     emptyReddList = nil;

     [reddList deleteAll];
     [reddList drop];
     reddList = nil;

     //[Male drop];
     Male = nil;
     //[Female drop];
     Female = nil;

     if(yearShuffler != nil){
          [yearShuffler drop];
          yearShuffler = nil;
     }

     [fishMortalityReporter drop];
     fishMortalityReporter = nil;

     [liveFishReporter drop];
     liveFishReporter = nil;

     //
     // Drop the fishParams
     //
    [fishParamsMap deleteAll];
    [fishParamsMap drop];
    fishParamsMap = nil;

     [fishMortSymbolList deleteAll];
     [fishMortSymbolList drop];
     fishMortSymbolList = nil;

     [reddMortSymbolList deleteAll];
     [reddMortSymbolList drop];
     reddMortSymbolList = nil;

     [ageSymbolList deleteAll];
     [ageSymbolList drop];
     ageSymbolList = nil;

     [reachSymbolList deleteAll];
     [reachSymbolList drop];
     reachSymbolList = nil;

      if(habitatManager){
          [habitatManager drop];
          habitatManager = nil;
      }

 //    [self outputModelZone: modelZone];

     [modelZone drop];
     modelZone = nil;

     //fprintf(stdout, "TroutModelSwarm >>>> drop >>>> dropping modelZone >>>> END\n");
     //fflush(0);
  }
  
  [super drop];

  //fprintf(stdout, "TroutModelSwarm >>>> drop >>>> END\n");
  //fflush(0);

  //exit(0);

} //drop




//////////////////////////////////
//
// outputModelZone
//
/////////////////////////////////////
- outputModelZone: (id <Zone>) anArbitraryZone
{
   id <ListIndex> ndx = nil;
   id obj = nil;
   //int liveFishCount = 0;
   //int deadFishCount = 0;

   int numberOfRT = 0;
   int numberOfBT = 0;
   int totalZoneFishCount = 0;
   //int objCount = 0;

   FILE* zout = NULL;

   fprintf(stdout, "\n\n\nTroutModelSwarm >>>> outputModelZone >>>> BEGIN\n");
   fflush(0);
    

   if((zout = fopen("ZoneOutputFile.txt", "a")) == NULL) 
   {
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> outputModelZone >>>> Error opening %s \n", "ZoneOutputFile.txt");
       fflush(0);
       exit(1);
   }
   
   fprintf(zout, "\n\n\nTroutModelSwarm >>>> outputModelZone >>>> BEGIN\n");
   fflush(0);
  
/*
 
   ndx = [[anArbitraryZone getPopulation] listBegin: scratchZone];
   //ndx = [[modelZone getPopulation] listBegin: scratchZone];
   //ndx = [[globalZone getPopulation] listBegin: scratchZone];
   while(([ndx getLoc] != End) && ((obj = [ndx next]) != nil))
   {
          Class aClass = Nil;
          Class ZoneClass = objc_get_class("ZoneAllocMapper");
          char aClassName[20];
          char ZoneClassName[20];

          aClass = object_get_class(obj);

          strncpy(aClassName, class_get_class_name(aClass), 20);   
          strncpy(ZoneClassName, class_get_class_name(ZoneClass), 20);   

          //if(strncmp(aClassName, ZoneClassName, 20) == 0)
          {
              objCount++;
              fprintf(zout, "Class name = %s\n", class_get_class_name (aClass));
              //fprintf(zout, "Class name = %s\n", class_get_class_name (ZoneClass));
              fprintf(zout, "objCount = %d\n", objCount);
              fflush(0);
          } 

    }
    [ndx drop];
*/
   
   ndx = [[anArbitraryZone getPopulation] listBegin: scratchZone];
   while(([ndx getLoc] != End) && ((obj = [ndx next]) != nil))
   {
          Class aClass = Nil;
          Class ZoneClass = objc_get_class("Cutthroat");
          char aClassName[20];
          char ZoneClassName[20];

          aClass = object_get_class(obj);

          strncpy(aClassName, class_get_class_name(aClass), 20);   
          strncpy(ZoneClassName, class_get_class_name(ZoneClass), 20);   


          //if(strncmp(aClassName, ZoneClassName, 20) == 0)
          {
              fprintf(zout, "Class name = %s\n", class_get_class_name (aClass));
              //fprintf(zout, "Class name = %s\n", class_get_class_name (ZoneClass));
              fflush(0);
              if([obj respondsTo: @selector(drop)])
              {
                  fprintf(zout, "Object responds to drop\n");
                  fflush(zout);
              }
              numberOfBT++;
          } 
    }
    [ndx drop];

    totalZoneFishCount = numberOfRT + numberOfBT;

    {
         //char* zBuf[300];
         id <OutputStream> catC = [OutputStream create: anArbitraryZone
                                         setFileStream: zout];
         fprintf(zout, "TroutModelSwarm >>>> outputModelZone >>>> testMemZone describe >>>> BEGIN\n");
         fflush(0);
         [anArbitraryZone describe: catC];
         //fprintf(zout," zBuf = %s\n", zBuf);
         //fflush(zout);

         fprintf(zout, "TroutModelSwarm >>>> outputModelZone >>>> testMemZone describe >>>> END\n");
         fflush(0);
         [catC drop];
    }

    fprintf(zout, "TroutModelSwarm >>>> outputModelZone >>>> END\n\n\n");
    fflush(0);
    fclose(zout);



    fprintf(stdout, "TroutModelSwarm >>>> outputModelZone >>>> END\n\n\n");
    fflush(0);


   return self;
}

@end

