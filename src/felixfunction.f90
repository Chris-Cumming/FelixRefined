!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
! felixrefine
!
! Richard Beanland, Keith Evans, Rudolf A Roemer and Alexander Hubert
!
! (C) 2013/14, all right reserved
!
! Version: :VERSION:
! Date:    :DATE:
! Time:    :TIME:
! Status:  :RLSTATUS:
! Build:   :BUILD:
! Author:  :AUTHOR:
! 
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
!  This file is part of felixrefine.
!
!  felixrefine is free software: you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation, either version 3 of the License, or
!  (at your option) any later version.
!  
!  felixrefine is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!  
!  You should have received a copy of the GNU General Public License
!  along with felixrefine.  If not, see <http://www.gnu.org/licenses/>.
!
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
! $Id: Felixrefine.f90,v 1.89 2014/04/28 12:26:19 phslaz Exp $
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

!!$REAL(RKIND) FUNCTION FelixFunction(IIterationFLAG,IErr)
SUBROUTINE FelixFunction(LInitialSimulationFLAG,IErr)

  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara

  USE IChannels

  USE MPI
  USE MyMPI

  IMPLICIT NONE

  !--------------------------------------------------------------------
  ! local variable definitions
  !--------------------------------------------------------------------
  
  INTEGER(IKIND) :: IErr,ind,jnd,knd,pnd,IThicknessIndex,ILocalPixelCountMin,&
        ILocalPixelCountMax,IIterationFLAG
  INTEGER(IKIND) :: IAbsorbTag = 0
  INTEGER(IKIND), DIMENSION(:), ALLOCATABLE :: IDisplacements,ICount
  LOGICAL,INTENT(IN) :: LInitialSimulationFLAG !If function is being called during initialisation
  REAL(RKIND),DIMENSION(:,:,:),ALLOCATABLE :: RIndividualReflectionsRoot,&
       RFinalMontageImageRoot
  COMPLEX(CKIND),DIMENSION(:,:,:), ALLOCATABLE :: CAmplitudeandPhaseRoot 

  IF(IWriteFLAG.GE.10.AND.my_rank.EQ.0) THEN
     PRINT*,"Felix function"
  END IF
 
  IDiffractionFLAG = 0!what does this mean

  !-------------------------------------------------------------------- 
  ! Setup crystal lattice, atom positions, hkl's, output reflections 
  !--------------------------------------------------------------------
  !CALL ExperimentalSetup (IErr)
 ! IF( IErr.NE.0 ) THEN
 !    PRINT*,"felixfunction(", my_rank, ") error in ExperimentalSetup()"
 !    RETURN
 ! END IF
   
  !--------------------------------------------------------------------
  ! Setup Image - moved to FelixRefine
 ! ALLOCATE(RhklPositions(nReflections,2),STAT=IErr)
 ! IF( IErr.NE.0 ) THEN
 !    PRINT*,"felixfunction(",my_rank,") error allocating RhklPositions"
 !    RETURN
 ! END IF

!  CALL ImageSetup( IErr )
 ! IF( IErr.NE.0 ) THEN
 !    PRINT*,"felixfunction(",my_rank,") error in ImageSetup"
 !    RETURN
 ! END IF
 
  !--------------------------------------------------------------------
  ! MAIN section
  !--------------------------------------------------------------------

!!$  Structure Factors must be calculated without absorption for refinement to work
!  CALL StructureFactorSetup(IErr)!RB no need to calculate the reflection pool every time
! (only true for Ug refinement, will need to be reinstated for other refinements)
!  IF( IErr.NE.0 ) THEN
!     PRINT*,"felixfunction(",my_rank,")error in StructureFactorSetup"
!     RETURN
!  END IF

  IF((IRefineModeSelectionArray(1).EQ.1).AND.(LInitialSimulationFLAG.NEQV..TRUE.)) THEN
     CALL ApplyNewStructureFactors(IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"felixfunction(",my_rank,")error in ApplyNewStructureFactors()"
        RETURN
     END IF
  END IF

!RB no need to recalculate the Ug pool either   
!  IF(IAbsorbFLAG.NE.0) THEN
!     CALL StructureFactorsWithAbsorption(IErr)
!     IF( IErr.NE.0 ) THEN
!        PRINT*,"felixfunction(",my_rank,")error in StructureFactorsWithAbsorption()"
!        RETURN
!     END IF
!  END IF
  
  !--------------------------------------------------------------------
  ! reserve memory for effective eigenvalue problem !RB moved to felixrefine
  !--------------------------------------------------------------------
  !Kprime Vectors and Deviation Parameter
   ! ALLOCATE(RDevPara(nReflections),STAT=IErr)
 ! IF( IErr.NE.0 ) THEN
 !    PRINT*,"felixfunction(",my_rank,")error allocating RDevPara"
 !    RETURN
 ! END IF
 ! ALLOCATE(IStrongBeamList(nReflections),STAT=IErr)
 ! IF( IErr.NE.0 ) THEN
 !    PRINT*,"felixfunction(",my_rank,")error allocating IStrongBeamList"
 !    RETURN
 ! END IF
 ! ALLOCATE(IWeakBeamList(nReflections),STAT=IErr)
 ! IF( IErr.NE.0 ) THEN
 !    PRINT*,"felixfunction(",my_rank,")error allocating IWeakBeamList"
 !    RETURN
 ! END IF

  !--------------------------------------------------------------------
  ! MAIN LOOP: solve for each (ind,jnd) pixel
  !--------------------------------------------------------------------

  ILocalPixelCountMin= (IPixelTotal*(my_rank)/p)+1
  ILocalPixelCountMax= (IPixelTotal*(my_rank+1)/p) 

  IF((IWriteFLAG.GE.6.AND.my_rank.EQ.0).OR.IWriteFLAG.GE.10) THEN
     PRINT*,"Felixfunction(", my_rank, "): starting the eigenvalue problem"
     PRINT*,"Felixfunction(", my_rank, "): for lines ", ILocalPixelCountMin, &
          " to ", ILocalPixelCountMax
  END IF
  
  IThicknessCount= (RFinalThickness- RInitialThickness)/RDeltaThickness + 1

!Allocations for the pixels dealt with by this core  
  IF(IImageFLAG.LE.2) THEN
     ALLOCATE(RIndividualReflections(INoOfLacbedPatterns,IThicknessCount,&
          (ILocalPixelCountMax-ILocalPixelCountMin)+1),STAT=IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(",my_rank,")error allocating RIndividualReflections"
        RETURN
     END IF
     RIndividualReflections = ZERO
  ELSE
     ALLOCATE(CAmplitudeandPhase(INoOfLacbedPatterns,IThicknessCount,&
          (ILocalPixelCountMax-ILocalPixelCountMin)+1),STAT=IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(",my_rank,")error allocating Amplitude and Phase"
        RETURN
     END IF
     CAmplitudeandPhase = CZERO
  END IF

  !RB moved to FelixRefine
!  ALLOCATE(CFullWaveFunctions(nReflections),STAT=IErr)
!  IF( IErr.NE.0 ) THEN
!     PRINT*,"Felixfunction(",my_rank,")error allocating CFullWaveFunctions"
!     RETURN
!  END IF
!  ALLOCATE(RFullWaveIntensity(nReflections),STAT=IErr)
!  IF( IErr.NE.0 ) THEN
!     PRINT*,"Felixfunction(",my_rank,")error allocating RFullWaveIntensity"
!     RETURN
!  END IF  

  IMAXCBuffer = 200000
  IPixelComputed= 0
 
  IF(IWriteFLAG.GE.0.AND.my_rank.EQ.0) THEN
     PRINT*,"Bloch wave calculation..."
  END IF

  DO knd = ILocalPixelCountMin,ILocalPixelCountMax,1
     jnd = IPixelLocations(knd,1)
     ind = IPixelLocations(knd,2)
     CALL BlochCoefficientCalculation(ind,jnd,knd,ILocalPixelCountMin,IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(",my_rank,") error in BlochCofficientCalculation"
        RETURN
     END IF
  END DO
  
  IF((IWriteFLAG.GE.6.AND.my_rank.EQ.0).OR.IWriteFLAG.GE.10) THEN
     PRINT*,"Felixfunction : ",my_rank," is exiting calculation loop"
  END IF
 
  !--------------------------------------------------------------------
  ! close outfiles
  !--------------------------------------------------------------------
  ALLOCATE(RIndividualReflectionsRoot(INoOfLacbedPatterns,IThicknessCount,IPixelTotal),&
       STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error allocating Root Reflections"
     RETURN
  END IF
  
  IF(IImageFLAG.GE.3) THEN
     ALLOCATE(CAmplitudeandPhaseRoot(INoOfLacbedPatterns,IThicknessCount,IPixelTotal),&
          STAT=IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(",my_rank,")error allocating Root Amplitude and Phase"
        RETURN
     END IF
     CAmplitudeandPhaseRoot = CZERO
  END IF

  RIndividualReflectionsRoot = ZERO

  ALLOCATE(IDisplacements(p),ICount(p),STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error allocating IDisplacements and/or ICount"
     RETURN
  END IF

  DO pnd = 1,p
     IDisplacements(pnd) = (IPixelTotal*(pnd-1)/p)
     ICount(pnd) = (((IPixelTotal*(pnd)/p) - (IPixelTotal*(pnd-1)/p)))*INoOfLacbedPatterns*IThicknessCount
          
  END DO
  
  DO ind = 1,p
        IDisplacements(ind) = (IDisplacements(ind))*INoOfLacbedPatterns*IThicknessCount
  END DO
  
  IF(IImageFLAG.LE.2) THEN
     CALL MPI_GATHERV(RIndividualReflections,SIZE(RIndividualReflections),&
          MPI_DOUBLE_PRECISION,RIndividualReflectionsRoot,&
          ICount,IDisplacements,MPI_DOUBLE_PRECISION,0,&
          MPI_COMM_WORLD,IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(", my_rank, ") error ", IErr, &
             " In MPI_GATHERV"
        RETURN
     END IF     
  ELSE     
     CALL MPI_GATHERV(CAmplitudeandPhase,SIZE(CAmplitudeandPhase),&
          MPI_DOUBLE_COMPLEX,CAmplitudeandPhaseRoot,&
          ICount,IDisplacements,MPI_DOUBLE_COMPLEX,0, &
          MPI_COMM_WORLD,IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(", my_rank, ") error in MPI_GATHERV"
        RETURN
     END IF   
  END IF
  
  IF(IImageFLAG.GE.3) THEN
     DEALLOCATE(CAmplitudeandPhase,STAT=IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(", my_rank, ") error deallocating CAmplitudePhase"
        RETURN
     END IF   
  END IF
   
  IF(IImageFLAG.LE.2) THEN
     DEALLOCATE(RIndividualReflections,STAT=IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(", my_rank, ") error deallocating RIndividualReflections"
        RETURN
     END IF   
  END IF
  
  IF(my_rank.EQ.0.AND.IImageFLAG.GE.3) THEN
     RIndividualReflectionsRoot = &
          CAmplitudeandPhaseRoot * CONJG(CAmplitudeandPhaseRoot)
  END IF

  IF(my_rank.EQ.0) THEN!RB reallocate for output
     ALLOCATE(RIndividualReflections(INoOfLacbedPatterns,IThicknessCount,IPixelTotal),STAT=IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(", my_rank, ") error ", IErr, &
             " in ALLOCATE() of DYNAMIC variables Root Reflections"
        RETURN
     END IF
     
     RIndividualReflections = RIndividualReflectionsRoot
  END IF

  !--------------------------------------------------------------------
  ! free memory
  !--------------------------------------------------------------------
  !Dellocate local Variables
  DEALLOCATE(IDisplacements,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IDisplacements"
     RETURN
  END IF
  DEALLOCATE(ICount,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating ICount"
     RETURN
  END IF
  !DEALLOCATE(IPixelLocations,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IPixelLocations"
     RETURN
  END IF
!  DEALLOCATE(RhklPositions,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RhklPositions"
     RETURN
  END IF
!   DEALLOCATE(RMask,STAT=IErr)       
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RMask"
     RETURN
  END IF
  !DEALLOCATE(RDevPara,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RDevPara"
     RETURN
  END IF
!  DEALLOCATE(IStrongBeamList,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IStrongBeamList"
     RETURN
  END IF
!  DEALLOCATE(IWeakBeamList,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IWeakBeamList"
     RETURN
  END IF
!  DEALLOCATE(CFullWaveFunctions,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating CFullWaveFunctions"
     RETURN
  END IF
!  DEALLOCATE(RFullWaveIntensity,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RFullWaveIntensity"
     RETURN
  END IF  
  DEALLOCATE(RIndividualReflectionsRoot,STAT=IErr) 
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RIndividualReflectionsRoot "
     RETURN  
  END IF
!  DEALLOCATE(MNP,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating MNP"
     RETURN
  END IF
!  DEALLOCATE(SMNP,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating SMNP"
     RETURN
  END IF
!  DEALLOCATE(RDWF,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RDWF"
     RETURN
  END IF
!  DEALLOCATE(ROcc,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating ROcc"
     RETURN
  END IF
!  DEALLOCATE(IAtoms,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IAtoms"
     RETURN
  END IF
!  DEALLOCATE(IAnisoDWFT,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IAnisoDWFT"
     RETURN
  END IF
!  DEALLOCATE(RFullAtomicFracCoordVec,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RFullAtomicFracCoordVec"
     RETURN
  END IF
!  DEALLOCATE(SFullAtomicNameVec,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating SFullAtomicNameVec"
     RETURN
  END IF
!  DEALLOCATE(RFullPartialOccupancy,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RFullPartialOccupancy"
     RETURN
  END IF
!  DEALLOCATE(RFullIsotropicDebyeWallerFactor,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RFullIsotropicDebyeWallerFactor"
     RETURN
  END IF
!  DEALLOCATE(IFullAtomicNumber,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IFullAtomicNumber"
     RETURN
  END IF
!  DEALLOCATE(IFullAnisotropicDWFTensor,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating IFullAnisotropicDWFTensor"
     RETURN
  END IF
!  DEALLOCATE(RgPoolT,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating Deallocation RgPoolT"
     RETURN
  END IF
!  DEALLOCATE(RgPoolMag,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating Deallocation RgPoolMag"
     RETURN
  END IF
!  DEALLOCATE(RgVecVec,STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"Felixfunction(",my_rank,")error deallocating RgPoolMag"
     RETURN
  END IF

  IF((my_rank.NE.0).AND.(LInitialSimulationFLAG.NEQV..TRUE.)) THEN     
!     DEALLOCATE(Rhkl,STAT=IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(",my_rank,")error deallocating Rhkl"
        RETURN
     END IF
  END IF
  IF(IImageFLAG.GE.3) THEN
     DEALLOCATE(CAmplitudeandPhaseRoot,STAT=IErr)     
     IF( IErr.NE.0 ) THEN
        PRINT*,"Felixfunction(",my_rank,")error deallocating CAmplitudeandPhase"
        RETURN  
     END IF
  END IF

END SUBROUTINE FelixFunction

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBROUTINE CalculateFigureofMeritandDetermineThickness(IThicknessCountFinal,IErr)
  
  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara

  USE IChannels

  USE MPI
  USE MyMPI

  IMPLICIT NONE

  INTEGER(IKIND) :: ind,jnd,knd,IErr,ICountedPixels,IThickness,hnd
  INTEGER(IKIND),DIMENSION(INoOfLacbedPatterns) :: IThicknessByReflection
  INTEGER(IKIND),INTENT(OUT) :: IThicknessCountFinal
  REAL(RKIND),DIMENSION(2*IPixelCount,2*IPixelCount) :: RSimulatedImageForPhaseCorrelation,RExperimentalImage
  REAL(RKIND) :: RCrossCorrelationOld,RIndependentCrossCorrelation,RThickness,&
	   PhaseCorrelate,Normalised2DCrossCorrelation,ResidualSumofSquares
  REAL(RKIND),DIMENSION(INoOfLacbedPatterns) :: RReflectionCrossCorrelations,RReflectionThickness
  CHARACTER*200 :: SPrintString
       
  
  IF(IWriteFLAG.GE.10.AND.my_rank.EQ.0) THEN
     PRINT*,"CalculateFigureofMeritandDetermineThickness(",my_rank,")"
  END IF

  RReflectionCrossCorrelations = ZERO

  DO hnd = 1,INoOfLacbedPatterns
     RCrossCorrelationOld = 1.0E15 !A large Number
     RThickness = ZERO
     DO ind = 1,IThicknessCount
        
        ICountedPixels = 0
        RSimulatedImageForPhaseCorrelation = ZERO
        RIndependentCrossCorrelation = ZERO

        DO jnd = 1,2*IPixelCount!RB does this have to be done here
           DO knd = 1,2*IPixelCount
              IF(ABS(RMask(jnd,knd)).GT.TINY) THEN
                 ICountedPixels = ICountedPixels+1
                 RSimulatedImageForPhaseCorrelation(jnd,knd) = &
                      RIndividualReflections(hnd,ind,ICountedPixels)
              END IF
           END DO
        END DO
               
        SELECT CASE (IImageProcessingFLAG)
        CASE(0)
           RExperimentalImage = RImageExpi(:,:,hnd)
        CASE(1)
           RSimulatedImageForPhaseCorrelation = &
                SQRT(RSimulatedImageForPhaseCorrelation)
           RExperimentalImage = &
                SQRT(RImageExpi(:,:,hnd))
        CASE(2)
           WHERE (RSimulatedImageForPhaseCorrelation.GT.TINY**2)
              RSimulatedImageForPhaseCorrelation = &
                   LOG(RSimulatedImageForPhaseCorrelation)
           ELSEWHERE
              RSimulatedImageForPhaseCorrelation = &
                   TINY**2
           END WHERE
              
           WHERE (RExperimentalImage.GT.TINY**2)
              RExperimentalImage = &
                   LOG(RImageExpi(:,:,hnd))
           ELSEWHERE
              RExperimentalImage = &
                   TINY**2
           END WHERE
              
        END SELECT

        SELECT CASE (ICorrelationFLAG)
           
        CASE(0) ! Phase Correlation
           
           RIndependentCrossCorrelation = &
                ONE-& ! So Perfect Correlation = 0 not 1
                PhaseCorrelate(&
                RSimulatedImageForPhaseCorrelation,RExperimentalImage,&
                IErr,2*IPixelCount,2*IPixelCount)
           
        CASE(1) ! Residual Sum of Squares (Non functional)
           RIndependentCrossCorrelation = &
                ResidualSumofSquares(&
                RSimulatedImageForPhaseCorrelation,RImageExpi(:,:,hnd),IErr)
           
        CASE(2) ! Normalised Cross Correlation

           RIndependentCrossCorrelation = &
                ONE-& ! So Perfect Correlation = 0 not 1
                Normalised2DCrossCorrelation(&
                RSimulatedImageForPhaseCorrelation,RExperimentalImage,&
                (/2*IPixelCount, 2*IPixelCount/),IPixelTotal,IErr)
           
        END SELECT
                
        IF(ABS(RIndependentCrossCorrelation).LT.RCrossCorrelationOld) THEN

           RCrossCorrelationOld = RIndependentCrossCorrelation

           IThicknessByReflection(hnd) = ind
           RReflectionThickness(hnd) = RInitialThickness +&
		   IThicknessByReflection(hnd)*RDeltaThickness
        END IF
     END DO

     RReflectionCrossCorrelations(hnd) = RCrossCorrelationOld
     
  END DO

  RCrossCorrelation = &
       SUM(RReflectionCrossCorrelations*RWeightingCoefficients)/&
       REAL(INoOfLacbedPatterns,RKIND)
!RB assume that the thickness is given by the mean of individual thicknesses  
  IThicknessCountFinal = SUM(IThicknessByReflection)/INoOfLacbedPatterns

  RThickness = RInitialThickness + (IThicknessCountFinal-1)*RDeltaThickness 
  

  IF(my_rank.eq.0) THEN
!RB     PRINT*,"Thicknesses",RReflectionThickness
!RB     PRINT*,"Correlation",RCrossCorrelation
!RB     PRINT*,"Thickness Final",IThicknessCountFinal
     WRITE(SPrintString,FMT='(A18,I4,A10)') "Specimen thickness ",NINT(RThickness)," Angstroms"
     PRINT*,TRIM(ADJUSTL(SPrintString))
     !XXPRINT*,"---------------------------------------------------------"
!     PRINT*,"Specimen thickness",NINT(RThickness),"Angstroms"
  END IF

END SUBROUTINE CalculateFigureofMeritandDetermineThickness

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

REAL(RKIND) FUNCTION SimplexFunction(RIndependentVariableValues,IIterationCount,IExitFLAG,IErr)

  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara

  USE IChannels

  USE MPI
  USE MyMPI

  IMPLICIT NONE
  
  INTEGER(IKIND) :: IErr,IExitFLAG,IThickness
  REAL(RKIND),DIMENSION(IIndependentVariables),INTENT(INOUT) :: RIndependentVariableValues
  INTEGER(IKIND),INTENT(IN) :: IIterationCount
  LOGICAL :: LInitialSimulationFLAG = .FALSE.
  
  IF(IWriteFLAG.GE.10.AND.my_rank.EQ.0) THEN
     PRINT*,"SimplexFunction(",my_rank,")"
  END IF

  IF(IRefineModeSelectionArray(1).EQ.1) THEN  !Ug refinement   
     CALL UpdateStructureFactors(RIndependentVariableValues,IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"SimplexFunction(",my_rank,")error in UpdateStructureFactors"
        RETURN
     END IF     
  ELSE !everything else
     CALL UpdateVariables(RIndependentVariableValues,IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"SimplexFunction(",my_rank,")error in UpdateVariables"
        RETURN
     END IF
     WHERE(RAtomSiteFracCoordVec.LT.0) RAtomSiteFracCoordVec=RAtomSiteFracCoordVec+ONE
     WHERE(RAtomSiteFracCoordVec.GT.1) RAtomSiteFracCoordVec=RAtomSiteFracCoordVec-ONE
  END IF

  IF (my_rank.EQ.0) THEN
     CALL PrintVariables(IErr)
     IF( IErr.NE.0 ) THEN
        PRINT*,"SimplexFunction(",my_rank,")error in PrintVariables"
        RETURN
     END IF
  END IF

  CALL FelixFunction(LInitialSimulationFLAG,IErr) ! Simulate !!  
  IF( IErr.NE.0 ) THEN
     PRINT*,"SimplexFunction(",my_rank,")error in FelixFunction"
     RETURN
  END IF

  IF(my_rank.EQ.0) THEN   
     CALL CreateImagesAndWriteOutput(IIterationCount,IExitFLAG,IErr) 
     IF( IErr.NE.0 ) THEN
        PRINT*,"SimplexFunction(",my_rank,")error in CreateImagesAndWriteOutput"
        RETURN
     ENDIF
!This is the key parameter!!!****     
     SimplexFunction = RCrossCorrelation     
  END IF

!RB   Now deallocated in felixrefine
  !DEALLOCATE(RgSumMat,STAT=IErr)
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"felixsim(", my_rank, ") error ", IErr, &
  !        " in Deallocation of RgSumMat"
  !   RETURN
  !ENDIF
  !!DEALLOCATE(CUgMatNoAbs,STAT=IErr)  
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"SimplexInitialisation (", my_rank, ") error in Deallocation()"
  !   RETURN
  !ENDIF
 !DEALLOCATE(CUgMatPrime,STAT=IErr)  
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"SimplexInitialisation (", my_rank, ") error in Deallocation()"
  !   RETURN
  !ENDIF
  !DEALLOCATE(CUgMat,STAT=IErr)  
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"SimplexInitialisation (", my_rank, ") error in Deallocation()"
  !   RETURN
  !ENDIF
  
END FUNCTION SimplexFunction

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBROUTINE CreateImagesAndWriteOutput(IIterationCount,IExitFLAG,IErr)

  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara

  USE IChannels

  USE MPI
  USE MyMPI
  
  IMPLICIT NONE
  
  INTEGER(IKIND) :: IErr,IThicknessIndex,IIterationCount,IExitFLAG
  !RB allocation now called from Image setup in felixrefine
  !ALLOCATE(RMask(2*IPixelCount,2*IPixelCount),STAT=IErr)
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"CreateImagesAndWriteOutput(",my_rank,")error allocating RMask"
  !   RETURN
  !ENDIF
  !RB mask has already been calculated
  !CALL ImageMaskInitialisation(IErr)
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"CreateImagesAndWriteOutput(", my_rank, ") error ", IErr, &
  !        " in ImageMaskInitialisation"
  !   RETURN
  !ENDIF

  CALL CalculateFigureofMeritandDetermineThickness(IThicknessIndex,IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"CreateImagesAndWriteOutput(", my_rank, ") error ", IErr, &
          "Calling function CalculateFigureofMeritandDetermineThickness"
     RETURN
  ENDIF
  !this only needs deallocation at felixrefine exit
  !DEALLOCATE(RMask,STAT=IErr)
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"CreateImagesAndWriteOutput(",my_rank,")error deallocating RMask"
  !   RETURN
  !ENDIF
  
!!$     OUTPUT -------------------------------------  
  CALL WriteIterationOutput(IIterationCount,IThicknessIndex,IExitFLAG,IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"CreateImagesAndWriteOutput(",my_rank,")error in WriteIterationOutput"
     RETURN
  ENDIF

!!$     FINISH OUTPUT  --------------------------------

  DEALLOCATE(RIndividualReflections,STAT=IErr)!RB deallocate output images
  IF( IErr.NE.0 ) THEN
     PRINT*,"CreateImagesAndWriteOutput(",my_rank,")error deallocating RIndividualReflections"
     RETURN
  ENDIF
  !RB now deallocated in felixrefine
  ! DEALLOCATE(IPixelLocations,STAT=IErr)
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"CreateImagesAndWriteOutput(",my_rank,")error deallocating IPixelLocations"
  !   RETURN
  !ENDIF
!  DEALLOCATE(Rhkl,STAT=IErr)
  !IF( IErr.NE.0 ) THEN
  !   PRINT*,"CreateImagesAndWriteOutput(",my_rank,")error deallocating Rhkl"
  !   RETURN
  !ENDIF

END SUBROUTINE CreateImagesAndWriteOutput

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBROUTINE UpdateVariables(RIndependentVariableValues,IErr)

  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara

  USE IChannels

  USE MPI
  USE MyMPI

  IMPLICIT NONE

  INTEGER(IKIND) :: IVariableType,IErr,ind
  REAL(RKIND),DIMENSION(IIndependentVariables),INTENT(IN) :: RIndependentVariableValues

  !!$  Fill the Independent Value array with values
  
  
  IF(IRefineModeSelectionArray(2).EQ.1) THEN     
     RAtomSiteFracCoordVec = RInitialAtomSiteFracCoordVec
  END IF

  DO ind = 1,IIndependentVariables
     IVariableType = IIterativeVariableUniqueIDs(ind,2)
     SELECT CASE (IVariableType)
     CASE(1)
	    !RB structure factor refinement, do in UpdateStructureFactors
     CASE(2)
        CALL ConvertVectorMovementsIntoAtomicCoordinates(ind,RIndependentVariableValues,IErr)
     CASE(3)
        RAtomicSitePartialOccupancy(IIterativeVariableUniqueIDs(ind,3)) = &
             RIndependentVariableValues(ind)
     CASE(4)
        RIsotropicDebyeWallerFactors(IIterativeVariableUniqueIDs(ind,3)) = &
             RIndependentVariableValues(ind)
     CASE(5)
        RAnisotropicDebyeWallerFactorTensor(&
             IIterativeVariableUniqueIDs(ind,3),&
             IIterativeVariableUniqueIDs(ind,4),&
             IIterativeVariableUniqueIDs(ind,5)) = & 
             RIndependentVariableValues(ind)
     CASE(6)
        SELECT CASE(IIterativeVariableUniqueIDs(ind,3))
        CASE(1)
           RLengthX = RIndependentVariableValues(ind)
        CASE(2)
           RLengthY = RIndependentVariableValues(ind)
        CASE(3)
           RLengthZ = RIndependentVariableValues(ind)
        END SELECT
     CASE(7)
        SELECT CASE(IIterativeVariableUniqueIDs(ind,3))
        CASE(1)
           RAlpha = RIndependentVariableValues(ind)
        CASE(2)
           RBeta = RIndependentVariableValues(ind)
        CASE(3)
           RGamma = RIndependentVariableValues(ind)
        END SELECT
     CASE(8)
        RConvergenceAngle = RIndependentVariableValues(ind)
     CASE(9)
        RAbsorptionPercentage = RIndependentVariableValues(ind)
     CASE(10)
        RAcceleratingVoltage = RIndependentVariableValues(ind)
     CASE(11)
        RRSoSScalingFactor = RIndependentVariableValues(ind)
     END SELECT
  END DO

 END SUBROUTINE UpdateVariables
 
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBROUTINE PrintVariables(IErr)

  USE WriteToScreen
  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara

  USE IChannels

  USE MPI
  USE MyMPI

  IMPLICIT NONE

  INTEGER(IKIND) :: IErr,ind,IVariableType,jnd,knd
  REAL(RKIND),DIMENSION(3) :: RCrystalVector
  !REAL(RKIND) :: &!RB
  !     RUgAmplitude,RUgPhase!RB
  CHARACTER*200 :: SPrintString

  RCrystalVector = [RLengthX,RLengthY,RLengthZ]

  DO ind = 1,IRefinementVariableTypes
     IF (IRefineModeSelectionArray(ind).EQ.1) THEN
        SELECT CASE(ind)
        CASE(1)
           WRITE(SPrintString,FMT='(A18,1X,F9.4)') "Current Absorption",RAbsorptionPercentage
           PRINT*,TRIM(ADJUSTL(SPrintString))
!           PRINT*,"Current Absorption",RAbsorptionPercentage
           PRINT*,"Current Structure Factors"!RB should also put in hkl here
           DO jnd = 2,INoofUgs+1!yy since no.1 is 000
   !           RUgAmplitude=( REAL(CUgToRefine(jnd))**2 + AIMAG(CUgToRefine(jnd))**2 )**0.5!RB
   !           RUgPhase=ATAN2(AIMAG(CUgToRefine(jnd)),REAL(CUgToRefine(jnd)))*180/PI!RB
              WRITE(SPrintString,FMT='(2(1X,F9.4))') REAL(CUgToRefine(jnd)),AIMAG(CUgToRefine(jnd))
              PRINT*,TRIM(ADJUSTL(SPrintString))
!XX              PRINT*,CUgToRefine(jnd)!,": Amplitude ",RUgAmplitude,", phase ",RUgPhase
           END DO           
        CASE(2)
           PRINT*,"Current Atomic Coordinates"
           DO jnd = 1,SIZE(RAtomSiteFracCoordVec,DIM=1)
              WRITE(SPrintString,FMT='(A2,3(1X,F9.4))') SAtomName(jnd),RAtomSiteFracCoordVec(jnd,:)
              PRINT*,TRIM(ADJUSTL(SPrintString))              
           END DO
        CASE(3)
           PRINT*,"Current Atomic Occupancy"
           DO jnd = 1,SIZE(RAtomicSitePartialOccupancy,DIM=1)
              WRITE(SPrintString,FMT='(A2,1X,F9.6)') SAtomName(jnd),RAtomicSitePartialOccupancy(jnd)
              PRINT*,TRIM(ADJUSTL(SPrintString))
           END DO
        CASE(4)
           PRINT*,"Current Isotropic Debye Waller Factors"
           DO jnd = 1,SIZE(RIsotropicDebyeWallerFactors,DIM=1)
              WRITE(SPrintString,FMT='(A2,1X,F9.6)') SAtomName(jnd),RIsotropicDebyeWallerFactors(jnd)
              PRINT*,TRIM(ADJUSTL(SPrintString))
           END DO
        CASE(5)
           PRINT*,"Current Anisotropic Debye Waller Factors"
           DO jnd = 1,SIZE(RAnisotropicDebyeWallerFactorTensor,DIM=1)
              DO knd = 1,3
                 WRITE(SPrintString,FMT='(A2,3(1X,F9.4))') SAtomName(jnd),RAnisotropicDebyeWallerFactorTensor(jnd,knd,:)
              PRINT*,TRIM(ADJUSTL(SPrintString))
              END DO
           END DO
        CASE(6)
           PRINT*,"Current Unit Cell Parameters"
           WRITE(SPrintString,FMT='(3(1X,F9.6))') RLengthX,RLengthY,RLengthZ
              PRINT*,TRIM(ADJUSTL(SPrintString))
        CASE(7)
           PRINT*,"Current Unit Cell Angles"
           WRITE(SPrintString,FMT='(3(F9.6,1X))') RAlpha,RBeta,RGamma
              PRINT*,TRIM(ADJUSTL(SPrintString))
        CASE(8)
           PRINT*,"Current Convergence Angle"
           WRITE(SPrintString,FMT='((F9.6,1X))') RConvergenceAngle
              PRINT*,TRIM(ADJUSTL(SPrintString))
        CASE(9)
           PRINT*,"Current Absorption Percentage"
           WRITE(SPrintString,FMT='((F9.6,1X))') RAbsorptionPercentage
              PRINT*,TRIM(ADJUSTL(SPrintString))
        CASE(10)
           PRINT*,"Current Accelerating Voltage"
           WRITE(SPrintString,FMT='((F9.6,1X))') RAcceleratingVoltage
              PRINT*,TRIM(ADJUSTL(SPrintString))
        CASE(11)
           PRINT*,"Current Residual Sum of Squares Scaling Factor"
           WRITE(SPrintString,FMT='((F9.6,1X))') RRSoSScalingFactor
              PRINT*,TRIM(ADJUSTL(SPrintString))
        END SELECT
     END IF
  END DO

END SUBROUTINE PrintVariables

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBROUTINE UpdateStructureFactors(RIndependentVariableValues,IErr)
  
  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara
  
  USE IChannels
  
  USE MPI
  USE MyMPI
  
  IMPLICIT NONE
  
  INTEGER(IKIND) :: IErr,ind
  REAL(RKIND),DIMENSION(IIndependentVariables),INTENT(IN) :: RIndependentVariableValues

  IF(IRefineModeSelectionArray(1).EQ.1) THEN
     DO ind = 1,INoofUgs
        CUgToRefine(ind+1) = &!yy ind+1 instead of ind
             CMPLX(RIndependentVariableValues((ind-1)*2+1),RIndependentVariableValues((ind-1)*2+2),CKIND)
     END DO
	 RAbsorptionPercentage = RIndependentVariableValues(2*INoofUgs+1)!RB
  END IF
  
END SUBROUTINE UpdateStructureFactors

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBROUTINE ConvertVectorMovementsIntoAtomicCoordinates(IVariableID,RIndependentVariableValues,IErr)

  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara
  
  USE IChannels
  
  USE MPI
  USE MyMPI
  
  IMPLICIT NONE

  INTEGER(IKIND) :: IErr,ind,jnd,IVariableID,IVectorID,IAtomID
  REAL(RKIND),DIMENSION(IIndependentVariables),INTENT(IN) :: &
       RIndependentVariableValues

!!$  Use IVariableID to determine which vector is being applied (IVectorID)

  IVectorID = IIterativeVariableUniqueIDs(IVariableID,3)

!!$  Use IVectorID to determine which atomic coordinate the vector is to be applied to (IAtomID)

  IAtomID = IAllowedVectorIDs(IVectorID)

!!$  Use IAtomID to applied the IVectodID Vector to the IAtomID atomic coordinate
    
  RAtomSiteFracCoordVec(IAtomID,:) = RAtomSiteFracCoordVec(IAtomID,:) + &
       RIndependentVariableValues(IVariableID)*RAllowedVectors(IVectorID,:)
  
END SUBROUTINE ConvertVectorMovementsIntoAtomicCoordinates

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBROUTINE InitialiseWeightingCoefficients(IErr)
  
  USE MyNumbers
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara
  USE IChannels
  
  USE MPI
  USE MyMPI
  
  IMPLICIT NONE

  INTEGER(IKIND) :: IErr,ind
  REAL(RKIND),DIMENSION(:),ALLOCATABLE :: RWeightingCoefficientsDummy

  ALLOCATE(RWeightingCoefficients(INoOfLacbedPatterns),STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"InitialiseWeightingCoefficients(",my_rank,")error allocating RWeightingCoefficients"
     RETURN
  ENDIF
  ALLOCATE(RWeightingCoefficientsDummy(INoOfLacbedPatterns),STAT=IErr)
  IF( IErr.NE.0 ) THEN
     PRINT*,"InitialiseWeightingCoefficients(",my_rank,")error allocating RWeightingCoefficientsDummy"
     RETURN
  ENDIF
  
  SELECT CASE (IWeightingFLAG)
  CASE(0)
     RWeightingCoefficients = ONE
  CASE(1)
     RWeightingCoefficientsDummy = RgPoolMag(IOutputReflections)/MAXVAL(RgPoolMag(IOutputReflections))
     IF(SIZE(RWeightingCoefficients).GT.1) THEN
        RWeightingCoefficientsDummy(1) = RWeightingCoefficients(2)/TWO 
     END IF
     DO ind = 1,INoOfLacbedPatterns
        RWeightingCoefficients(ind) = RWeightingCoefficientsDummy(INoOfLacbedPatterns-(ind-1))
     END DO
!!$     RWeightingCoefficients = 1/RgPoolMag(IOutputReflections)
  CASE(2)
     RWeightingCoefficients = RgPoolMag(IOutputReflections)/MAXVAL(RgPoolMag(IOutputReflections))
     IF(SIZE(RWeightingCoefficients).GT.1) THEN
        RWeightingCoefficients(1) = RWeightingCoefficients(2)/TWO 
     END IF
  END SELECT

END SUBROUTINE InitialiseWeightingCoefficients

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

REAL(RKIND) FUNCTION RStandardError(RStandardDeviation,RMean,RFigureofMerit,IErr)

  USE MyNumbers
  
  USE CConst; USE IConst; USE RConst
  USE IPara; USE RPara; USE SPara; USE CPara
  USE BlochPara
  
  USE IChannels
  
  USE MPI
  USE MyMPI
  
  IMPLICIT NONE

  INTEGER(IKIND) :: &
      IErr
  REAL(RKIND),INTENT(INOUT) :: &
       RStandardDeviation,RMean
  REAL(RKIND),INTENT(IN) :: &
       RFigureofMerit
  
  IF (IStandardDeviationCalls.GT.1) THEN
     RMean = (RMean*REAL(IStandardDeviationCalls,RKIND) + &
          RFigureofMerit)/REAL(IStandardDeviationCalls+1,RKIND)
     
     RStandardDeviation = SQRT(&
          ((REAL(IStandardDeviationCalls,RKIND)*RStandardDeviation**2)+&
          (RFigureofMerit-RMean)**2)/ &
          REAL(IStandardDeviationCalls+1,RKIND))   
  ELSE
     RMean = RFigureofMerit
     RStandardDeviation = ZERO
  END IF
     
  RStandardError = RStandardDeviation/SQRT(REAL(IStandardDeviationCalls+1,RKIND))
  IStandardDeviationCalls = IStandardDeviationCalls + 1
     
END FUNCTION  RStandardError
