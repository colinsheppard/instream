/*
EcoSwarm library for individual-based modeling, last revised February 2012.
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation under the 
Central Valley Project Improvement Act, EPRI, USEPA, USFWS,
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

#import <stdlib.h>


#import "Func.h"

@implementation Func

+ create: aZone
{
  return [super create: aZone];
}



+ createBegin: aZone
{
   Func* aFunc = [super createBegin: aZone];
   static id <List> messageProbeList = nil;

   if(messageProbeList == nil)
   {
       messageProbeList = [List create: globalZone]; 
   }

   aFunc->classMessageProbeList = messageProbeList;
   aFunc->messageProbe = nil; 
   aFunc->dropMessageProbe = NO;

   return aFunc;
}




+     createBegin: aZone
   setInputMethod: (SEL) anInputMethod
{
   Func* aFunc = [super createBegin: aZone];

   aFunc->inputMethod = anInputMethod;
   [aFunc createInputMethodMessageProbeFor: aFunc->inputMethod];

   return aFunc;
}



- createEnd
{
   return [super createEnd];
}


- updateWith: anObj 
{
  return ([self subclassResponsibility: M(updateWith:)]);
}


- setInputMethod: (SEL) anInputMethod
{
  inputMethod = anInputMethod;
  return self;
}



- (id <MessageProbe>) createInputMethodMessageProbeFor: (SEL) anInputMethod
{
  id <ListIndex> ndx = nil;
  id <MessageProbe> aMessageProbe = nil;
  char* inputtedSelectorName = (char *) NULL;

  //fprintf(stdout, "Func >>>> createInputMethodMessageProbeFor >>>> BEGIN\n");
  //fflush(0);

  inputtedSelectorName = (char *) sel_get_name(anInputMethod);

  if(classMessageProbeList == nil)
  {
      fprintf(stderr, "ERROR: Func >>>> createInputMethodMessageProbeFor >>>> classMessageProbeList is nil\n");
      fflush(0);
      exit(1);
  }
  
  ndx = [classMessageProbeList listBegin: scratchZone];

  while(([ndx getLoc] != End) && ((aMessageProbe = (id <MessageProbe>) [ndx next]) != (id <MessageProbe>) nil))
  {
      char* selectorName = (char *) [aMessageProbe getProbedMessage];

      // 
      // Each selector has exactly one string for its name, so I ought to be able to
      // compare their addresses here.
      //
      if(inputtedSelectorName == selectorName)
      {
           messageProbe = aMessageProbe;
           break;
      } 
  }

  [ndx drop];

  if(messageProbe == nil) 
  {
      messageProbe = [MessageProbe        create: globalZone
                               setProbedSelector: anInputMethod];
      [classMessageProbeList addLast: messageProbe];
  } 

  //fprintf(stdout, "Func >>>> createInputMethodMessageProbeFor >>>> END\n");
  //fflush(0);

  return messageProbe;
}




- (const char *) getProbedMessage
{
   return [messageProbe getProbedMessage];
}

- (val_t) getProbedMessageValWithAnObj: anObj
{
    return (val_t) [messageProbe dynamicCallOn: anObj];
}


- (BOOL) isResultId
{
   return [messageProbe isResultId];
}


- (double) getProbedMessageRetValWithAnObj: anObj
{
    double retVal = 0.0;

    val_t val = [messageProbe dynamicCallOn: anObj];

    if((val.type == _C_ID) || (val.type == _C_SEL))
    {
        fprintf(stderr, "ERROR: Func >>>> getProbedMessageRetValWithAnObj >>>> val.type incorrect\n");
        fflush(0);
        exit(1);
    }
    else
    { 
       retVal =  [messageProbe doubleDynamicCallOn: anObj];
    }

    return retVal;

}


- getProbedMessageIDRetValWithAnObj: anObj
{
 
    id retVal = nil;
    val_t val = [messageProbe dynamicCallOn: anObj];

    if((val.type == _C_ID) || (val.type == _C_SEL))
    {
       retVal = [messageProbe objectDynamicCallOn: anObj];
    }
    else
    {
       fprintf(stderr, "ERROR: Func >>>> getProbedMessageIDRetValWithAnObj >>>> val.type incorrect\n");
       fflush(0);
       exit(1);
    }

    return retVal;

}
    

- (double) getFuncValue
{

   //fprintf(stdout, "Func >>>> getFuncValue >>>> funcValue = %f\n", funcValue);
   //fflush(0);
 
   return funcValue;
}


- (void) drop
{
   //fprintf(stdout, "Func >>>> drop >>>> BEGIN\n");
   //fflush(0);

   if(classMessageProbeList)
   {
       //
       // Don't drop the classMessageProbeList or the probes that it contains, we'll them
       // use for subsequent model runs.
       //
   }

   if(dropMessageProbe)
   {
       [messageProbe drop];
       messageProbe = nil;
   }
      
   [super drop];

   //fprintf(stdout, "Func >>>> drop >>>> END\n");
   //fflush(0);
}

@end

