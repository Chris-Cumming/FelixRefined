!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
! Felix
!
! Richard Beanland, Keith Evans & Rudolf A Roemer
!
! (C) 2013-19, all rights reserved
!
! Version: master
! Date:    28-Feb-2018
! Time:    :TIME:
! Status:  
! Build:   
! Author:  r.beanland@warwick.ac.uk
! 
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
!  Felix is free software: you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation, either version 3 of the License, or
!  (at your option) any later version.
!  
!  Felix is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!  
!  You should have received a copy of the GNU General Public License
!  along with Felix.  If not, see <http://www.gnu.org/licenses/>.
!
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

! All modules & procedures conatained in this file:
! SConst
! IConst
! RConst
! IPara
! RPara
! CPara
! SPara
! IChannels
! BlochPara
! Refinement

!>
!! Module-description: 
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE SConst

  CHARACTER(50), PARAMETER :: RStr= "Version: master / 1.0 / r.beanland"
  CHARACTER(50), PARAMETER :: DStr= "Date: 25-Oct-2021"
  CHARACTER(50), PARAMETER :: AStr= "Refinements B,C,D,F,H and S working, no HOLZ" 
  CHARACTER(8) SAllSpaceGrp(230)
!NB needs more work here, does not have non-standard settings or modern versions
!with the letter e
  DATA SAllSpaceGrp/"P1","P-1","P2","P21","C2","Pm","Pc","Cm",&
       "Cc","P2/m","P21/m","C2/m","P2/c","P21/c","C2/c", &
       "P222","P2221","P21212","P212121","C2221","C222","F222", &
       "I222","I212121","Pmm2","Pmc21","Pcc2","Pma2","Pca21", &
       "Pnc2","Pmm21","Pba2","Pna21","Pnn2","Cmm2","Cmc21","Ccc2", &
       "Amm2","Aem2","Ama2","Aea2","Fmm2","Fdd2","Imm2","Iba2", &
       "Ima2","Pmmm","Pnnn","Pccm","Pban","Pmma","Pnna","Pmna","Pcca", &
       "Pbam","Pccn","Pbcm","Pnnm","Pmmn","Pbcn","Pbca","Pnma","Cmcm", &
       "Cmca","Cmmm","Cccm","Cmme","Ccca","Fmmm","Fddd","Immm","Ibam", &
       "Ibca","Imma","P4","P41","P42","P43","I4","I41","P-4","I-4", &
       "P4/m","P42/m","P4/n","P42/n","I4/m","I41/a","P422","P4212", &
       "P4122","P41212","P4222","P42212","P4322","P43212","I422", &
       "I4122","P4mm","P4bm","P42cm","P42nm","P4cc","P4nc","P42mc", &
       "P42bc","I4mm","I4cm","I41md","I41cd","P-42m","P-42c","P-421m", &
       "P-421c","P-4m2","P-4c2","P-4b2","P-4n2","I-4m2","I-4c2", &
       "I-42m","I-42d","P4/mmm","P4/mcc","P4/nbm","P4/nnc","P4/mbm", &
       "P4/mnc","P4/nmm","P4/ncc","P42/mmc","P42/mcm","P42/nbc","P42/nnm", &
       "P42/mbc","P42/mnm","P42/mnc","P42/ncm","I4/mmm","I4/mcm","I41/amd", &
       "I41/acd","P3","P31","P32","R3","P-3","R-3","P312","P321","P3112", &
       "P3121","P3212","P3221","R32","P3m1","P31m","P3c1","P31c","R3m", &
       "R3c","P-31m","P-31c","P-3m1","P-3c1","R-3m","R-3c","P6","P61", &
       "P65","P62","P64","P63","P-6","P6/m","P63/m","P622","P6122", &
       "P6522","P6222","P6422","P6322","P6mm","P6cc","P63cm","P63mc", &
       "P-6m2","P-6c2","P-62m","P-62c","P6/mmm","P6/mcc","P63/mcm", &
       "P63/mmc","P23","F23","I23","P213","I213","Pm-3","Pn-3","Fm-3", &
       "Fd-3","Im-3","Pa-3","Ia-3","P432","P4232","F432","F4132","I432", &
       "P4332","P4132","I4132","P-43m","F-43m","I-43m","P-43n","F-43c", &
       "I-43d","Pm-3m","Pn-3n","Pm-3n","Pn-3m","Fm-3m","Fm-3c","Fd-3m", &
       "Fd-3c","Im-3m","Ia-3d"/

  CHARACTER(2) :: SElementSymbolMatrix(110)!N.B. Number must equal INElements
  DATA SElementSymbolMatrix/"H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", &
       "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", &
       "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", &
        "Ga", "Ge", "As", "Se", "Br", "Kr", "Rb", "Sr", "Y", "Zr", &
        "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", &
        "Sb", "Te", "I", "Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", &
        "Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", &
        "Lu", "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", &
        "Tl", "Pb", "Bi", "Po", "At", "Rn", "Fr", "Ra", "Ac", "Th", &
        "Pa", "U", "Np", "Pu", "Am", "Cm", "Bk", "Cf", "Es", "Fm",& 
        "Md","No","Lr","D","Ja","Jb","Jc","Jd","Je","Jf"/!Note element 'Q', 'Ja'... etc. added to END of list

  CHARACTER(8) :: SAlphabet(26)
  DATA SAlphabet/"Aa","Bb","Cc","Dd","Ee","Ff","Gg","Hh","Ii","Jj","Kk","Ll",&
       "Mm","Nn","Oo","Pp","Qq","Rr","Ss","Tt","Uu","Vv","Ww","Xx","Yy","Zz"/

END MODULE SConst
!--------------------------------------------------------------------

!>
!! Module-description: 
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE IConst
  USE MyNumbers
  INTEGER(IKIND), PARAMETER :: &
       MAXWriteFLAG= 10, &
       ADD_OUT_INFO=6, &
       IParallelFLAG=0,&
       IRandomFLAG = 1, &
       IFixedSeed = 123456787,&
       IRefinementVariableTypes = 10

END MODULE IConst
!--------------------------------------------------------------------


!>
!! Module-description: 
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE RConst
  USE MyNumbers
  
  REAL(RKIND), PARAMETER :: &
       RSpeedOfLight=REAL(2.99762458D+8,RKIND), &! in m/s
       RElectronMass=REAL(9.10938291D-31,RKIND), &!in kg
       RElectronMassMeV=REAL(0.510998928,RKIND), &!don't think we ever use this
       RPlanckConstant=REAL(6.62606957D-34,RKIND), &! in kg m^2 /s
       RElectronCharge=REAL(1.602176565D-19,RKIND), &!in C
       RAngstromConversion=REAL(1.D10,RKIND)! So [1A (in m)] * RAngstromConversion = 1
  REAL(RKIND), PARAMETER :: RTolerance =REAL(1E-7,RKIND)
    
END MODULE RConst
!--------------------------------------------------------------------

!>
!! Module-description: 
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE IPara
  USE MyNumbers
  USE IConst 
     
  !Write Out
  INTEGER(IKIND) :: IMAXRBuffer,  IMAXCBuffer     
  !Input Flags
  INTEGER(IKIND) :: IWriteFLAG,IDebugFLAG,IScatterFactorMethodFLAG, &
       IVolumeFLAG,IHolzFLAG,IAbsorbFLAG, &
       IBeamConvergenceFLAG,IDevFLAG, &
       IRefineModeFLAG,IPrint,IRefineSwitch,&
       IWeightingFLAG,IRefineMethodFLAG,ICorrelationFLAG,IImageProcessingFLAG,&
       IByteSize
  !Minimum Reflections etc
  INTEGER(IKIND) :: IMinStrongBeams,IMinWeakBeams
  !OtherFLAGS
  INTEGER(IKIND) :: IDiffractionFLAG=0
  INTEGER(IKIND) :: IInitialSimulationFLAG
  INTEGER(IKIND) :: ISimFLAG
  !Disk Radius
  INTEGER(IKIND) :: IPixelCount 
  !Crystal Settings
  INTEGER(IKIND) :: IMaxPossibleNAtomsUnitCell
  !Name2Atom index
  INTEGER(IKIND), DIMENSION(:), ALLOCATABLE :: IBasisAtomicNumber,IAtomicNumber
  !Microscope Settings
  INTEGER(IKIND) :: IIncidentBeamDirectionX, IIncidentBeamDirectionY, &
       IIncidentBeamDirectionZ, &
       IXDirectionX, IXDirectionY, IXDirectionZ, &
       INormalDirectionX,INormalDirectionY,INormalDirectionZ
  !Iterative Ug
  INTEGER(IKIND) :: INoofUgs
  !LACBED Input
  INTEGER(IKIND) :: INoOfLacbedPatterns
  !Beams from selection criteria
  INTEGER(IKIND) :: INhkl,nStrongBeams,nWeakBeams,nBeams,IHKLMAXValue
  INTEGER(IKIND), DIMENSION(:), ALLOCATABLE :: IBasisAnisoDW,IStrongBeamList, IAnisoDW
  !Main
  INTEGER(IKIND) :: IPixelTotal, INAtomsUnitCell,IPixelComputed
  INTEGER, DIMENSION(2) :: IImageSizeXY
  !Refinement FLAGS
  INTEGER(IKIND) :: IImageOutputFLAG
  !LACBED
  INTEGER(IKIND),DIMENSION(:,:), ALLOCATABLE :: ILACBEDStrongBeamList, IPixelLocation, ISymmetryRelations
  INTEGER(IKIND),DIMENSION(:), ALLOCATABLE :: InBeams,IOutputReflections,IEquivalentUgKey
  !inpcif
  INTEGER(IKIND) :: ISymCount,ISpaceGrp,ILN
  INTEGER(IKIND) :: IPixelCountTotal
  !Thickness loop Variables
  INTEGER(IKIND) :: IThicknessCount
  INTEGER(IKIND),DIMENSION(:,:),ALLOCATABLE :: IPixelLocations
  !Refine Parameters
  INTEGER(IKIND) :: IFluxIterationSteps
  INTEGER(IKIND), DIMENSION(2) :: IOffset
  INTEGER(IKIND), DIMENSION(:),ALLOCATABLE :: IElementList
  !Ug Calculation
  INTEGER(IKIND) :: ICurrentZ,IPsize
  !Refinement   
  INTEGER(IKIND),DIMENSION(IRefinementVariableTypes) :: IRefineMode
  INTEGER(IKIND),DIMENSION(IRefinementVariableTypes) :: INoofParameters  !zz
  INTEGER(IKIND),DIMENSION(:,:),ALLOCATABLE :: IIterativeVariableUniqueIDs
  INTEGER(IKIND),DIMENSION(:),ALLOCATABLE :: IIndependentVariableType,IIndependentVariableAtom
  !List of Atomic Sites for Refinement
  INTEGER(IKIND),DIMENSION(:),ALLOCATABLE :: IAtomsToRefine
  !Simplex Variables
  INTEGER(IKIND) :: INoOfVariables,ILocalPixelCountMin,ILocalPixelCountMax,IUgOffset
  INTEGER(IKIND), DIMENSION(:), ALLOCATABLE :: IDisplacements,ICount
  !Refinement Vectors
  INTEGER(IKIND),DIMENSION(:),ALLOCATABLE :: IAtomMoveList
  INTEGER(IKIND) :: IFelixCount,IPreviousPrintedIteration,IStandardDeviationCalls  
END MODULE IPara
!--------------------------------------------------------------------

!>
!! Module-description: 
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE RPara
  USE MyNumbers
  USE RConst
  USE IConst

  !INPUT Section 
  !Crystallography
  REAL(RKIND) :: RLengthX,RLengthY,RLengthZ,RVolume,RAlpha,RBeta,RGamma, &
       RDebyeWallerConstant,RAbsorptionPercentage
  REAL(RKIND), DIMENSION(:), ALLOCATABLE :: RBasisIsoDW, RBasisOccupancy, RIsoDW, ROccupancy
  REAL(RKIND), DIMENSION(:,:), ALLOCATABLE :: RSymVec,RBasisAtomPosition, RBasisAtomDelta,&
       RAtomPosition,RUniqueKey
  REAL(RKIND), DIMENSION(:,:,:), ALLOCATABLE :: RSymMat
  !Precision and errors
  REAL(RKIND) :: RPrecision
  !Microscope Parameters
  REAL(RKIND) :: RConvergenceAngle,RAcceleratingVoltage
  REAL(RKIND) :: RElectronVelocity,RElectronWaveLength, &
       RElectronWaveVectorMagnitude,RRelativisticCorrection, &
       RRelativisticMass,RBraggCentral,RAcceptanceAngle
  !LACBED
  REAL(RKIND) :: RInitialThickness,RFinalThickness,RDeltaThickness, &
       RInitialDebyeWallerFactor,RFinalDebyeWallerFactor,&
       RDeltaDebyeWallerFactor
  !Iterative Ugs
  REAL(RKIND) :: RPercentageUgChange
  !Debye Waller Constant, g-vector magnitude, dummy [s'x s'y] for absorption calc
  REAL(RKIND) :: RCurrentB,RCurrentGMagnitude,RSprimeY,RPScale
  !HKL indices 
  REAL(RKIND), DIMENSION(:,:), ALLOCATABLE :: Rhkl 
  REAL(RKIND), DIMENSION(:,:), ALLOCATABLE :: RInputHKLs
  ! scattering factors
  REAL(RKIND), DIMENSION(:,:), ALLOCATABLE :: RScattFactors!,RPseudoAtom
  ! Crystallography 
  ! Real Space and Reciprocal Lattice Vectors in Orthogonal and Microscope
  ! reference frames
  REAL(RKIND), DIMENSION(ITHREE) :: RXDirM,RYDirM,RZDirM,& 
       RaVecO, RbVecO, RcVecO, &
       RaVecM, RbVecM, RcVecM, &
       RarVecO, RbrVecO, RcrVecO, &
       RarVecM, RbrVecM, RcrVecM, &
       RXDirC, RZDirC, RNormDirC,RNormDirM
  REAL(RKIND), DIMENSION(:,:), ALLOCATABLE :: RAtomCoordinate
  REAL(RKIND) :: RBaseVec(ITHREE,ITHREE), &
       RInvBaseVec(ITHREE,ITHREE)
  REAL(RKIND), DIMENSION(:,:,:), ALLOCATABLE :: RAnisotropicDebyeWallerFactorTensor
  !Diffraction Pattern Definitions
  REAL(RKIND), DIMENSION(:), ALLOCATABLE :: RgPoolMag, RSg
  REAL(RKIND), DIMENSION(:,:), ALLOCATABLE :: RgPool, RgPoolMagLaueZone
  REAL(RKIND), DIMENSION(ITHREE,ITHREE) :: RTMat
  REAL(RKIND) :: RDeltaK, RMinimumGMag,RGVectorMagnitude
  REAL(RKIND),DIMENSION(ITHREE) :: RGVector
  REAL(RKIND),DIMENSION(:),ALLOCATABLE :: RgDotNorm
  !Image Initialisation
  REAL(RKIND),DIMENSION(:,:),ALLOCATABLE :: RhklPositions
  REAL(RKIND),DIMENSION(:,:,:),ALLOCATABLE :: RFinalMontageImage
  !Main Program
  REAL(RKIND) :: RMeanInnerPotential,RScattFacToVolts
  REAL(RKIND),DIMENSION(:,:),ALLOCATABLE :: RgMatrixMagnitude, RgSumMat
  REAL(RKIND),DIMENSION(:,:,:),ALLOCATABLE :: RgMatrix
  REAL(RKIND) :: ROuterIntegralLowerBound,ROuterIntegralUpperBound,&!RB not used?
       RInnerIntegralLowerBound,RInnerIntegralUpperBound,&
       RInnerIntegrationParameterGMagPrime,&
       ROuterIntegrationParameterGMagPrime
  !WaveFunction Arrays
  REAL(RKIND),DIMENSION(:),ALLOCATABLE :: RWaveIntensity,RFullWaveIntensity,RSumIntensity
  REAL(RKIND), DIMENSION(:,:,:), ALLOCATABLE :: RIndividualReflections
  !Refinement Variables
  REAL(RKIND), DIMENSION(:,:),ALLOCATABLE :: RImageIn
  REAL(RKIND) :: RFigureofMerit
  ! Experimental Images (width,height, no.of patterns)
  REAL(RKIND),DIMENSION(:,:,:),ALLOCATABLE :: RImageExpi  
  ! Simulated Images as a 1D array (no. of patterns, no of thicknesses, totalpixels)
  REAL(RKIND),DIMENSION(:,:,:),ALLOCATABLE :: RSimulatedPatterns
  ! Simulated Images as images (width,height, no.of patterns, no of thicknesses)
  REAL(RKIND),DIMENSION(:,:,:,:),ALLOCATABLE :: RImageSimi
  ! Average simulated Images (width,height, no.of patterns, no of thicknesses)
  REAL(RKIND),DIMENSION(:,:,:,:),ALLOCATABLE :: RImageAvi,RImageBase
  ! Image masks (width,height, no.of patterns)
  REAL(RKIND),DIMENSION(:,:,:),ALLOCATABLE :: RImageMask
  !Iterative Variable Value
  REAL(RKIND) :: RValue!this is an awful name that doesn't mean anything
  !Refinement Vectors
  REAL(RKIND),DIMENSION(:,:),ALLOCATABLE :: RVector
  !Uncertainties in refined parameters
  REAL(RKIND),DIMENSION(:),ALLOCATABLE :: RIndependentDelta
  REAL(RKIND) :: RSimplexLengthScale,RExitCriteria,RSimplexStandardDeviation,RSimplexMean
  !Gaussian blur radius in pixels
  REAL(RKIND) :: RBlurRadius
END MODULE RPara
!--------------------------------------------------------------------

!>
!! Module-description: 
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE CPara
  USE MyNumbers

  COMPLEX(CKIND),DIMENSION(:),ALLOCATABLE :: CAlphaWeightingCoefficients, CPsi0,CUniqueUg,CEigenValues,&
                CGammaValues, CWaveFunctions,CFullWaveFunctions
  COMPLEX(CKIND), DIMENSION(:,:), ALLOCATABLE :: CUgMatNoAbs,CUgMatPrime,CUgMat,CUgSgMatrix,CEigenValuesChunk,&
                CEigenVectors,CEigenValueDependentTerms,CInvertedEigenVectors,CBeamProjectionMatrix,&
                CDummyBeamMatrix
  COMPLEX(CKIND), DIMENSION(:,:,:), ALLOCATABLE :: CEigenVectorsChunk,CAmplitudeandPhase,CPseudoAtom,CPseudoScatt

END MODULE CPara
!--------------------------------------------------------------------

!>
!! Module-description: 
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE SPara
  USE MyNumbers
  
  CHARACTER(500) :: SPrintString
  CHARACTER(40) :: SChemicalFormula
  CHARACTER(1) :: SSpaceGroupName
  CHARACTER(10) :: SSpaceGrp
  CHARACTER(30), DIMENSION(:), ALLOCATABLE :: SSymString
  CHARACTER(5), DIMENSION(:), ALLOCATABLE :: SBasisAtomLabel,SAtomLabel
  CHARACTER(2), DIMENSION(:), ALLOCATABLE :: SBasisAtomName, SAtomName
  CHARACTER(1), DIMENSION(:), ALLOCATABLE :: SWyckoffSymbol
  
END MODULE SPara
!--------------------------------------------------------------------

!>
!! Module-description: Input and output channels
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE IChannels
  INTEGER, PARAMETER :: IChInp= 40, &
       IChOutWF= 41, IChOutWI= 42, &
       IChOutEV= 43, IChOutEX= 44, &
       IChOutUM= 45, IChOut=46, &
       IChInImage = 51
  INTEGER :: IChOutWF_MPI,IChOutWI_MPI,IChOutES_MPI,IChOutUM_MPI,IChOut_MPI 
  INTEGER, PARAMETER :: IChOutWFImageReal= 47, IChOutWFImagePhase= 48, &
       IChOutWIImage= 49, MontageOut = 50,IChOutSimplex = 52
END MODULE IChannels
!--------------------------------------------------------------------

!>
!! Module-description: Eigen problem variables
!!
!! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
!!
MODULE BlochPara 
  USE MyNumbers
  USE IConst
  USE MPI
  USE MyMPI

  INTEGER(IKIND),DIMENSION(:), ALLOCATABLE :: IWeakBeamList
  REAL(RKIND) RBigK
  REAL(RKIND),DIMENSION(:), ALLOCATABLE :: RDevPara
  REAL(RKIND), DIMENSION(ITHREE) :: RTiltedK
  REAL(8), DIMENSION(:), ALLOCATABLE :: RROutArray, RIOutArray
  COMPLEX(CKIND),DIMENSION(:,:), ALLOCATABLE :: CEigenSaveTemp
END MODULE BlochPara
