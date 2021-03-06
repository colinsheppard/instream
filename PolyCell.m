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


#include <math.h>
#include <stdlib.h>

#import <simtools.h>

#import "KDTree.h"

#import "PolyCell.h"

@implementation PolyCell

+ create: aZone 
{
  PolyCell* polyCell = [super create: aZone];

  polyCell->cellZone = [Zone create: aZone];

  polyCell->tagCell = NO;


  polyCell->numPolyCoords = 0;
  polyCell->numCornerCoords = 0;


  polyCell->forSurePolyPoint = nil;
  polyCell->polyCellError = NO;

  return polyCell;
}




/////////////////////////////////////
//
// getPolyCellZone
//
/////////////////////////////////////
- (id <Zone>) getPolyCellZone
{
    return cellZone;
}

////////////////////////////////////
//
// setCellNumber
//
///////////////////////////////////
- setPolyCellNumber: (int) aPolyCellNumber
{
    polyCellNumber = aPolyCellNumber;
    return self;
}


////////////////////////////////
//
// getPolyCellNumber
//
////////////////////////////////
- (int) getPolyCellNumber
{
     return polyCellNumber;
}


////////////////////////////////////////
//
// setNumberOfNodes
//
////////////////////////////////////////
- setNumberOfNodes: (int) aNumberOfNodes
{
    numberOfNodes = aNumberOfNodes;
    return self;
}


//////////////////////////////////////
//
// getNumberOfNodes
//
/////////////////////////////////////
- (int) getNumberOfNodes
{
   return numberOfNodes;
}


/////////////////////////////////////////////////
//
// incrementNumCoordinatess
//
/////////////////////////////////////////////////
- incrementNumCoordinates: (int) anIncrement
{
     numPolyCoords += anIncrement;
     return self;
} 


//////////////////////////////////////////////////
//
// createPolyCoordinateArray
//
/////////////////////////////////////////////////
- createPolyCoordinateArray{
  int i;
    //fprintf(stdout, "PolyCell >>>> createPolyCoordinateArray >>> BEGIN %d \n",numPolyCoords);
    //fflush(0);

    polyCoordinates = (double **) [cellZone alloc: (numPolyCoords) * sizeof(double *)];

    for(i=0; i<numPolyCoords; i++){
      polyCoordinates[i] = (double *) [cellZone alloc: 2 * sizeof(double)];
    }

    //fprintf(stdout, "PolyCell >>>> createPolyCoordinateArray >>> END\n");
    //fflush(0);

    return self;
}

//////////////////////////////////////////////////
//
// setPolyCooordsWith
//
//////////////////////////////////////////////////
- setPolyCoordsWith: (double) aPolyCoordX and: (double) aPolyCoordY{
  //fprintf(stdout, "PolyCell >>>> setPolyCoordsWith >>>>  polyCellNumber = %d\n", polyCellNumber);
  //fprintf(stdout, "PolyCell >>>> setPolyCoordsWith >>>>  numPolyCoords = %d\n", numPolyCoords);
  //fprintf(stdout, "PolyCell >>>> setPolyCoordsWith >>>>  polyCoordArrayLength = %d\n", polyCoordArrayLength);
  //fprintf(stdout, "PolyCell >>>> setPolyCoordsWith >>>> X = %f >>>> Y = %f\n", aPolyCoordX, aPolyCoordY);
  //fflush(0); 
     
  if(polyCoordArrayLength+1 > numPolyCoords){
    fprintf(stderr, "ERROR: PolyCell >>>> setPolyCoordsWith >>>> Attempted to add more coordinates to polyCoordinates array than specified by numPolyCoords.");
    fflush(0);
    exit(1);
  }
  polyCoordinates[polyCoordArrayLength][0] = aPolyCoordX; 
  polyCoordinates[polyCoordArrayLength][1] = aPolyCoordY; 
  polyCoordArrayLength++;

  //fprintf(stdout, "PolyCell >>>> setPolyCoordsWith >>>> END");
  //fflush(0); 
  return self;
}


/////////////////////////////////////////////////////////////
//
// checkPolyCoords
//
//////////////////////////////////////////////////////////////
- checkPolyCoords
{
     //int i;

     //fprintf(stdout, "PolyCell >>>> checkPolyCoords >>>>  BEGIN\n");
     //fprintf(stdout, "PolyCell >>>> checkPolyCoords >>>>  polyCellNumber = %d\n", polyCellNumber);
     //fprintf(stdout, "PolyCell >>>> checkPolyCoords >>>>  numPolyCoords = %d\n", numPolyCoords);
     //fflush(0); 

     //for(i = 0; i < numPolyCoords; i++)
     //{     
            //fprintf(stdout, "PolyCell >>>> checkPolyCoords >>>> X = %f \n", polyCoordinates[i][0]); 
            //fprintf(stdout, "PolyCell >>>> checkPolyCoords >>>> Y = %f \n", polyCoordinates[i][1]); 
            //fflush(0);
     //}

     //fprintf(stdout, "PolyCell >>>> checkPolyCoords >>>>  BEGIN\n");
     //fflush(0);

     return self;
}

/////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

             /// HERE ////////////

/////////////////////////////////////////////////////////////////
//
// createPolyPoints
// creates the polyPointList and populates it;
//
////////////////////////////////////////////////////////////////
- createPolyPoints
{
    int i;

    //fprintf(stdout, "PolyCell >>>> createPolyPoints >>>> BEGIN\n");
    //fflush(0);

    polyPointList = [List create: cellZone]; 

    for(i = 0; i < numPolyCoords; i++){
         PolyPoint* polyPoint = [PolyPoint createBegin: cellZone];
 
         [polyPoint setPolyCell: self];

         [polyPoint setXCoordinate: 100 * polyCoordinates[i][0]
                              andY: 100 * polyCoordinates[i][1]];

         polyPoint = [polyPoint createEnd];

         [polyPointList addFirst: polyPoint];

         if(i == 0){
              forSurePolyPoint = polyPoint;
              forSurePointX = [forSurePolyPoint getIntX];
              forSurePointY = [forSurePolyPoint getIntY];
         }

         if(forSurePolyPoint != polyPoint){
              if((forSurePointX == [polyPoint getIntX]) && (forSurePointY == [polyPoint getIntY])){
                    [polyPointList remove: polyPoint];
                    [polyPoint drop];
                    polyPoint = nil;
              }
         }
    }

    //fprintf(stdout, "PolyCell >>>> createPolyPoints >>>> END\n");
    //fflush(0);

    return self;
}


///////////////////////////////////////////
//
// getPolyPointList
//
///////////////////////////////////////////
- (id <List>) getPolyPointList
{
     return polyPointList;
}


///////////////////////////////////////////////
//
// setMinXCoordinate
//
////////////////////////////////////////////////
- setMinXCoordinate: (long int) aMinXCoordinate
{
    minXCoordinate = aMinXCoordinate;
    return self;
}

/////////////////////////////////////////////////
//
// setMaxYCoordinate
//
/////////////////////////////////////////////////
- setMaxYCoordinate: (long int) aMaxYCoordinate
{
    maxYCoordinate = aMaxYCoordinate;
    return self;
}


////////////////////////////////////////////////
//
// tagPolyCell
//
////////////////////////////////////////////////
- tagPolyCell
{
    tagCell = YES;
    return self;
}


///////////////////////////////////////////////////
//
// unTagPolyCell
//
//////////////////////////////////////////////////
- unTagPolyCell
{
    tagCell = NO;
    return self;
}


////////////////////////////////////////
//
// tagAdjacentCells
//
///////////////////////////////////////
- tagAdjacentCells
{
    [listOfAdjacentCells forEach: M(tagPolyCell)];
    return self;
}

////////////////////////////////////////
//
// unTagAdjacentCells
//
///////////////////////////////////////
- unTagAdjacentCells
{
    [listOfAdjacentCells forEach: M(unTagPolyCell)];
    return self;
}



////////////////////////////////////////////////
//
// setRaster* 
//
///////////////////////////////////////////

- setPolyRasterResolutionX: (int) aResolutionX 
{
  polyRasterResolutionX = aResolutionX;
  return self;
}

- (int) getPolyRasterResolutionX 
{
  return polyRasterResolutionX;
}

- setPolyRasterResolutionY: (int) aResolutionY 
{
  polyRasterResolutionY = aResolutionY;
  return self;
}

- (int) getPolyRasterResolutionY 
{
  return polyRasterResolutionY;
}



/////////////////////////////////////
//
// createPolyCellPixels
//
////////////////////////////////////
- createPolyCellPixels
{

  id <ListIndex> ndx = [polyPointList listBegin: scratchZone];
  PolyPoint* polyPoint = nil;

  long int aDisplayX = 0;
  long int aDisplayY = 0;
  int i;

  //fprintf(stdout, "PolyCell >>>> createPolyCellPixels >>>> BEGIN\n");
  //fflush(0);

  maxDisplayX = LONG_MIN;
  maxDisplayY = LONG_MIN;
  minDisplayX = LONG_MAX;
  minDisplayY = LONG_MAX;

  while(([ndx getLoc] != End) && ((polyPoint = [ndx next]) != nil)){
      long int ppDisplayX = [polyPoint getDisplayX];
      long int ppDisplayY = [polyPoint getDisplayY];

      maxDisplayX = (maxDisplayX > ppDisplayX) ? maxDisplayX : ppDisplayX;
      maxDisplayY = (maxDisplayY > ppDisplayY) ? maxDisplayY : ppDisplayY;
      minDisplayX = (minDisplayX < ppDisplayX) ? minDisplayX : ppDisplayX;
      minDisplayY = (minDisplayY < ppDisplayY) ? minDisplayY : ppDisplayY;
  }
  //fprintf(stdout, "PolyCell >>>> createPolyCellPixels >>>> %ld %ld %ld %ld \n",minDisplayX,minDisplayY,maxDisplayX,maxDisplayY);
  //fflush(0);

  pixelCount = 0;
  for(aDisplayX = minDisplayX; aDisplayX <= maxDisplayX; aDisplayX++)
  {
      for(aDisplayY = minDisplayY; aDisplayY <= maxDisplayY; aDisplayY++)
      {
          if([self containsRasterX: aDisplayX andRasterY: aDisplayY])
          {
               pixelCount++;
          }
      }
  }

  if(pixelCount > 0)
  {
     i = 0;
     polyCellPixels = (PolyPixelCoord **) [cellZone alloc: pixelCount * sizeof(PolyPixelCoord *)];

     for(aDisplayX = minDisplayX; aDisplayX <= maxDisplayX; aDisplayX++)
     {
         for(aDisplayY = minDisplayY; aDisplayY <= maxDisplayY; aDisplayY++)
         {
             if([self containsRasterX: aDisplayX andRasterY: aDisplayY])
             {
                  if(i < pixelCount)
                  {
                      polyCellPixels[i] = (PolyPixelCoord *) [cellZone alloc: sizeof(PolyPixelCoord)];
                  
                      polyCellPixels[i]->pixelX = aDisplayX;
                      polyCellPixels[i]->pixelY = aDisplayY;
                      i++;
                   
                  }
             }
         }
     }
   }  // if(pixelCount

   else   // Zero pixels; possible for small cells and high resolution
   {      // So at least make each corner a pixel.
     pixelCount = [polyPointList getCount];
     polyCellPixels = (PolyPixelCoord **) [cellZone alloc: pixelCount * sizeof(PolyPixelCoord *)];

     [ndx setLoc: Start];
     i = 0;
     while(([ndx getLoc] != End) && ((polyPoint = [ndx next]) != nil))
     {
        long int ppDisplayX = [polyPoint getDisplayX];
        long int ppDisplayY = [polyPoint getDisplayY];
  
        polyCellPixels[i] = (PolyPixelCoord *) [cellZone alloc: sizeof(PolyPixelCoord)];
  
        polyCellPixels[i]->pixelX = ppDisplayX;
        polyCellPixels[i]->pixelY = ppDisplayY;
        i++;
     } // while
   }   // else zero pixels
  
  //fprintf(stdout, "PolyCell >>>> createPolyCellPixels >>>> created %d pixels\n",pixelCount);
  //fflush(0);
  
  [ndx drop];
  ndx = nil;

  return self;
} 


/////////////////////////////////////////////////////////////
//
// calcPolyCellCentroid
//
// This method also calculates the polyCellArea
// Area Reference: O'Rourke, J (1998),
//                 Computational Geometry in C, 2nd Edition
//                 Cambridge University Press, Cambridge
//                 p. 21
//
// Centroid Reference: Harris, J.W., Stocker, H., (1998)
//                     Handbook of Mathematics and Computational Science
//                     Springer-Verlag, New York
//                     p. 378
/////////////////////////////////////////////////////////////
- calcPolyCellCentroid
{
   int i;
   int j;
   PolyPoint* polyPointI;
   PolyPoint* polyPointJ;
   int numberOfPPoints = 0;
  


   //fprintf(stdout, "PolyCell >>>> calcPolyCellCentroid >>>> BEGIN\n");
   //fflush(0);

   polyCellArea = 0.0;
   polyCenterX = 0.0;
   polyCenterY = 0.0;

   numberOfPPoints = [polyPointList getCount];
   
   //
   // The points must be labeled counter clockwise.
   //
   for(i = 0; i < numberOfPPoints; i++) 
   {
      j = (i + 1) % numberOfPPoints;
      
      polyPointI = [polyPointList atOffset: i];
      polyPointJ = [polyPointList atOffset: j];

      polyCellArea += [polyPointI getXCoordinate] * [polyPointJ getYCoordinate];
      polyCellArea -= [polyPointI getYCoordinate] * [polyPointJ getXCoordinate];


   }

   polyCellArea /= 2;

   if(polyCellArea <= 0.0)
   {
      fprintf(stderr, "ERROR: PolyCell >>>> calcPolyCellCentroid >>>> polyCellNumber = %d polyCellArea = %f\n", polyCellNumber, polyCellArea);
      fflush(0);
      exit(1);
   }

   polyCenterX = 0.0;
   polyCenterY = 0.0;

   for(i = 0; i < numberOfPPoints; i++) 
   {
      polyPointI = [polyPointList atOffset: i];
      polyCenterX  += [polyPointI getIntX];
      polyCenterY  += [polyPointI getIntY];
   }

   polyCenterX = polyCenterX/numberOfPPoints;
   polyCenterY = polyCenterY/numberOfPPoints;

   displayCenterX = (unsigned int) (polyCenterX - minXCoordinate) + 0.5;
   displayCenterX = displayCenterX/polyRasterResolutionX + 0.5;
   displayCenterY = (unsigned int) (maxYCoordinate - polyCenterY) + 0.5;
   displayCenterY = displayCenterY/polyRasterResolutionY + 0.5;

   //fprintf(stdout, "PolyCell >>>> calcPolyCellCentroid >>>> X = %f, Y = %f \n",polyCenterX, polyCenterY);
   //fprintf(stdout, "PolyCell >>>> calcPolyCellCentroid >>>> END\n");
   //fflush(0);

   return self;
}


////////////////////////////
//
// getPolyCenterX
//
////////////////////////////
- (double) getPolyCenterX
{
    return polyCenterX;
}



///////////////////////////////
//
// getPolyCenterY
//
///////////////////////////////
- (double) getPolyCenterY
{
    return polyCenterY;
}


/////////////////////////////
//
// getPolyCellArea
//
////////////////////////////
- (double) getPolyCellArea
{
    return polyCellArea;
}


////////////////////////////////////////////////////////////////////////
//
// createPolyAdjacentCellsFrom
//
////////////////////////////////////////////////////////////////////////
- createPolyAdjacentCellsFrom: (void *) vertexKDTree {
  void *kdSet;
  int i,j,numberOfPPoints = 0;
  double iX,iY,jX,jY,tX,tY,midPointX,midPointY,edgeLength,dx,dy,distItoTemp,distJtoTemp;
  PolyCell* otherPolyCell = nil;
  //PolyCell* tempCell = nil;
  PolyPoint* polyPointI = nil;
  PolyPoint* polyPointJ = nil;
  PolyPoint* tempPoint = nil;

  //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> BEGIN\n");
  //fflush(0);

  numberOfPPoints = [polyPointList getCount];

  // Cycle through each edge of the polygon
  for(i = 0; i < numberOfPPoints; i++){
    j = (i + 1) % numberOfPPoints;
      
    //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> Edge i,j = %d,%d \n",i,j);
    //fflush(0);
    
    polyPointI = [polyPointList atOffset: i];
    polyPointJ = [polyPointList atOffset: j];

    iX = [polyPointI getXCoordinate];
    iY = [polyPointI getYCoordinate];
    jX = [polyPointJ getXCoordinate];
    jY = [polyPointJ getYCoordinate];

    // Find the midpoint and length
    midPointX = (iX + jX) / 2.0;
    midPointY = (iY + jY) / 2.0;
    dx = iX - jX;
    dy = iY - jY;
    edgeLength = sqrt(dx*dx + dy*dy);

    // Use the kdtree to pull the set of points within 0.5L of the midpoint
    kdSet = kd_nearest_range3(vertexKDTree, midPointX, midPointY, 0.0, edgeLength / 2.0 + 1.0); // the 1.0 is the tolerance, 1cm 

    // Now iterate through these points and find any that are on the segment between I and J
    while(kd_res_end(kdSet)==0){
      tempPoint = kd_res_item_data(kdSet);

      //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> PP x,y = %f,%f \n",[tempPoint getXCoordinate],[tempPoint getYCoordinate]);
      //fflush(0);

      // No need to consider this point if we already know it's from a neighboring cell
      otherPolyCell = [tempPoint getPolyCell];

      //BOOL printOutput = ([self getPolyCellNumber] == 1082 && [otherPolyCell getPolyCellNumber] == 1101) || ([self getPolyCellNumber] == 1101 && [otherPolyCell getPolyCellNumber] == 1082);
      //if(printOutput){
        //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> self = %d, other = %d \n",[self getPolyCellNumber],[otherPolyCell getPolyCellNumber]);
        //fflush(0);
        //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> self list of adjacent: ");
        //id <ListIndex> ndx = [listOfAdjacentCells listBegin: scratchZone];
        //while(([ndx getLoc] != End) && ((tempCell = [ndx next]) != nil)){
          //fprintf(stdout, "%d, ",[tempCell getPolyCellNumber]);
        //}
        //fprintf(stdout, "\n");
        //fflush(0);
        //[ndx drop];
        //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> other list of adjacent: ");
        //ndx = [[otherPolyCell getListOfAdjacentCells] listBegin: scratchZone];
        //while(([ndx getLoc] != End) && ((tempCell = [ndx next]) != nil)){
          //fprintf(stdout, "%d, ",[tempCell getPolyCellNumber]);
        //}
        //fprintf(stdout, "\n");
        //fflush(0);
        //[ndx drop];
      //}

      if([listOfAdjacentCells contains: otherPolyCell]){
        // do nothing
        
        //if(printOutput){
          //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> do nothing \n");
          //fflush(0);
        //}
      }else{
        //if(printOutput){
          //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> test neighbor\n");
          //fflush(0);
        //}

          tX = [tempPoint getXCoordinate];
          tY = [tempPoint getYCoordinate];

          dx = iX - tX;
          dy = iY - tY;
          distItoTemp = sqrt(dx*dx + dy*dy);
          dx = jX - tX;
          dy = jY - tY;
          distJtoTemp = sqrt(dx*dx + dy*dy);

          if(abs(distItoTemp + distJtoTemp - edgeLength) < 1.0 && otherPolyCell != self){
            // Found a neighbor
            [listOfAdjacentCells addLast: otherPolyCell];

            //if(printOutput){
              //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> found neighbor!\n");
              //fflush(0);
            //}

            if(![[otherPolyCell getListOfAdjacentCells] contains: self]){
              // I am a neighbor to my neighbor -- this is important to avoid missing the case when one edge is a superset of the
              // smaller edge (in which case no point on the larger egde lies on the segment of the smaller edge).  See illustration
              // below where AB is on polygon C and XY on polygon Z.  Without the following we would know Z is a neighbor to C but
              // not vice versa.
              //
              //	|   Z	|
              //	|	    |
              // A----X-------Y-----B
              // |		          |
              // |	    C	      |
              //
              [[otherPolyCell getListOfAdjacentCells] addLast: self];

              //if(printOutput){
                //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> neighbor to my neighbor\n");
                //fflush(0);
              //}
            }
          }
      }
      kd_res_next(kdSet);
    }
    kd_res_free(kdSet);
  }
  
  //fprintf(stdout, "PolyCell >>>> createPolyAdjacentCells >>>> END\n");
  //fflush(0);

  return self;
}

/////////////////////////////////////
//
// getListOfAdjacentCells
//
////////////////////////////////////
- (id <List>) getListOfAdjacentCells
{
    return listOfAdjacentCells;
}


//////////////////////////////////////////////////////////////////////////////
//
// containsRasterX
//
// Point in Polygon Reference: O'Rourke, J (1998),
//                             Computational Geometry in C, 2nd Edition
//                             Cambridge University Press, Cambridge
//                             pp 239-245
//
// Note: A point must be strictly interior for a 'YES' return value.
//       Points on the boundary are not handled consistently.
//
//////////////////////////////////////////////////////////////////////////////
- (BOOL) containsRasterX: (long int) aRasterX andRasterY: (long int) aRasterY
{
  int i;
  BOOL interiorPoint = NO; 
  double polyX;  
  double polyY;  

  int counter = 0;
  double xIntersect;

  int ppListCount = [polyPointList getCount];

  PolyPoint* p1 = nil;
  PolyPoint* p2 = nil;
 
  polyX = (double) (aRasterX * polyRasterResolutionX) + minXCoordinate;
  polyY = maxYCoordinate - (double) (aRasterY * polyRasterResolutionY);


  p1 = [polyPointList atOffset: 0]; 

  for(i = 1; i <= ppListCount; i++) 
  {
    //
    // Change these two sets of vars from long int to double
    //
    double minP1P2Y;
    double maxP1P2Y;
    double maxP1P2X;
    
    double p1X;
    double p1Y;
    double p2X;
    double p2Y;

    p2 = [polyPointList atOffset: (i % ppListCount)];

    p1X = [p1 getXCoordinate];
    p1Y = [p1 getYCoordinate];
    p2X = [p2 getXCoordinate];
    p2Y = [p2 getYCoordinate];

    maxP1P2X = (p1X > p2X) ? p1X : p2X;
    minP1P2Y = (p1Y < p2Y) ? p1Y : p2Y;
    maxP1P2Y = (p1Y > p2Y) ? p1Y : p2Y;


    if(polyY > minP1P2Y)
    {
      if(polyY <= maxP1P2Y)
      {
        if(polyX <= maxP1P2X)
        {
          if(p1Y != p2Y) 
          {
            xIntersect = (polyY - p1Y) * (p2X - p1X)/(p2Y - p1Y) + p1X;
            if (p1X == p2X || polyX <= xIntersect)
            {
              counter++;
            }
          }
        }
      }
    }

    p1 = p2;


  } //for 

  if (counter % 2 == 0) 
  {
     interiorPoint = NO;
  }
  else
  {
     interiorPoint = YES;
  
  }

      
  //fprintf(stdout, "PolyCell >>>> containsProbedX: anProbedY: >>>> cell number %d END\n", polyCellNumber);
  //fflush(0);

  return interiorPoint;
}


////////////////////////////////////////////////
//
// setRasterColorVariable
//
////////////////////////////////////////////////
- setRasterColorVariable: (char *) aColorVariable 
{
   strncpy(rasterColorVariable, aColorVariable, 35);

   return self;
}





/////////////////////////////////////////
//
// drop
//
////////////////////////////////////////
- (void) drop
{
    int i = 0;

    //fprintf(stdout, "PolyCell >>>> drop >>>> BEGIN\n");
    //fflush(0);

    for(i = 0; i < numberOfNodes; i++)
    {
         [cellZone free: polyCoordinates[i]]; 
         polyCoordinates[i] = NULL;
    }
    [cellZone free: polyCoordinates]; 
    polyCoordinates = NULL;

    [polyPointList deleteAll];
    polyPointList = nil;

    for(i = 0; i < pixelCount; i++)
    {
          [cellZone free: polyCellPixels[i]];
          polyCellPixels[i] = NULL; 
    }
    [cellZone free: polyCellPixels];
    polyCellPixels = NULL;

   [cellZone drop];

   [super drop];
   self = nil;

   //fprintf(stdout, "PolyCell >>>> drop >>>> END\n");
   //fflush(0);
}

@end
