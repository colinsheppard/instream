/*
inSTREAM Version 4.3, September 2006
Individual-based stream trout modeling software. Developed and maintained by Steve Railsback (Lang, Railsback & Associates, Arcata, California) and
Steve Jackson (Jackson Scientific Computing, McKinleyville, California).
Development sponsored by EPRI, US EPA, USDA Forest Service, and others.
Copyright (C) 2006 Lang, Railsback & Associates.

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




#import "HabitatSpace.h"
#import "Trout.h"
#import "Redd.h"

#import "FishCell.h"

@implementation FishCell

+ create: aZone 
{
  FishCell* fishCell = [super create: aZone];

  fishCell->cellFracSpawn = 0.0;
  fishCell->cellFracShelter = 0.0;
  fishCell->cellDistToHide = 0.0;

  fishCell->cellDataSet = NO;

  return fishCell;
}



////////////////////////////////////
//
// getCellVelocity
//
///////////////////////////////////
- (double) getCellVelocity
{
    return [super getPolyCellVelocity];
}


///////////////////////////////////////////
//
// setShadeColorMax
//
///////////////////////////////////////////
- setShadeColorMax: (double) aShadeColorMax
{
       shadeColorMax = aShadeColorMax;
       return self;
}


//////////////////////////////////////////
//
// toggleColorRep
//
//////////////////////////////////////////
- toggleColorRep: (double) aShadeColorMax
{
   fprintf(stdout, "FishCell >>>> toggleColorRep >>>> BEGIN\n");
   fflush(0);

   if(strncmp(rasterColorVariable, "depth",5) == 0)
   {
       strncpy(rasterColorVariable, "velocity", 9);
   }
   else if(strncmp(rasterColorVariable, "velocity",8) == 0)
   {
       strncpy(rasterColorVariable, "depth", 6);
   }
   else
   {
       fprintf(stderr, "ERROR: FishCell >>>> toggleColorRep >>>> incorrect rasterColorVariable\n");
       fflush(0);
       exit(1);
   }

   shadeColorMax = aShadeColorMax;

   fprintf(stdout, "FishCell >>>> toggleColorRep >>>> END\n");
   fflush(0);

   return self;
}

/////////////////////////////////////////////////////////////////////
//
// drawSelfOn
//
/////////////////////////////////////////////////////////////////////
- drawSelfOn: (id <Raster>) aRaster 
{
  int maxIndex;
  double colorVariable = 0.0;
  double colorRatio;
  int i;

  // new from Colin 2011-04-01
  id aRedd;
  int pixToUse;
  double numToDraw;
  double counter;
  // endnew from Colin

  //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> BEGIN\n");
  //fflush(0);

  //
  // don't call super, do all of the work here 
  //

   if(rasterColorVariable == NULL)
   {
       fprintf(stderr, "ERROR: FishCell >>>> drawSelfOn >>>> rasterColorVariable has not been set\n");
       fflush(0);
       exit(1);
   }

   if(strcmp("depth",rasterColorVariable) == 0) 
   {
        colorVariable = polyCellDepth; 
   }
   else if(strcmp("velocity",rasterColorVariable) == 0) 
   {
        colorVariable = polyCellVelocity; 
   }
   else 
   {
         fprintf(stderr, "ERROR: FishCell >>>> draswSelfOn >>>> Unknown rasterColorVariable value = %s\n",rasterColorVariable);
         fflush(0);
         exit(1);
   }

   if(fabs(shadeColorMax) <= 0.000000001)
   {
       fprintf(stderr, "ERROR: FishCell >>>> drawSelfOn >>>> shadeColorMax is 0.0\n");
       fflush(0);
       exit(1);
   }
   colorRatio = colorVariable/shadeColorMax; 

//  New shading code 1/14/2011 SFR

   if (colorRatio >= 1.0)
    {
      colorRatio = 0.99;  // so interiorColor truncates to CELL_COLOR_MAX - 1
    }

   interiorColor = (int) ( ((double) CELL_COLOR_MAX) * colorRatio);

   //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> colorVariable = %f\n",colorVariable);
   //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> shadeColorMax = %f\n",shadeColorMax);
   //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> colorRatio = %f\n",colorRatio);
   //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> maxIndex = %d\n",maxIndex);
   //fflush(0);
   
   if(tagCell)
   {
      interiorColor = TAG_CELL_COLOR;
   }
   if(1)
   {

     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> maxIndex = %d\n", maxIndex);
     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> interiorColor = %d\n", interiorColor);
     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> polyCellDepth = %f\n", polyCellDepth);
     //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> polyCellVelocity = %f\n", polyCellVelocity);
     //fflush(0);
      

      for(i = 0;i < pixelCount; i++)
      {
          [aRaster drawPointX: polyCellPixels[i]->pixelX Y: polyCellPixels[i]->pixelY Color: interiorColor];
      }

      numberOfNodes = [polyPointList getCount];
      for(i = 1; i < numberOfNodes; i++) 
      { 
          [aRaster lineX0: [[polyPointList atOffset: i - 1] getDisplayX]
                       Y0: [[polyPointList atOffset: i - 1] getDisplayY]
                       X1: [[polyPointList atOffset: i % numberOfNodes] getDisplayX]
                       Y1: [[polyPointList atOffset: i % numberOfNodes] getDisplayY]
                    Width: 1
                    Color: POLYBOUNDARYCOLOR];

      }
   }
  
  
  // new from Colin 2011-04-01
   numToDraw = (double) [fishIContain getCount];
   if(numToDraw > 0.0)
   {
       counter = 0.0;
       id <ListIndex> ndx;
       ndx = [fishIContain listBegin: scratchZone];
       Trout* fish = nil;

       while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil))
       {    
          counter = counter + 1.0;
          pixToUse = (int) (pixelCount * (counter / (numToDraw + 1.0)));
           [fish drawSelfOn: aRaster 
                        atX: polyCellPixels[pixToUse]->pixelX 
                          Y: polyCellPixels[pixToUse]->pixelY];
       }
  
       [ndx drop];
   }


 
   if([reddsIContain getCount] > 0);
   {
        id <ListIndex> ndx = [reddsIContain listBegin: scratchZone];
 
        while(([ndx getLoc] != End) && ((aRedd = [ndx next]) != nil)) 
        {
             [aRedd drawSelfOn: aRaster];
             }
        [ndx drop];
  }
  // endnew from Colin 2011-04-01

  // new from Colin 2011-04-01
  // Commented out the following
/*
   if([fishIContain getCount] > 0)
   {
       id <ListIndex> ndx;
       ndx = [fishIContain listBegin: scratchZone];
       Trout* fish = nil;

       while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil))
       {    
           [fish drawSelfOn: aRaster 
                        atX: displayCenterX 
                          Y: displayCenterY];
       }
  
       [ndx drop];
   }

  // endnew from Colin 2011-04-01


   if([reddList getCount] > 0);
   {
        id <ListIndex> ndx = [reddList listBegin: scratchZone];
        UTMRedd* redd = nil;
 
        while(([ndx getLoc] != End) && ((redd = [ndx next]) != nil)) 
        {
             [redd drawSelfOn: aRaster
                          atX: displayCenterX 
                            Y: displayCenterY];
             }
        [ndx drop];
  }
*/

  //fprintf(stdout, "FishCell >>>> drawSelfOn >>>> END\n");
  //fflush(0);

  return self;
}






///////////////////////////////////////////////
//
// buildObjects
//
//////////////////////////////////////////////
- buildObjects 
{
  if(myRandGen == nil)
  {
     fprintf(stderr, "ERROR: FishCell >>>> buildObjects >>>> myRandGen is nil\n");
     fflush(0);
     exit(1);
  } 

  //
  // misc initializations
  //
  fishIContain  = [List create: cellZone];
  reddsIContain = [List create: cellZone];
  listOfAdjacentCells = [List create: cellZone];

  if(fishParamsMap == nil)
  {
     fprintf(stderr, "ERROR: Cell >>>> buildObjects >>>> fishParamsMap is nil\n");
     fflush(0);
     exit(1);
  }

  [self initializeSurvProb];

  foodReportFirstTime=YES;
  depthVelRptFirstTime=YES;
 
  return self;
}


////////////////////////////////////
//
// setRandGen
//
//////////////////////////////////
- setRandGen: aRandGen
{
    myRandGen = aRandGen;
    return self;
}

//////////////////////////////////////
//
// getRandGen
//
//////////////////////////////////////
- getRandGen
{
    return myRandGen;
}

/////////////////////////////////////////////////////////////////////
//
// setSpace
//
////////////////////////////////////////////////////////////////////
- setSpace: aSpace 
{
   space = aSpace;
   return self;
}




////////////////////////////////////////////////////////////////////
//
// getSpace
//
///////////////////////////////////////////////////////////////////
- getSpace 
{
  return space;
}



/////////////////////////////////
//
// setReach
//
////////////////////////////////
- setReach: aReach
{
   reach = aReach;
   return self;
}


//////////////////////////////////
//
// getReach
//
/////////////////////////////////
- getReach
{
   return reach;
}



///////////////////////////////////////
//
// setReachEnd
//
///////////////////////////////////////
- setReachEnd: (char) aReachEnd
{
     reachEnd = aReachEnd;
     return self;
}


//////////////////////////////////////
//
// getReachEnd
//
//////////////////////////////////////
- (char) getReachEnd
{
     return reachEnd;
}


//////////////////////////////////////////
//
// calcCellDistToUS
//
//////////////////////////////////////////
- calcCellDistToUS
{
    id <List> upstreamCells = [reach getUpstreamCells];

    if([upstreamCells contains: self]) 
    {
             cellDistToUS = 0.0;
    }
    else
    {
        id <ListIndex> ndx = [upstreamCells listBegin: scratchZone];
        FishCell* oFishCell = nil;
    
        double oPolyCenterX = 0.0;
        double oPolyCenterY = 0.0;

        double distToUS     = (double) 1.0E99;

        cellDistToUS = (double) 1.0E99;

        while(([ndx getLoc] != End) && ((oFishCell = [ndx next]) != nil))
        {
                 oPolyCenterX = [oFishCell getPolyCenterX];
                 oPolyCenterY = [oFishCell getPolyCenterY];

                 distToUS = sqrt(pow((polyCenterX - oPolyCenterX), 2) + pow((polyCenterY - oPolyCenterY), 2));

                 cellDistToUS = (cellDistToUS < distToUS) ? cellDistToUS : distToUS; 
        }

        [ndx drop];
        ndx = nil;
    }

    //fprintf(stdout, "FishCell >>>> calcCellDistToUS >>>> cellNumber = %d >>>>> cellDistToUS = %f\n", polyCellNumber, cellDistToUS);
    //fflush(0);

    return self;
}


//////////////////////////////////////////////
//
// calcCellDistToDS
//
///////////////////////////////////////////////
- calcCellDistToDS
{
    id <List> downstreamCells = [reach getDownstreamCells];

    if([downstreamCells contains: self]) 
    {
             cellDistToDS = 0.0;
    }
    else
    {
        id <ListIndex> ndx = [downstreamCells listBegin: scratchZone];
        FishCell* oFishCell = nil;
    
        double oPolyCenterX = 0.0;
        double oPolyCenterY = 0.0;

        double distToDS     = (double) 1.0E99;

        cellDistToDS = (double) 1.0E99;

        while(([ndx getLoc] != End) && ((oFishCell = [ndx next]) != nil))
        {
                 oPolyCenterX = [oFishCell getPolyCenterX];
                 oPolyCenterY = [oFishCell getPolyCenterY];

                 distToDS = sqrt(pow((polyCenterX - oPolyCenterX), 2) + pow((polyCenterY - oPolyCenterY), 2));

                 cellDistToDS = (cellDistToDS < distToDS) ? cellDistToDS : distToDS; 
        }

        [ndx drop];
        ndx = nil;
    }

    //fprintf(stdout, "FishCell >>>> calcCellDistToDS >>>> cellNumber = %d >>>>> cellDistToDS = %f\n", polyCellNumber, cellDistToDS);
    //fflush(0);

    return self;
}



/////////////////////////////////
//
// getCellDistToUS
//
/////////////////////////////////
- (double) getCellDistToUS
{
     return cellDistToUS;
}


/////////////////////////////////
//
// getCellDistToDS
//
/////////////////////////////////
- (double) getCellDistToDS
{
     return cellDistToDS;
}


/////////////////////////////////////////////////////
//
// setTimeManager
//
/////////////////////////////////////////////////////
- setTimeManager: (id <TimeManager>) aTimeManager
{
     timeManager = aTimeManager;
     return self;
}

/////////////////////////////////////////////
//
// setModel
//
/////////////////////////////////////////////
- setModel: (id <TroutModelSwarm>) aModel
{
    model = (id <TroutModelSwarm>) aModel;
    return self;
}


//////////////////////////////////////
//
// setFishParamsMap
//
/////////////////////////////////////
- setFishParamsMap: (id <Map>) aMap
{
    fishParamsMap = aMap;
    return self;
}



///////////////////////////////////////////
//
// setNumberOfSpecies
//
///////////////////////////////////////////

- setNumberOfSpecies: (int) aNumberOfSpecies
{
    numberOfSpecies = aNumberOfSpecies;
    return self;
}



//////////////////////////////////////////////
//
// setHabShearParamA:habShearParamB
//
////////////////////////////////////////////
- setHabShearParamA: (double) aHabShearParamA
     habShearParamB: (double) aHabShearParamB
{
    habShearParamA = aHabShearParamA;
    habShearParamB = aHabShearParamB;
    return self;
}


////////////////////////////////////////
//
// getHabShearParamA
//
////////////////////////////////////////
- (double) getHabShearParamA
{
   return habShearParamA;
}


////////////////////////////////////////
//
// getHabShearParamB
//
////////////////////////////////////////
- (double) getHabShearParamB
{
   return habShearParamB;
}

////////////////////////////////////////////////////
//
// setHabSheltSpeedFrac
//
////////////////////////////////////////////////////
- setHabShelterSpeedFrac: (double) aShelterSpeedFrac
{
    habShelterSpeedFrac = aShelterSpeedFrac;
    return self;
}


///////////////////////////////////////////////
//
// getHabShelterSpeedFrac
//
///////////////////////////////////////////////
- (double) getHabShelterSpeedFrac
{
   return habShelterSpeedFrac;
}


////////////////////////////////////////////////////////
//
// setDistanceToHide
//
///////////////////////////////////////////////////////
- setDistanceToHide: (double) aDistance 
{
  cellDistToHide = aDistance;
  return self;
}


//////////////////////////////////////////////////////
//
// getDistanceToHide
//
/////////////////////////////////////////////////////
- (double) getDistanceToHide 
{
   return cellDistToHide;
}



/*
- drawSelfOn: (id <Raster>) aRaster 
{
  double colorVariable=0.0;
  int i, numfishincell;
  int j, numReddsInCell;
  id <ListIndex> numFishNdx;
  id <ListIndex> numReddsNdx;
  id fish;
  id redd;

  // first calculate color to use
  // [0,100] use continous scale
  // [101,1000] use bin values

    if(strcmp("depth",rasterColorVariable) == 0) 
    {
      colorVariable = depth; 
    }
    else if(strcmp("velocity",rasterColorVariable) == 0) 
    {
    colorVariable = velocity; 
    }
    else 
    {
        fprintf(stderr, "ERROR: Unknown rasterColorVariable value = %s\n",rasterColorVariable);
        fflush(0);
        exit(1);
    }

  if ((0.0 <= colorVariable) && (colorVariable <= 100.0))
    myColor = (int)(colorVariable/COLOR_MODIFIER + 0.5);
  else if ((100.0 < colorVariable) && (colorVariable <= 150.0))
    myColor = 55L;
  else if ((150.0 < colorVariable) && (colorVariable <= 200.0))
    myColor = 56L;
  else if ((200.0 < colorVariable) && (colorVariable <= 250.0))
    myColor = 57L;
  else if ((250.0 < colorVariable) && (colorVariable <= 300.0))
    myColor = 58L;
  else if ((300.0 < colorVariable) && (colorVariable <= 350.0))
    myColor = 59L;
  else if ((350.0 < colorVariable) && (colorVariable <= 400.0))
    myColor = 60L;
  else if ((400.0 < colorVariable) && (colorVariable <= 450.0))
    myColor = 61L;
  else if ((450.0 < colorVariable) && (colorVariable <= 500.0))
    myColor = 62L;
  else if (500.0 < colorVariable)
    myColor = 63L;
  else
    myColor = 0L;

  // put a lower bound on the color
  if (myColor <= 0)
  {
      myColor = 1L;
  }

  if(tagCell)
  {
      myColor = TAG_CELL_COLOR;
  }

  [aRaster fillRectangleX0: 
               (int)([boundary[0] getElement: XCOORDINATE]/rasterResolutionX + 0.5)
           Y0: (int)([boundary[0] getElement: YCOORDINATE]/rasterResolutionY + 0.5)
           X1: (int)([boundary[3] getElement: XCOORDINATE]/rasterResolutionX + 0.5)
           Y1: (int)([boundary[3] getElement: YCOORDINATE]/rasterResolutionY + 0.5)
           Color: myColor ];

  [aRaster rectangleX0: (int)([boundary[0] getElement: XCOORDINATE]/rasterResolutionX + 0.5)
           Y0: (int)([boundary[0] getElement: YCOORDINATE]/rasterResolutionY + 0.5)
           X1: (int)([boundary[3] getElement: XCOORDINATE]/rasterResolutionX + 0.5)
           Y1: (int)([boundary[3] getElement: YCOORDINATE]/rasterResolutionY + 0.5)
           Width: 1
           Color: 0L ];






  // draw my fish

  numfishincell = [fishIContain getCount];
  numFishNdx = [fishIContain listBegin: scratchZone];
      if(numfishincell != 0) {
             i=1;
             while( ([numFishNdx getLoc] != End) && ((fish = [numFishNdx next]) != nil) ) {
              [fish drawSelfOn: aRaster atPosition: i  of: numfishincell];
              i++;
             }
      }
  [numFishNdx drop];





  // draw my Redds


  numReddsInCell = [reddsIContain getCount];
  numReddsNdx = [reddsIContain listBegin: scratchZone];
      if(numReddsInCell != 0) 
      {
             j=1;

             while( ([numReddsNdx getLoc] != End) && ((redd = [numReddsNdx next]) != nil) ) 
             {
                 [redd drawSelfOn: aRaster atPosition: j  of: numReddsInCell];
                 j++;
             }
      }
  [numReddsNdx drop];

  tagCell = NO;

  return self;
}
*/


/////////////////////////////////
//
// tagDestCells
//
////////////////////////////////
- tagDestCells
{
    tagCell = YES;
    return self;
}


///////////////////////////////////////////////
//
// getNeighborsWithin
//
//////////////////////////////////////////////
- getNeighborsWithin: (double) aRange 
            withList: (id <List>) aCellList
{
  //fprintf(stdout, "FishCell >>>> getNeighborsWithin >>>> BEGIN\n");
  //fflush(0);

  [space getNeighborsWithin: aRange 
                         of: self
                   withList: aCellList];

  //fprintf(stdout, "FishCell >>>> getNeighborsWithin >>>> END\n");
  //fflush(0);

  return self;
}

////////////////////////////////
//
// getNumberOfFish
//
///////////////////////////////
- (int) getNumberOfFish 
{
   return [fishIContain getCount];
}




//////////////////////////////////////////////////////////////////
//
// getNumberOfRedds
//
/////////////////////////////////////////////////////////////////
- (int) getNumberOfRedds 
{
  return [reddsIContain getCount];
}




//////////////////////////////////////////////////////////////////
//
// getFishIContain
//
/////////////////////////////////////////////////////////////////
- (id <List>) getFishIContain 
{
   return fishIContain;
}




//////////////////////////////////////////////////////////////////
//
// getReddsIContain
//
/////////////////////////////////////////////////////////////////
- (id <List>) getReddsIContain 
{
   return reddsIContain;
}


/*
///////////////////////////////////////////////////////////////////
//
// calcDepthAndVelocityWithIndex
//
///////////////////////////////////////////////////////////////////
- calcDepthAndVelocityWithIndex: (int) anInterpolationIndex
             withInterpFraction: (double) anInterpFraction
{
   aVelocity = [velocityInterpolator getValueWithTableIndex: anInterpolationIndex 
                                         withInterpFraction: anInterpFraction];

   aWsl = [wslInterpolator getValueWithTableIndex: anInterpolationIndex
                                   withInterpFraction: anInterpFraction];

   if(aDepth < 0.0)
    {
      aDepth = 0.0;
    }

   if(aVelocity < 0.0) 
   {
     aVelocity = 0.0;
   }

   velocity = aVelocity;
   depth = aDepth;

   return self;
}

*/

///////////////////////////////////////////
//
// getYesterdaysRiverFlow
//
/////////////////////////////////////////
- (double) getYesterdaysRiverFlow 
{
  return [space getYesterdaysRiverFlow];
}


///////////////////////////////////////////
//
// getRiverFlow
//
/////////////////////////////////////////
- (double) getRiverFlow 
{
  return [space getRiverFlow];
}


////////////////////////////////////////////////////////////////////
//
// getTomrrowsRiverFlow
//
////////////////////////////////////////////////////////////////////
- (double) getTomorrowsRiverFlow 
{
  return [space getTomorrowsRiverFlow];
}

////////////////////////////////////////////////////////////////////
//
// getFlowChange
//
////////////////////////////////////////////////////////////////////
- (double) getFlowChange 
{
    return [space getFlowChange];
}




//////////////////////////////////////////////////////////////////
//
// setCellFracShelter
//
//////////////////////////////////////////////////////////////////
- (void) setCellFracShelter: (double) aDouble 
{
    cellFracShelter = aDouble;
}


/////////////////////////////////////////////////////////////////
//
// calcCellShelterArea
//
////////////////////////////////////////////////////////////////
- (void) calcCellShelterArea 
{
    cellShelterArea = polyCellArea*cellFracShelter;
}

/////////////////////////////////////
//
// resetShelterAreaAvailable
//
////////////////////////////////////////
- (void) resetShelterAreaAvailable 
{
   shelterAreaAvailable = cellShelterArea;
 
   if(shelterAreaAvailable > 0.0)
   {
       isShelterAvailable = YES;
   }
   else
   {
       isShelterAvailable = NO;
   }
}


////////////////////////////////////
//
// getShelterAreaAvailable 
//
////////////////////////////////////
- (double) getShelterAreaAvailable 
{
     return shelterAreaAvailable;
}

//////////////////////////////////
//
// getIsShelterAvailable
//
//////////////////////////////////
- (BOOL) getIsShelterAvailable
{
      return isShelterAvailable;
}


//////////////////////////////////////////////////////////////////
//
// setCellFracSpawn
//
//////////////////////////////////////////////////////////////////
- setCellFracSpawn: (double) aDouble 
{
   cellFracSpawn = aDouble;
   return self;
}





////////////////////////////////////////////////////////////////////
//
// getCellFracSpawn
//
////////////////////////////////////////////////////////////////////
- (double) getCellFracSpawn 
{
   return cellFracSpawn;
}


/////////////////////////////////////////////////////
//
// getCellFracShelter
//
/////////////////////////////////////////////////////
- (double) getCellFracShelter
{
    return cellFracShelter;
}

//////////////////////////////////////////////////////
//
// spawnHere
//
/////////////////////////////////////////////////////
- spawnHere: aFish 
{
   [self addFish: aFish];
   return self;
}

/////////////////////////////////////////////////////////////
//
// eatHere
//
/////////////////////////////////////////////////////////////
- eatHere: aFish 
{
  //
  // sheltered?
  //
  if(shelterAreaAvailable > 0.0) 
  {
    if([aFish getAmIInAShelter] == YES ) 
    {
        shelterAreaAvailable -= [aFish getFishShelterArea];
    }
    if(shelterAreaAvailable < 0.0) 
    {
         shelterAreaAvailable = 0.0;
         isShelterAvailable = NO;
    }
  }

  hourlyAvailDriftFood -= [aFish getHourlyDriftConRate];
  hourlyAvailSearchFood -= [aFish getHourlySearchConRate];

  [self addFish: aFish];

#ifdef FOODAVAILREPORT
  [self foodAvailAndConInCell: aFish];
#endif

  return self;
}


/////////////////////////////////////////////////////////////////////
//
// addFish
//
//
/////////////////////////////////////////////////////////////////////
- addFish: aFish 
{
  id fishOldCell=nil;

  fishOldCell = [aFish getCell];

  if(fishOldCell != nil) [fishOldCell removeFish: aFish];
   
  [fishIContain addLast: aFish];
  [aFish setCell: self];

  [aFish setReach: reach];

  numberOfFish = [fishIContain getCount];

  return self;
}




/////////////////////////////////////////////////////////////////////////
//
// removeFish
//
/////////////////////////////////////////////////////////////////////////
- removeFish: aFish 
{
  [fishIContain remove: aFish];
  [aFish setCell: nil];
  numberOfFish = [fishIContain getCount];
  return self;
}




///////////////////////////////////////////////////////////////
//
// addRedd
//
//
// addRedd has a different functionality from addFish.  Since
// redds don't move around like fish, they spend their entire
// life in once cell.  So, an "addRedd" only occurs after the
// creation of a new redd. 
//
// NOTE: The new Redd MUST BE added to the BEGINNING of the
//       reddIContain List in order to make the SUPER IMPOSITION
//       function work.
//
//
///////////////////////////////////////////////////////////////
- addRedd: aRedd 
{
  id <UniformIntegerDist> reddPixelDist = [UniformIntegerDist create: scratchZone
                                                        setGenerator: myRandGen
                                                       setIntegerMin: 0
                                                              setMax: (pixelCount - 1) ];

  int aPixelNum = [reddPixelDist getIntegerSample];

  [reddsIContain addFirst: aRedd];

  [aRedd setRasterX: polyCellPixels[aPixelNum]->pixelX];
  [aRedd setRasterY: polyCellPixels[aPixelNum]->pixelY];

  [reddPixelDist drop];

  fprintf(stdout, "FishCell >>>> addRedd >>>> END\n");
  fflush(0);

  return self;
}




/////////////////////////////////////////////////////////////
//
// removeRedd
//
/////////////////////////////////////////////////////////////
- removeRedd: aRedd 
{
  [reddsIContain remove: aRedd];
  return self;
}



//////////////////////////////////////////////////////////
//
// getHabPreyEnergyDensity
//
/////////////////////////////////////////////////////////
- (double) getHabPreyEnergyDensity 
{
  return [space getHabPreyEnergyDensity];
}



//////////////////////////////////////////////////
//
// getTemperature
//
//////////////////////////////////////////////////
- (double) getTemperature 
{
  return [space getTemperature];
}


//////////////////////////////////////////////////
//
// getTurbidity
//
//////////////////////////////////////////////////
- (double) getTurbidity 
{
  return [space getTurbidity];
}


/////////////////////////////////////////////
//
// calcDriftHourlyTotal
//
////////////////////////////////////////////
-  calcDriftHourlyTotal 
{
   driftHourlyCellTotal = (  3600 
                          * polyCellArea
                          * polyCellDepth
                          * polyCellVelocity
                          * [space getHabDriftConc])
                          /[space getHabDriftRegenDist];
   return self;
}


////////////////////////////////////////////
//
// calcSearchHourlyTotal
//
//////////////////////////////////////////////
- calcSearchHourlyTotal 
{
  searchHourlyCellTotal = polyCellArea * [space getHabSearchProd];
  return self;
}


//////////////////////////////////////////
//
// getHourlyAvailDriftFood
//
////////////////////////////////////////
- (double) getHourlyAvailDriftFood 
{
   return hourlyAvailDriftFood;
}

//////////////////////////////////////////
//
// getHourlyAvailSearchFood
//
////////////////////////////////////////
- (double) getHourlyAvailSearchFood 
{
   return hourlyAvailSearchFood;
}

//////////////////////////////////
//
// updateDSCellHourlyTotal
//
//////////////////////////////////
- (void) updateDSCellHourlyTotal 
{
  [self calcDriftHourlyTotal];
  [self calcSearchHourlyTotal];
}


/////////////////////////////////////
//
//resetAvailHourlyTotal
//
//////////////////////////////////////
- (void) resetAvailHourlyTotal 
{
   hourlyAvailDriftFood = driftHourlyCellTotal;
   hourlyAvailSearchFood = searchHourlyCellTotal;
}
////////////////////////////////////////////////
//
// getDayLength
//
////////////////////////////////////////////////
- (double) getDayLength 
{
   return [space getDayLength];
}

- (double) getPolyCellDepth
{
   return [super getPolyCellDepth];
}


//////////////////////////////////////////
//
// isDepthGreaterThan0
//
/////////////////////////////////////////
- (BOOL) isDepthGreaterThan0
{
    if(polyCellDepth <= 0.0)
    {
        return NO;
    }

    return YES;
}

///////////////////////////////////////
//
// getPiscivorousFishDensity
//
///////////////////////////////////////
- (double) getPiscivorousFishDensity
{
   return [space calcPiscivorousFishDensity];
} 


////////////////////////////////////////////////
//
// initializeSurvProb
//
////////////////////////////////////////////////
- initializeSurvProb 
{
  id <Index> mapNdx;
  FishParams* fishParams = nil;

  //fprintf(stdout, "FishCell >>>> initializeSurvProb >>>> BEGIN\n");
  //fflush(0);

  if(numberOfSpecies <= 0)
  {
     fprintf(stderr, "ERROR: FishCell >>>> initializeSurvProb >>>> numberOfSpecies is 0\n");
     fflush(0);
     exit(1);
  }

  survMgrMap = [Map create: cellZone];
  survMgrReddMap = [Map create: cellZone];

  mapNdx = [fishParamsMap mapBegin: scratchZone];

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {

     id <SurvMGR> survMgr;
     id <Symbol> species = [fishParams getFishSpecies];
 
     survMgr = [SurvMGR     createBegin: cellZone
                     withHabitatObject: self];

     [survMgrMap at: species  insert: survMgr];

     ANIMAL = [survMgr getANIMALSYMBOL];
     HABITAT = [survMgr getHABITATSYMBOL];

      //
      // High Temperature
      //

      [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "HighTemperature"] 
                        withType: "SingleFunctionProb"
                  withAgentKnows: YES
                 withIsStarvProb: NO];

      [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "HighTemperature"] 
                           withInputObjectType: HABITAT
                             withInputSelector: M(getTemperature)
                                   withXValue1: fishParams->mortFishHiTT9
                                   withYValue1: 0.9
                                   withXValue2: fishParams->mortFishHiTT1
                                   withYValue2: 0.1];


      [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "Velocity"] 
                        withType: "SingleFunctionProb"
                  withAgentKnows: YES
                 withIsStarvProb: NO];

      [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "Velocity"] 
                           withInputObjectType: ANIMAL
                             withInputSelector: M(getSwimSpeedMaxSwimSpeedRatio)
                                   withXValue1: fishParams->mortFishVelocityV9
                                   withYValue1: 0.9
                                   withXValue2: fishParams->mortFishVelocityV1
                                   withYValue2: 0.1];

      [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "Stranding"] 
                        withType: "SingleFunctionProb"
                  withAgentKnows: YES
                 withIsStarvProb: NO];

      [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "Stranding"] 
                           withInputObjectType: ANIMAL
                             withInputSelector: M(getDepthLengthRatioForCell)
                                   withXValue1: fishParams->mortFishStrandD1
                                   withYValue1: 0.1
                                   withXValue2: fishParams->mortFishStrandD9
                                   withYValue2: 0.9];

     //
     // Poor Condition
     //

     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "PoorCondition"]
                       withType: "SingleFunctionProb"
                 withAgentKnows: YES
                withIsStarvProb: YES];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "PoorCondition"] 
                          withInputObjectType: ANIMAL
                            withInputSelector: M(getFishCondition)
                                  withXValue1: fishParams->mortFishConditionK1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishConditionK9
                                  withYValue2: 0.9];
    

     //
     // TerrestialPredation Predation
     // 
     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
             withType: "LimitingFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];

     [survMgr addConstantFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withValue: fishParams->mortFishTerrPredMin];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getPolyCellDepth)
                                  withXValue1: fishParams->mortFishTerrPredD1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishTerrPredD9
                                  withYValue2: 0.9];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getTurbidity)
                                  withXValue1: fishParams->mortFishTerrPredT1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishTerrPredT9
                                  withYValue2: 0.9];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: ANIMAL
                            withInputSelector: M(getFishLength)
                                  withXValue1: fishParams->mortFishTerrPredL9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishTerrPredL1
                                  withYValue2: 0.1];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: ANIMAL
                            withInputSelector: M(getFeedTimeForCell)
                                  withXValue1: fishParams->mortFishTerrPredF9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishTerrPredF1
                                  withYValue2: 0.1];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getPolyCellVelocity)
                                  withXValue1: fishParams->mortFishTerrPredV1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishTerrPredV9
                                  withYValue2: 0.9];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "TerrestialPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getDistanceToHide)
                                  withXValue1: fishParams->mortFishTerrPredH9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishTerrPredH1
                                  withYValue2: 0.1];





     //
     // Aquatic Predation
     // 
     [survMgr addPROBWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
             withType: "LimitingFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];


     [survMgr addConstantFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withValue: fishParams->mortFishAqPredMin];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getPolyCellDepth)
                                  withXValue1: fishParams->mortFishAqPredD9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishAqPredD1
                                  withYValue2: 0.1];



     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: ANIMAL
                            withInputSelector: M(getFishLength)
                                  withXValue1: fishParams->mortFishAqPredL1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishAqPredL9
                                  withYValue2: 0.9];


     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: ANIMAL
                            withInputSelector: M(getFeedTimeForCell)
                                  withXValue1: fishParams->mortFishAqPredF9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishAqPredF1
                                  withYValue2: 0.1];

     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getPiscivorousFishDensity)
                                  withXValue1: fishParams->mortFishAqPredP9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishAqPredP1
                                  withYValue2: 0.1];


     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getTurbidity)
                                  withXValue1: fishParams->mortFishAqPredU1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortFishAqPredU9
                                  withYValue2: 0.9];


     [survMgr addLogisticFuncToProbWithSymbol: [model getFishMortalitySymbolWithName: "AquaticPredation"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getTemperature)
                                  withXValue1: fishParams->mortFishAqPredT9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortFishAqPredT1
                                  withYValue2: 0.1];

             

     [survMgr setLogisticFuncLimiterTo: 20.0];
     //[survMgr setTestOutputOnWithFileName: "SurvMGRTest.out"];
     survMgr = [survMgr createEnd];

  }
 
  [mapNdx setLoc: Start];

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {

     id <SurvMGR> survMgr;
     id <Symbol> species = [fishParams getFishSpecies];
 
     survMgr = [SurvMGR     createBegin: cellZone
                     withHabitatObject: self];

     [survMgrReddMap at: species insert: survMgr];

     ANIMAL = [survMgr getANIMALSYMBOL];
     HABITAT = [survMgr getHABITATSYMBOL];

    //
    // Dewatering
    //
    [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "ReddDewater"]
                      withType: "SingleFunctionProb"
                withAgentKnows: YES
               withIsStarvProb: NO];

    [survMgr addBoolSwitchFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "ReddDewater"]
                           withInputObjectType: HABITAT
                             withInputSelector: M(isDepthGreaterThan0)
                                  withYesValue: 1.0
		                   withNoValue: fishParams->mortReddDewaterSurv];


     //
     // Scouring
     // 
     [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "ReddScour"] 
                       withType: "CustomProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];
  
   
     [survMgr addCustomFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "ReddScour"] 
                              withClassName: "ReddScourFunc"
                        withInputObjectType: ANIMAL
                          withInputSelector: M(getCell)];


     //
     // Low Temperature
     //
     [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "LowTemperature"]
                       withType: "SingleFunctionProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];


     [survMgr addLogisticFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "LowTemperature"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getTemperature)
                                  withXValue1: fishParams->mortReddLoTT1
                                  withYValue1: 0.1
                                  withXValue2: fishParams->mortReddLoTT9
                                  withYValue2: 0.9];




     //
     // High Temperature
     //
     [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "HighTemperature"]
                       withType: "SingleFunctionProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];


     [survMgr addLogisticFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "HighTemperature"] 
                          withInputObjectType: HABITAT
                            withInputSelector: M(getTemperature)
                                  withXValue1: fishParams->mortReddHiTT9
                                  withYValue1: 0.9
                                  withXValue2: fishParams->mortReddHiTT1
                                  withYValue2: 0.1];

     //
     // SuperImposition
     //
     
      [survMgr addPROBWithSymbol: [model getReddMortalitySymbolWithName: "ReddSuperimp"] 
                       withType: "CustomProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];
  
   
      [survMgr addCustomFuncToProbWithSymbol: [model getReddMortalitySymbolWithName: "ReddSuperimp"] 
                               withClassName: "ReddSuperimpFunc"
                         withInputObjectType: ANIMAL
                           withInputSelector: M(getCell)];


     [survMgr setLogisticFuncLimiterTo: 20.0];
     //[survMgr setTestOutputOnWithFileName: "SurvMGRTest.out"];
     survMgr = [survMgr createEnd];
  }
 
  //fprintf(stdout, "Cell >>>> initializeSurvProb >>>> END\n");
  //fflush(0);

  return self;
}




/////////////////////////////////////////////////////
//
// updateHabitatSurvivalProb
//
/////////////////////////////////////////////////////
- updateHabitatSurvivalProb 
{
  //fprintf(stdout, "FishCell >>>> updateHabitatSurvivalProb >>>> BEGIN\n");
  //fflush(0);

  [survMgrMap forEach: M(updateForHabitat)];
  [survMgrReddMap forEach: M(updateForHabitat)];

  //fprintf(stdout, "FishCell >>>> updateHabitatSurvivalProb >>>> END\n");
  //fflush(0);
  return self;
}


//////////////////////////////////
//
// updateHabSurvProbForAqPred
//
/////////////////////////////////
- updateHabSurvProbForAqPred
{
  //fprintf(stdout, "FishCell >>>> updateHabSurvProbForAqPred >>>> BEGIN\n");
  //fflush(0);

  [survMgrMap forEach: M(updateForHabitat)];

  //fprintf(stdout, "FishCell >>>> updateHabSurvProbForAqPred >>>> END\n");
  //fflush(0);

  return self;
}


/////////////////////////////////////
//
// updateFishSurvivalProbFor
//
/////////////////////////////////////
- updateFishSurvivalProbFor: aFish
{
  //fprintf(stdout, "FishCell >>>> updateFishSurvivalProbFor >>>> BEGIN\n");
  //fflush(0);

   [[survMgrMap at: [aFish getSpecies]] 
          updateForAnimal: aFish]; 

  //fprintf(stdout, "FishCell >>>> updateFishSurvivalProbFor >>>> END\n");
  //fflush(0);

   return self;
}


- updateReddSurvivalProbFor: aRedd
{
  //fprintf(stdout, "FishCell >>>> updateReddSurvivalProbFor >>>> BEGIN\n");
  //fflush(0);

   [[survMgrReddMap at: [aRedd getSpecies]] 
               updateForAnimal: aRedd]; 

  //fprintf(stdout, "FishCell >>>> updateReddSurvivalProbFor >>>> BEGIN\n");
  //fflush(0);

   return self;
}


///////////////////////////////////////////////
//
// updatePolyCellVelocity
//
// This was done in the super class but was moved here
// for diagnostic purposes
//
///////////////////////////////////////////////
- updatePolyCellVelocityWith: (double) aFlow
{
   //polyCellVelocity = [velocityInterpolator getValueFor: aFlow];

  [super updatePolyCellVelocityWith: aFlow];

   if(polyCellVelocity < 0.0)
   {
         fprintf(stderr, "ERROR: FishCell >>>> reach = %s >>>> cell number = %d aFlow = %f polyCellVelocity = %f >>>> updatePolyCellVelocityWith >>>> polyCellVelocity is negative\n", [reach getReachName], 
                                                                                                                                                                                       polyCellNumber,
                                                                                                                                                                                       aFlow,
                                                                                                                                                                                       polyCellVelocity);
         fflush(0);
         [velocityInterpolator printSelf];
         exit(1);
   }

   return self;
}



//////////////////////////////////////////
//
//(id <List>) getListOfSurvProbsFor: aFish
//
//////////////////////////////////////////
- (id <List>) getListOfSurvProbsFor: aFish
{
   return [[survMgrMap at: [aFish getSpecies]] getListOfSurvProbsFor: aFish]; 
}

//////////////////////////////////////////
//
//(id <List>) getReddListOfSurvProbsFor: aRedd
//
//////////////////////////////////////////
- (id <List>) getReddListOfSurvProbsFor: aRedd
{
   return [[survMgrReddMap at: [aRedd getSpecies]] getListOfSurvProbsFor: aRedd]; 
}



- (double) getTotalKnownNonStarvSurvivalProbFor: aFish
{
  return  [[survMgrMap at: [aFish getSpecies]] getTotalKnownNonStarvSurvivalProbFor: aFish];
}



- (double) getStarvSurvivalFor: aFish
{
   return [[survMgrMap at: [aFish getSpecies]] 
           getStarvSurvivalFor: aFish]; 
}


#ifdef FOODAVAILREPORT

- foodAvailAndConInCell: aFish 
{
  FILE * foodReportPtr=NULL;
  const char * foodReportFile = "FoodAvailability.rpt";
  char date[12];

  if([space getFoodReportFirstTime] == YES) 
  {
     if((foodReportPtr = fopen(foodReportFile,"w")) == NULL) 
     {
          fprintf(stderr, "ERROR: Cannot open %s for writing",foodReportFile);
          fflush(0);
          exit(1);
     }

     fprintf(foodReportPtr,"\n%-15s%-16s%-16s%-16s%-16s%-16s%-16s%-16s\n","Date",
                                                                          "PolyCellNumber",
                                                                          "SearchFoodProd",
                                                                          "DriftFoodProd",
                                                                          "SearchAvail",
                                                                          "Driftavail",
                                                                          "SearchConsumed",
                                                                          "DriftConsumed");
     fflush(foodReportPtr);

  }

  if([space getFoodReportFirstTime] == NO)
  {
      if((foodReportPtr = fopen(foodReportFile,"a")) == NULL)
      {
          fprintf(stderr, "ERROR: Cannot open %s for writing\n", foodReportFile);
          fflush(0);
          exit(1);
      }

      strncpy(date, [timeManager getDateWithTimeT: [space getModelTime]],12);

      fprintf(foodReportPtr,"%-15s%-16d%-16E%-16E%-16E%-16E%-16E%-16E\n", date,
                                                                          polyCellNumber,
                                                                          searchHourlyCellTotal,
                                                                          driftHourlyCellTotal,
                                                                          hourlyAvailSearchFood,
                                                                          hourlyAvailDriftFood,
                                                                          [aFish getHourlySearchConRate],
                                                                          [aFish getHourlyDriftConRate]);

     fflush(foodReportPtr);
  }

  if(foodReportPtr != NULL) 
  {
      fclose(foodReportPtr);
  }

  [space setFoodReportFirstTime: NO];

  return self;
}

#endif



/////////////////////////////////////////
//
// depthVelReport
//
/////////////////////////////////////////
- depthVelReport: (FILE *) depthVelPtr 
{
    char date[12];

    if([space getDepthVelRptFirstTime] == YES) 
    {
         fprintf(depthVelPtr,"%-15s%-15s%-7s%-16s%-16s%-16s\n", "Date",
                                                                "Flow",
                                                                "PolyCellNumber",
                                                                "PolyCellArea",
                                                                "PolyCellDepth",
                                                                "PolyCellVelocity");
         fflush(depthVelPtr);

    }

    if(polyCellDepth != 0) 
    {
         strncpy(date, [timeManager getDateWithTimeT: [space getModelTime]],12);

         fprintf(depthVelPtr,"%-15s%-15f%-7d%-16f%-16f%-16f\n", date,
                                                               [space getRiverFlow],
                                                               polyCellNumber,
                                                               polyCellArea,
                                                               polyCellDepth,
                                                               polyCellVelocity);
    }
         
    [space setDepthVelRptFirstTime: NO];

    return self;
}




///////////////////////////////////////////////////////////
//
// isThereABarrierTo
//
/////////////////////////////////////////////////////////
- (int) isThereABarrierTo: aCell 
{
   //
   //returns -1, 0, 1 depending on whether the barrier is downstream 
   //
   return [space isThereABarrierTo: aCell from: self];
}    


- (double) getHabDriftConc
{
    return [space getHabDriftConc];
}



- (double) getHabSearchProd
{
    return [space getHabSearchProd];
}


///////////////////////////////////
//
// setCellDataSet
//
//////////////////////////////////
- setCellDataSet: (BOOL) aBool
{
   cellDataSet = aBool;
   return self;
}

//////////////////////////////////
//
// checkCellDataSet
//
/////////////////////////////////
- checkCellDataSet
{
    if(cellDataSet == NO)
    {
        fprintf(stderr, "FishCell >>>> checkCellDataSet >>>>  fracShelter, distToHide, fracSpawn has not been set\n");
        fprintf(stderr, "FishCell >>>> checkCellDataSet >>>>  cellNumber = %d in reach = %s\n", polyCellNumber, [reach getReachName]);
        fflush(0);
        exit(1);
    }

    return self;
}

/////////////////////////////////////////////
//
// checkVelocityInterpolator
//
////////////////////////////////////////////
- checkVelocityInterpolator
{
  if(velocityInterpolator == nil)
  {
      fprintf(stdout, "FishCell >>>> checkVelocityInterpolator >>>> velocityInterpolator is nil in polyCell = %d in reach = %s\n", polyCellNumber, [reach getReachName]);
      fflush(0);
      exit(1);
  }
  return self;
}
/////////////////////////////////////////////
//
// checkDepthInterpolator
//
////////////////////////////////////////////
- checkDepthInterpolator
{
  if(depthInterpolator == nil)
  {
      fprintf(stdout, "FishCell >>>> checkDepthInterpolator >>>> depthInterpolator is nil in polyCell = %d in reach = %s\n", polyCellNumber, [reach getReachName]);
      fflush(0);
      exit(1);
  }
  return self;
}


/////////////////////////////////////////
//
// drop
//
////////////////////////////////////////
- (void) drop
{

   //fprintf(stdout, "FishCell >>>> drop >>>> BEGIN\n");
   //fflush(0);
   

   [fishIContain  removeAll];
   [fishIContain  drop];
   fishIContain = nil;
   [reddsIContain removeAll];
   [reddsIContain drop];
   reddsIContain = nil;

   [listOfAdjacentCells removeAll];
   [listOfAdjacentCells drop];
   listOfAdjacentCells = nil;

   [survMgrMap deleteAll];
   [survMgrMap drop];
   survMgrMap = nil;

   [survMgrReddMap deleteAll];
   [survMgrReddMap drop];
   survMgrReddMap = nil;

   [super drop];
   self = nil;

   //fprintf(stdout, "FishCell >>>> drop >>>> END\n");
   //fflush(0);
}

@end


