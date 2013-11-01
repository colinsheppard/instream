ifeq ($(SWARMHOME),)
SWARMHOME=/usr
endif

EXTRACPPFLAGS+=

APPLICATION=instream
OBJECTS=Trout.o \
	HabitatSpace.o \
	Redd.o \
	TroutModelSwarm.o \
	TroutObserverSwarm.o \
        FishParams.o \
	SearchElement.o \
	ScenarioIterator.o \
	ExperSwarm.o \
	main.o \
\
        TimeManager.o \
\
        ExperBatchSwarm.o \
        TroutBatchSwarm.o \
\
        Cutthroat.o \
        Cutthroat2.o \
        Cutthroat3.o \
        Cutthroat4.o \
        Cutthroat5.o \
        Cutthroat6.o \
        Cutthroat7.o \
        Cutthroat8.o \
        Cutthroat9.o \
        Cutthroat10.o \
        Cutthroat11.o \
        Cutthroat12.o \
\
        HabitatManager.o \
        HabitatSetup.o \
\
	SurvProb.o \
	SingleFuncProb.o \
	LimitingFunctionProb.o \
\
	SurvMGR.o \
	Func.o \
	LogisticFunc.o \
	ConstantFunc.o \
	BooleanSwitchFunc.o \
	ObjectValueFunc.o \
\
	ReddScour.o \
	ReddScourFunc.o \
\
	ReddSuperimp.o \
	ReddSuperimpFunc.o \
\
	EcoAverager.o \
	BreakoutAverager.o \
	BreakoutMessageProbe.o \
	BreakoutVarProbe.o \
	BreakoutReporter.o \
\
	TroutMortalityCount.o \
\
	InterpolationTable.o \
	TimeSeriesInputManager.o \
\
	YearShuffler.o \
	SolarManager.o \
\
	PolyInputData.o \
	PolyCell.o \
	PolyPoint.o \
	FishCell.o \
\
	KDTree.o


OTHERCLEAN= instream.exe.core instream.exe unhappiness.output

include $(SWARMHOME)/etc/swarm/Makefile.appl

main.o: main.m Trout.h HabitatSpace.h TroutObserverSwarm.h 
Trout.o: Trout.m Trout.h globals.h DEBUGFLAGS.h
Redd.o: Redd.[hm] HabitatSpace.h globals.h DEBUGFLAGS.h
SurvivalProb.o: SurvivalProb.[hm] globals.h DEBUGFLAGS.h
HabitatSpace.o: HabitatSpace.[hm] globals.h DEBUGFLAGS.h
FishParams.o: FishParams.[hm] DEBUGFLAGS.h
TroutModelSwarm.o: TroutModelSwarm.[hm] globals.h Cutthroat.h \
	HabitatSpace.h FishParams.h DEBUGFLAGS.h Cutthroat2.h Cutthroat3.h Cutthroat4.h Cutthroat5.h \
	Cutthroat6.h Cutthroat7.h Cutthroat8.h Cutthroat9.h Cutthroat10.h Cutthroat11.h Cutthroat12.h
TroutObserverSwarm.o: TroutObserverSwarm.[hm] TroutModelSwarm.h  globals.h
SearchElement.o: SearchElement.[hm]
ScenarioIterator.o: ScenarioIterator.[hm] SearchElement.h
ExperSwarm.o: ExperSwarm.[hm] SearchElement.h ScenarioIterator.h globals.h
#
TimeManager.o : TimeManager.[hm]
#
ExperBatchSwarm.o : ExperBatchSwarm.[hm]
TroutBatchSwarm.o : TroutBatchSwarm.[hm]
#
Cutthroat.o : Cutthroat.[hm] DEBUGFLAGS.h
Cutthroat2.o : Cutthroat2.[hm] DEBUGFLAGS.h
Cutthroat3.o : Cutthroat3.[hm] DEBUGFLAGS.h
Cutthroat4.o : Cutthroat4.[hm] DEBUGFLAGS.h
Cutthroat5.o : Cutthroat5.[hm] DEBUGFLAGS.h
Cutthroat6.o : Cutthroat6.[hm] DEBUGFLAGS.h
Cutthroat7.o : Cutthroat7.[hm] DEBUGFLAGS.h
Cutthroat8.o : Cutthroat8.[hm] DEBUGFLAGS.h
Cutthroat9.o : Cutthroat9.[hm] DEBUGFLAGS.h
Cutthroat10.o : Cutthroat10.[hm] DEBUGFLAGS.h
Cutthroat11.o : Cutthroat11.[hm] DEBUGFLAGS.h
Cutthroat12.o : Cutthroat12.[hm] DEBUGFLAGS.h
#
HabitatManager.o : HabitatManager.[hm]
HabitatSetup.o : HabitatSetup.[hm]
#
SurvProb.o : SurvProb.[hm]
SingleFuncProb.o : SingleFuncProb.[hm] globals.h
LimitingFunctionProb.o : LimitingFunctionProb.[hm] globals.h
SurvMGR.o : SurvMGR.[hm]
#
ReddScour.o : ReddScour.[hm] SurvProb.h
ReddScourFunc.o : ReddScourFunc.[hm] Func.h
#
ReddSuperimp.o : ReddSuperimp.[hm] SurvProb.h
ReddSuperimpFunc.o : ReddSuperimpFunc.[hm] Func.h
#
Func.o : Func.[hm] globals.h
LogisticFunc.o : LogisticFunc.[hm]
ConstantFunc.o : ConstantFunc.[hm]
BooleanSwitchFunc.o : BooleanSwitchFunc.[hm]
ObjectValueFunc.o : ObjectValueFunc.[hm]
#
BreakoutReporter.o : BreakoutReporter.[hm]
EcoAverager.o : EcoAverager.[hm]
BreakoutAverager.o : BreakoutAverager.[hm]
BreakoutMessageProbe.o : BreakoutMessageProbe.[hm]
BreakoutVarProbe.o : BreakoutVarProbe.[hm]
#
TroutMortalityCount.o : TroutMortalityCount.[hm]
#
InterpolationTable.o : InterpolationTable.[hm]
TimeSeriesInputManager.o : TimeSeriesInputManager.[hm]
#
YearShuffler.o : YearShuffler.[hm]
#
SolarManager.o : SolarManager.[hm]
#
PolyInputData.o : PolyInputData.[hm]
PolyCell.o : PolyCell.[hm]
PolyPoint.o : PolyCell.[hm]
FishCell.o : FishCell.[hm]
#
KDTree.o : KDTree.[hm]
