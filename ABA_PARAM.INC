C     ABA_PARAM.INC
C
C     Abaqus parameter include file — stub for use with EN234_FEA
C     and gfortran. This file is included by Abaqus-format user
C     subroutines (.for files) to set implicit double precision
C     and define the precision parameter NPRECD.
C
C     In a real Abaqus installation this file is provided by
C     the Abaqus solver. For standalone compilation with gfortran,
C     this stub provides the minimum required definitions.
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (NPRECD=2)
