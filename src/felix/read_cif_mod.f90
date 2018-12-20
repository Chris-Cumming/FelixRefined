!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
! Felix
!
! Richard Beanland, Keith Evans & Rudolf A Roemer
!
! (C) 2013-17, all rights reserved
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

!>
!! Module-description: 
!!
MODULE read_cif_mod

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: read_cif 

  CONTAINS

  !>
  !! Procedure-description: Reads from felix.cif input file using toolbox
  !!
  !! Major-Authors: Keith Evans (2014), Richard Beanland (2016)
  !!
  SUBROUTINE read_cif(IErr)

    ! -----------------------------------------------------------------------
    ! ReadCif: Read the input file
    !
    !	IErr	error code
    ! ----------------------------------------------------------------------
    !
    ! based on 
    ! 
    !                     CIF Tool Box Application 'tbx_ex.f'
    !                     ------------------------
    !                     Version: June 1998
    !
    ! ----------------------------------------------------------------------
    
    !
    ! The tool box common variable file 'ciftbx.cmn' must be present 
    ! at the start of EACH routine using the CIFtbx functions.

    USE MyNumbers
    USE message_mod

    ! global outputs (or inout)
    USE SPARA, ONLY : SChemicalFormula, SSpaceGroupName, SBasisAtomLabel, &
          SBasisAtomName, SWyckoffSymbol, SSpaceGrp
    USE RPARA, ONLY : RLengthX, RLengthY, RLengthZ, RAlpha, RBeta, RGamma, RVolume, &
          RAnisotropicDebyeWallerFactorTensor, RBasisAtomPosition, RBasisIsoDW, &
          RBasisOccupancy, RSymMat, RSymVec
    USE IPARA, ONLY : IVolumeFLAG, IBasisAtomicNumber, IMaxPossibleNAtomsUnitCell, &
          ISymCount, IBasisAnisoDW

    ! global inputs
    USE SConst, ONLY : SAllSpaceGrp
    USE RPARA, ONLY : RDebyeWallerConstant
    USE IPARA, ONLY : IAtomsToRefine,IAnisoDebyeWallerFactorFlag,ILN
    USE SConst, ONLY : SElementSymbolMatrix
    USE IConst
    
    IMPLICIT NONE

    INCLUDE       'ciftbx-f90.cmn'

    LOGICAL       f1,f2,f3
    CHARACTER(32)  name
    CHARACTER(32)  SChemForm
    CHARACTER(80)  line,SPrintString
    CHARACTER(4)   label(6)
    CHARACTER(1)   SAlphabetarray(52)
    CHARACTER(52)  alphabet
    CHARACTER(62)  alphabetnum
    CHARACTER(2)   rs
    CHARACTER(1)   slash
    REAL(RKIND),DIMENSION(:),ALLOCATABLE :: RPrint
    REAL          cela,celb,celc,siga,sigb,sigc
    REAL          x,y,z,u,su,sx,sy,sz,B,sB,sOcc,Uso,suso,Occ
    REAL          numb,sdev,dum
    REAL          xf(6),yf(6),zf(6),uij(6,6)
    INTEGER       i,j,nsite, iset, imark
    DATA SAlphabetarray /"A","B","C","D","E","F","G","H","I","J","K","L","M","N", &
         "O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e", &
         "f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v", &
         "w","x","y","z"/
    DATA alphabet /"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"/
    DATA alphabetnum /"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"/
    DATA          cela,celb,celc,siga,sigb,sigc/6*0./
    DATA          x,y,z,u,sx,sy,sz,su/8*0./
    DATA          xf,yf,zf,uij/54*0./
    DATA          rs/'\\'/

    INTEGER IAtomCount, ICommaPosLeft, ICommaPosRight, &
         Ipos,Idpos, IoneI,IFRACminus, Inum,Idenom,IAtomID
    CHARACTER*32 Csym(ITHREE)
    INTEGER IErr,ind,jnd

    ! fudge to deal with gfortran vs. g77
    slash = rs(1:1)

    ! Assign the CIFtbx files 
    f1 = init_( 1, 2, 3, 6 )

    ! Request dictionary validation check
    IF(.NOT.dict_('cif_core.dic','valid dtype')) THEN
      ! Restore the old clipping action for text fields
      clipt_ = .TRUE.
      pclipt_ = .TRUE.
    END IF
    
    ! Open the CIF to be accessed
    name='felix.cif'
    IF(.NOT.ocif_(name)) THEN
      IErr=1; IF(l_alert(IErr,"ReadCif","Cannot find .cif")) RETURN
    END IF

    ! Assign the data block to be accessed
    IF(.NOT.data_(' ')) THEN
      IErr=1; IF(l_alert(IErr,"ReadCif","No cif data_ statement found")) RETURN
    END IF
   
    ! Extracts crystal formula
    f1 = char_('_chemical_formula_structural', name)
    IF(.NOT.f1) THEN
      IErr=1; IF(l_alert(IErr,"ReadCif","Chemical formula missing")) RETURN
    END IF
    ! strip spaces/brackets and set global variable SChemicalFormula
    ILN=0!Global variable with length of chemical formula string
    DO jnd = 1,LEN(TRIM(name))
      IF ( SCAN(alphabetnum,name(jnd:jnd)).NE.0) THEN!it is an allowed character, put it in 
        ILN=ILN+1
        SChemicalFormula(ILN:ILN) = name(jnd:jnd)
      END IF
    END DO
    
    ! Extract some cell dimensions; test all is OK
    ! NEED TO PUT IN A CHECK FOR LENGTH UNITS
    siga = 0.
    sigb = 0.
    sigc = 0.
    f1 = numb_('_cell_length_a', cela, siga)
    f2 = numb_('_cell_length_b', celb, sigb)
    f3 = numb_('_cell_length_c', celc, sigc)
    ! error check
    IF(.NOT.(f1.AND.f2.AND.f3)) THEN
        IErr=1; IF(l_alert(IErr,"ReadCif","Cell dimension(s) missing")) RETURN
    END IF
    RLengthX=cela; RLengthY=celb; RLengthZ=celc

    siga = 0.
    sigb = 0.
    sigc = 0.
    f1 = numb_('_cell_angle_alpha', cela, siga)
    f2 = numb_('_cell_angle_beta', celb, sigb)
    f3 = numb_('_cell_angle_gamma', celc, sigc)
    IF(.NOT.(f1.AND.f2.AND.f3)) THEN
        IErr=1; IF(l_alert(IErr,"ReadCif","Cell angles(s) missing")) RETURN
    END IF

    ! convert angles from degrees to radians
    IF (cela.GT.TWOPI) THEN!assume this angle is expressed in degrees
      RAlpha=cela*DEG2RADIAN;
    END IF
    IF (celb.GT.TWOPI) THEN!assume this angle is expressed in degrees
      RBeta=celb*DEG2RADIAN;
    END IF
    IF (celc.GT.TWOPI) THEN!assume this angle is expressed in degrees
      RGamma=celc*DEG2RADIAN;
    END IF
    CALL message( LXL, dbg14, "Unit cell angles alpha, beta, gamma", (/ RAlpha*RADIAN2DEG,RBeta*RADIAN2DEG,RGamma*RADIAN2DEG /) )

    f1 = numb_('_cell_volume', cela, siga)
    !Cell volume
    IF((f1) .EQV. .FALSE.) THEN
      IVolumeFLAG= 0
      RVolume= RLengthX*RLengthY*RLengthZ* &
            SQRT(ONE-COS(RAlpha)*COS(RAlpha)-COS(RBeta)*COS(RBeta)-COS(RGamma)*COS(RGamma) + &
            TWO*COS(RAlpha)*COS(RBeta)*COS(RGamma))
    ELSE 
      RVolume= cela
      IVolumeFLAG= 1
    END IF
    CALL message ( LXL, dbg14, "Unit cell volume", RVolume )

    DO      
      f1 = char_('_atom_type_symbol', name)
      !CALL message (LXL, dbg14, "_atom_type_symbol",f1 )
      IF(loop_.NEQV. .TRUE.) EXIT
    END DO

    ! Extract space group notation (expected char string)
    f1 = char_('_symmetry_space_group_name_H-M', name)
	
    !different types of space groups as well as different phrasing of Hall space groups
    IF (SCAN(name,alphabet).EQ.0) THEN
      f1 = char_('_symmetry_space_group_name_Hall',name)
      IF (SCAN(name,alphabet).EQ.0) THEN
        f1 = numb_('_symmetry_Int_tables_number',numb,sx)
        IF (numb.LT.TINY) THEN
          f1 = numb_('_space_group_IT_number',numb,sx)
          IF (numb.LT.TINY) THEN
            IErr=1; IF(l_alert(IErr,"ReadCif","No Space Group")) RETURN
          ELSE
            name = SAllSpaceGrp(NINT(numb))
          END IF
        ELSE 
          name = SAllSpaceGrp(NINT(numb))
        END IF
      END IF
    END IF

    SSpaceGroupName=TRIM(name(1:1))
    SSpaceGrp = TRIM(ADJUSTL(name))
    
    !sometimes space group is input in lowercase letters - below changes the first letter to uppercase
    IF (SCAN(alphabet,SSpaceGroupName).GT.26) THEN
       SSpaceGroupName=SAlphabetarray(SCAN(alphabet,SSpaceGroupName)-26)
    END IF

    CALL message( LXL, dbg14, "Space group", SSpaceGrp)
    
    ! ----------------------------------------------------------
    ! Extract atom site data
    ! count how many atoms
    IAtomCount=0
    DO 
      f1 = char_('_atom_site_label', name)
      IAtomCount= IAtomCount+1
      IF(loop_ .NEQV. .TRUE.) EXIT
    END DO
    IF (SIZE(IAtomsToRefine,DIM=1).GT.IAtomCount) THEN
      IErr=1; IF(l_alert(IErr,"ReadCif",&
            "Number of atomic sites to refine is larger than the number of atoms. "//&
            "Please correct in felix.inp")) RETURN
    END IF

    !allocate variables
    ALLOCATE(RBasisAtomPosition(IAtomCount,ITHREE),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","RBasisAtomPosition()")) RETURN
    ALLOCATE(SBasisAtomLabel(IAtomCount),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","SBasisAtomLabel()")) RETURN
    ALLOCATE(SBasisAtomName(IAtomCount),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","SBasisAtomName()")) RETURN
    ALLOCATE(IBasisAtomicNumber(IAtomCount),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","IBasisAtomicNumber()")) RETURN
    ALLOCATE(SWyckoffSymbol(IAtomCount),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","allocate SWyckoffSymbol")) RETURN
    ALLOCATE(RBasisIsoDW(IAtomCount),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","RBasisIsoDW()")) RETURN
    ALLOCATE(RBasisOccupancy(IAtomCount),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","RBasisOccupancy()")) RETURN
    ALLOCATE(RAnisotropicDebyeWallerFactorTensor(IAtomCount,ITHREE,ITHREE),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","RAnisotropicDebyeWallerFactorTensor()")) RETURN
    ALLOCATE(IBasisAnisoDW(IAtomCount),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","IBasisAnisoDW()")) RETURN

    !initialise variables
    IBasisAtomicNumber = 0
    RAnisotropicDebyeWallerFactorTensor = ZERO
    IMaxPossibleNAtomsUnitCell = 0
    ! input data loop
    DO ind=1,IAtomCount
      B = ZERO
      Uso = ZERO
      f1 = char_('_atom_site_label', name)
      SBasisAtomLabel(ind)=name
      f1 = char_('_atom_site_type_symbol', name)
      SBasisAtomName(ind)=name(1:2)
      ! remove the oxidation state numbers
      Ipos=SCAN(SBasisAtomName(ind),"1234567890")
      IF (Ipos.GT.0) WRITE(SBasisAtomName(ind),'(A1,A1)') name(1:1)," "
      !get atomic number
      DO jnd=1,INElements!NB must match SElementSymbolMatrix defined in smodules line 73
        IF(TRIM(SBasisAtomName(ind)).EQ.TRIM(SElementSymbolMatrix(jnd))) THEN
          IBasisAtomicNumber(ind)=jnd
        END IF
      END DO
      IF (IBasisAtomicNumber(ind).EQ.0) THEN
        WRITE(SPrintString,'(A,I0,A,A)') &
              "Could not find Z for atom",ind,"with symbol",SBasisAtomName(ind)
        IF(l_alert(IErr,"ReadCif",SPrintString)) RETURN
        IErr=1; RETURN
      END IF
      !Wyckoff symbol
      f1 = char_('_atom_site_Wyckoff_symbol',name)
      SWyckoffSymbol(ind) = name
      !coordinates
      f2 = numb_('_atom_site_fract_x', x, sx)
      RBasisAtomPosition(ind,1)= x
      f2 = numb_('_atom_site_fract_y', y, sy)
      RBasisAtomPosition(ind,2)= y
      f2 = numb_('_atom_site_fract_z', z, sz)
      RBasisAtomPosition(ind,3)= z
      !Isotropic D-W factor
      f2 = numb_('_atom_site_B_iso_or_equiv',B,sB)
      f2 = numb_('_atom_site_U_iso_or_equiv',Uso,suso)	
      IF(ABS(B).GT.TINY) THEN
        RBasisIsoDW(ind) = B
      ELSE
	    IF(ABS(Uso).GT.TINY) THEN
          RBasisIsoDW(ind) = Uso*(8*PI**2)
        ELSE
          RBasisIsoDW(ind) = RDebyeWallerConstant
        END IF
      END IF
      !occupancy
      f2 = numb_('_atom_site_occupancy',Occ, sOcc)
      RBasisOccupancy(ind) = Occ

      CALL message( LXL, dbg7, "For Atom ",ind)
      CALL message( LXL, dbg7, SBasisAtomLabel(ind)//SBasisAtomName(ind)//&
            " Z=",IBasisAtomicNumber(ind) )
      CALL message( LXL, dbg7, "RBasisAtomPosition", RBasisAtomPosition(ind,:) )
      CALL message( LXL, dbg7, "(DWF, occupancy) respectively = ",&
            (/ RBasisIsoDW(ind), RBasisOccupancy(ind) /) )
      
      IF(loop_ .NEQV. .TRUE.) EXIT
    END DO

    ! Anisotropic D-W factor !?? should check that it exists
    DO ind=1,IAtomCount
      f2 = numb_('_atom_site_aniso_U_11',u,su) 
      RAnisotropicDebyeWallerFactorTensor(ind,1,1) = u
      f2 = numb_('_atom_site_aniso_U_22',u,su) 
      RAnisotropicDebyeWallerFactorTensor(ind,2,2) = u
      f2 = numb_('_atom_site_aniso_U_33',u,su) 
      RAnisotropicDebyeWallerFactorTensor(ind,3,3) = u
      f2 = numb_('_atom_site_aniso_U_23',u,su) 
      RAnisotropicDebyeWallerFactorTensor(ind,2,3) = u
      f2 = numb_('_atom_site_aniso_U_12',u,su) 
      RAnisotropicDebyeWallerFactorTensor(ind,1,2) = u
      f2 = numb_('_atom_site_aniso_U_13',u,su) 
      RAnisotropicDebyeWallerFactorTensor(ind,1,3) = u
      IBasisAnisoDW(ind) = ind
      IF(IAnisoDebyeWallerFactorFlag.EQ.1) THEN
        CALL message( LM,"RAnisotropicDebyeWallerFactorTensor, index = ",ind)
        CALL message( LM, "..",RAnisotropicDebyeWallerFactorTensor(ind,:,:) )
      END IF
    END DO

    ! count how many symmetry elements
    ISymCount=0
    DO 
      f1 = char_('_symmetry_equiv_pos_as_xyz', name)
      DO 
        f2 = char_(name, line)
        ISymCount=ISymCount+1
        IF(text_ .NEQV. .TRUE.) EXIT
      END DO
      IF(loop_ .NEQV. .TRUE.) EXIT
    END DO

    ALLOCATE(RSymVec(ISymCount,ITHREE),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","allocate RSymVec")) RETURN
    ALLOCATE(RSymMat(ISymCount,ITHREE,ITHREE),STAT=IErr)
    IF(l_alert(IErr,"ReadCif","allocate RSymMat")) RETURN
    
    RSymVec=ZERO
    RSymMat=ZERO
    
    ! Fill the symmetry matrix
    ISymCount=0
    DO 
      f1 = char_('_symmetry_equiv_pos_as_xyz', name)
      DO 
        f2 = char_(name, line)
        ISymCount=ISymCount+1
        ICommaPosLeft = SCAN(name, ",")
        ICommaPosRight= SCAN(name, ",",.TRUE.)
        Csym(1)= name(1:ICommaPosLeft-1)
        Csym(2)= name(ICommaPosLeft+1:ICommaPosRight-1)
        Csym(3)= name(ICommaPosRight+1:LEN_TRIM(name))
        DO ind=1,ITHREE
          IFRACminus=1
          name= Csym(ind)
          Ipos= SCAN(name, "xX")
          IF(Ipos.GT.0) THEN ! there is an X
            IoneI=1
            IF(Ipos.GT.1) THEN
              IF(name(Ipos-1:Ipos-1).EQ."-") IoneI=-1
            END IF
            RSymMat(ISymCount,ind,1)=IoneI
          END IF
             
          Ipos= SCAN(name, "yY")
          IF(Ipos.GT.0) THEN ! there is a Y
            IoneI=1
            IF(Ipos.GT.1)THEN
              IF(name(Ipos-1:Ipos-1).EQ."-") IoneI=-1
            END IF
            RSymMat(ISymCount, ind,2)=IoneI
          END IF
             
          Ipos= SCAN(name, "zZ")
          IF(Ipos.GT.0) THEN ! there is a Z
            IoneI=1
            IF(Ipos.GT.1) THEN
              IF(name(Ipos-1:Ipos-1).EQ."-") IoneI=-1
            END IF
            RSymMat(ISymCount, ind,3)=IoneI
          END IF
          Ipos= SCAN(name, "/")
          IF(Ipos.GT.1) THEN
            IF(Ipos < LEN_TRIM(NAME) ) THEN ! there is an /
              Inum  = IACHAR(name(Ipos-1:Ipos-1))-48
              Idenom= IACHAR(name(Ipos+1:Ipos+1))-48
              IF(Ipos.GT.2) THEN
                IF(name(Ipos-2:Ipos-2)=="-") IFRACminus=-1
              END IF
            END IF
            RSymVec(ISymCount,ind)=IFRACminus*REAL(Inum)/REAL(Idenom)
          END IF
        END DO
!IF(my_rank.EQ.0) PRINT*, Csym
!WRITE(SPrintString,'(F3.0,1X,F3.0,1X,F3.0,2X,F3.0,1X,F3.0,1X,F3.0,2X,F3.0,1X,F3.0,1X,F3.0)') RSymMat(ISymCount,1,:),RSymMat(ISymCount,2,:),RSymMat(ISymCount,3,:)
!IF(my_rank.EQ.0) PRINT*, ISymCount,"RSymMat:  ", SPrintString             
!IF(my_rank.EQ.0) PRINT*, ISymCount,"RSymVec:", RSymVec(ISymCount,:)             
        IF(text_ .NEQV. .TRUE.) EXIT
      END DO

      IF(loop_ .NEQV. .TRUE.) EXIT
    END DO

    ! closes the cif file
    CALL close_

  END SUBROUTINE read_cif

  !>
  !! Procedure-description: Strips any character from string which is not simply
  !! numeric or alphabetic
  !!
  !! Major-Authors: Jacob Richardson (2017)
  !! 
  SUBROUTINE strip_chars(SString,SStripped)
  !now redundant
    !?? only used once but it is a nice pure utility function
    CHARACTER(*), INTENT(IN) :: SString
    CHARACTER, DIMENSION(:), ALLOCATABLE, INTENT(OUT) :: SStripped
    CHARACTER(LEN_TRIM(SString)) :: SPaddedStripped
    INTEGER :: i, n
    n = 0
    DO i = 1,LEN_TRIM(SString) 
      IF ( VERIFY(SString(i:i), &
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890") == 0) THEN
        n = n + 1
        SPaddedStripped(n:n) = SString(i:i)
      END IF
    END DO
    SStripped = SPaddedStripped(1:n)
  END SUBROUTINE

END MODULE read_cif_mod
