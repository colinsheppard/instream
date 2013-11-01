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


#import <defobj.h>

//
// initialize integers
//

#define LARGEINT 2147483647
#define XCOORDINATE 0
#define YCOORDINATE 1
#define ZCOORDINATE 2
#define DIMENSION 2
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define CELL_COLOR_START 0.0
#define CELL_COLOR_MAX 57
#define TAG_FISH_COLOR 70
#define BARRIER_COLOR 71
#define TAG_CELL_COLOR 75
#define DRY_CELL_COLOR 76
#define UTMINTERIORCOLOR 73
#define UTMBOUNDARYCOLOR 74
#define POLYINTERIORCOLOR 73
#define POLYBOUNDARYCOLOR 74
#define FISH_LENGTH_COEF 15
#define FISHCOLORSTART 58

#define DAYTIMERASTER 72
#define NIGHTTIMERASTER 73

#ifndef PI
#define PI 3.141592654
#endif

// define the segregation symbols for sex
extern id <Symbol> Male, Female;

id randGen; // use the same generator for all random draws in the model

//
// Define the line length for
// comment header lines in input files
// 
#define HCOMMENTLENGTH 200

