/*
inSTREAM Version 5.0, February 2012.
Individual-based stream trout modeling software. Developed and maintained 
by Steve Railsback (Lang, Railsback & Associates, Arcata, California),
Steve Jackson (Jackson Scientific Computing, McKinleyville, California), and
Colin Sheppard (Arcata, California). For information contact info@LangRailsback.com
Development sponsored by EPRI, US EPA, USDA Forest Service, and others.
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


#import "FishParams.h"

@interface SpawnerParams: FishParams
{

@private


@public

// THE FOLLOWING VARIABLES ARE INITIALIZED BY THE
// FISH .Params FILE.
// ADD NEW CONSTANTS HERE.
// 
// CAUTION: If this file is modified in any way the user
//          MUST "make clean" and then remake the executable 
//

//BEGIN CONSTANTS INITIALIZED BY THE FISH .Params FILE


double testParam;

}

+ createBegin: aZone;
- createEnd;

- (void) drop;

@end



