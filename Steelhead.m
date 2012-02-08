/*
inSTREAM Version 5.0, February 2012.
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




#import "globals.h"
#import "Steelhead.h"

@implementation Steelhead

+ createBegin: aZone 
{
   return [super createBegin: aZone];
}

- setSex: (id <Symbol>) aSex
{
    sex = aSex;
    return self;
}

- setRandGen: aRandGen
{
    randGen = aRandGen;
    return self;
}

- setRasterResolutionX: (int) aRasterResX
                     Y: (int) aRasterResY
{
    rasterResolutionX = aRasterResX;
    rasterResolutionY = aRasterResY;
    return self;
}

- setArrivalStartTime: (time_t) anArrivalStartTime
{
      arrivalStartTime = anArrivalStartTime;
      return self;
}

- (time_t) getArrivalStartTime
{
      return arrivalStartTime;
}
- setArrivalStartMonth: (int) aMonth 
                andDay: (int) aDay
{
     arrivalStartMonth = aMonth;
     arrivalStartDay = aDay;
     return self;
}

- (int) getArrivalStartMonth
{
     return arrivalStartMonth;
}


- (int) getArrivalStartDay
{
     return arrivalStartDay;
}

- move
{
    return self;
}

- spawn
{
    return self;
}

- grow
{
    return self;
}

- die
{
    return self;
}


///////////////////////////////////////////////////////////////////////////////
//
// compareArrivalTime
// Needed by QSort in TroutModelSwarm method: buildTotalTroutPopList
//
///////////////////////////////////////////////////////////////////////////////
//- (int) compareArrivalTime: aSpawner 
- (int) compare: aSpawner 
{
  double oFishArriveStartTime = [aSpawner getArrivalStartTime];

  if(arrivalStartTime > oFishArriveStartTime)
  {
     return 1;
  }
  else if(arrivalStartTime == oFishArriveStartTime)
  {
     return 0;
  }
  else
  {
     return -1;
  }
}

////////////////////////////////////////////////
//
// drop
//
///////////////////////////////////////////////
- (void) drop
{
     [super drop];
}


@end

