Copyright>        OpenRadioss
Copyright>        Copyright (C) 1986-2022 Altair Engineering Inc.
Copyright>    
Copyright>        This program is free software: you can redistribute it and/or modify
Copyright>        it under the terms of the GNU Affero General Public License as published by
Copyright>        the Free Software Foundation, either version 3 of the License, or
Copyright>        (at your option) any later version.
Copyright>    
Copyright>        This program is distributed in the hope that it will be useful,
Copyright>        but WITHOUT ANY WARRANTY; without even the implied warranty of
Copyright>        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Copyright>        GNU Affero General Public License for more details.
Copyright>    
Copyright>        You should have received a copy of the GNU Affero General Public License
Copyright>        along with this program.  If not, see <https://www.gnu.org/licenses/>.
Copyright>    
Copyright>    
Copyright>        Commercial Alternative: Altair Radioss Software 
Copyright>    
Copyright>        As an alternative to this open-source version, Altair also offers Altair Radioss 
Copyright>        software under a commercial license.  Contact Altair to discuss further if the 
Copyright>        commercial version may interest you: https://www.altair.com/radioss/.    
C----s---1----+----2----+----3----+----4----+----5----+----6----+----7--
Chd|====================================================================
Chd|  REDEF_SEATBELT                source/tools/seatbelts/redef_seatbelt.F
Chd|-- called by -----------
Chd|        R23L114DEF3                   source/elements/spring/r23l114def3.F
Chd|-- calls ---------------
Chd|        VINTER2                       source/tools/curve/vinter.F   
Chd|====================================================================
      SUBROUTINE REDEF_SEATBELT(FX      ,XK     ,DX     ,FXEP   ,DXOLD ,
     .                          DPX     ,TF     ,NPF    ,XC     ,OFF   ,
     .                          E       ,ANIM   ,IANI   ,POS    ,XL0   ,
     .                          DMN     ,DMX    ,LSCALE ,YIELD  ,AK    ,  
     .                          IECROU  ,IFUNC  ,IFUNC2 ,XX_OLD ,FX_MAX,
     .                          XKC     ,LLT_LOC,INDEXA ,FLAG   ,XK_TAN,
     .                          EPS_OLD ,FRAM_FACTOR)
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   G l o b a l   P a r a m e t e r s
C-----------------------------------------------
#include      "mvsiz_p.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "com08_c.inc"
#include      "vect01_c.inc"
#include      "scr05_c.inc"
#include      "impl1_c.inc"
#include      "com01_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      INTEGER NPF(*),IECROU(MVSIZ),IFUNC(MVSIZ),IFUNC2(MVSIZ),IANI,
     .        INDEXA(*),LLT_LOC,FLAG
C     REAL
      my_real
     .   FX(*), XK(*), DX(*), FXEP(*), DXOLD(*), DPX(*), TF(*),
     .   OFF(*),E(*),XL0(*),LSCALE(*),YIELD(*),AK(MVSIZ),XX_OLD(*),
     .   FX_MAX(*),XKC(*),ANIM(*),DMN(*),DMX(*),POS(*),XC(*),XK_TAN(*)
      my_real, INTENT(IN) :: FRAM_FACTOR(MVSIZ)
      my_real, INTENT(INOUT) :: EPS_OLD(MVSIZ)
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER
     . I, K, NP2, FUND, K1, II, JECROU(4), INTERP, JPOS(MVSIZ), JFUNC,
     . JLEN(MVSIZ),JAD(MVSIZ),J
      my_real
     . X1,X2,Y1,Y2,DT11,AN3Y0(MVSIZ),XN3FY0(MVSIZ),DXELA(MVSIZ),XI1,XI2,YI1,YI2,DDXT,DDXC,
     . XX(MVSIZ),YY(MVSIZ),GET_U_FUNC,DYDX(MVSIZ),DDX(MVSIZ),DVX(MVSIZ),FOLD(MVSIZ),
     . DAMP,DAMM,FXB,XXB,XK_TANSAV(MVSIZ),X1S,X2S
C=======================================================================
C     Derived from REDEF3
C     Can be launched on a reduced number of elements (defined by INDEXA)
C     --> FLAG = 1 : loop on all elements I = J
C     --> FLAG = 2 : loop only on 2nd strand of elements in slipring - I /= J 
C        (ALL LOCAL ARRAYS USE J)
C-----------------------------------------------------------------------
C
      DT11 = DT1
      IF(DT11==ZERO)DT11 = EP30
C
      DO J=LFT,LLT_LOC
        I = INDEXA(J)
        DX(I)=DX(I)/XL0(I)
        DXOLD(I)=DXOLD(I)/XL0(I)
        E(I)=E(I)/XL0(I)
        FOLD(J)=FX(I)
        DDX(J)= (DX(I)-EPS_OLD(I))
        DVX(J)= (DX(I)-DXOLD(I))/ DT11
        EPS_OLD(I) = DX(I)
      ENDDO
C
      IF ((IANI/=0).AND.(FLAG==1))THEN
        DO I=LFT,LLT_LOC
          II=I+NFT
          DAMP=DX(I)/MAX(DMX(I),EM15)
          DAMM=DX(I)/MIN(DMN(I),-EM15)
          ANIM(II)=MAX(ANIM(II),DAMP,DAMM)
          ANIM(II)=MIN(ANIM(II),ONE)
        ENDDO
      ENDIF
C
C-------------------------------------
C        VECTOR INTERPOLATION (ADRESS)
C-------------------------------------
C
      JECROU(1:4) = 0
      INTERP = 0
C
      DO J=LFT,LLT_LOC
       I = INDEXA(J)
       IF(IECROU(I) == 0)THEN
         JECROU(1) = JECROU(1) + 1
       ELSEIF(IECROU(I) == 10)THEN
         JECROU(2) = JECROU(2) + 1
         INTERP = 1
       ELSEIF(IECROU(I) == 11)THEN
         JECROU(3) = JECROU(3) + 1
       ELSEIF(IECROU(I) == 12)THEN
         JECROU(4) = JECROU(4) + 1
         INTERP = 1
       ENDIF
      ENDDO
C
      IF(INTERP>0)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          JPOS(J)  = NINT(POS(I))          
          JFUNC =MAX(1,IFUNC(I))
          JAD(J)   = NPF(JFUNC) / 2  + 1
          JLEN(J)  = NPF(JFUNC+1) / 2  - JAD(J)  - JPOS(J)
          XX(J) =ZERO
        ENDDO
      ENDIF
C
C-------------------------------------
C        LINEAR ELASTIC
C-------------------------------------
      IF(JECROU(1)==LLT_LOC)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J) 
          FX(I)=XK(I)*DX(I)
          XK_TAN(I) = XK(I)
        ENDDO
      ELSEIF(JECROU(1)>0)THEN
        DO J=LFT,LLT
          I = INDEXA(J) 
          IF(IFUNC(I)==0)THEN
            FX(I)=XK(I)*DX(I)
            XK_TAN(I) = XK(I)
          ENDIF
        ENDDO
      ENDIF            
C
C-------------------------------------
C        ELASTO PLASTIC (Isotropic hardening) - PERFECTLY PLASTIC IN COMPRESSION
C-------------------------------------
      IF(JECROU(2)==LLT_LOC)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)                                          
          FUND = IFUNC2(I)     ! courbe N3 de unload                                                             
          NP2  = (NPF(FUND+1)-NPF(FUND))*HALF                       
          AN3Y0(J)= ZERO
          DXELA(J)=DX(I)-DPX(I)
          IF (((DXELA(J) >= ZERO).OR.(FXEP(I) >= ZERO)).AND.(FUND > 0)) THEN
C--- Tension - load curve is used
            DO  K=2,NP2                                                       
              K1=2*(K-2)                                                
              X1=TF(NPF(FUND)+K1)                                       
              X2=TF(NPF(FUND)+K1+2)                                     
              Y1=TF(NPF(FUND)+K1+1)                                     
              Y2=TF(NPF(FUND)+K1+3) 
              IF((FXEP(I)< Y2.AND.FXEP(I)>=Y1))THEN  
                AN3Y0(J)=(Y2-Y1)/ (X2-X1)                     
                XN3FY0(I)=(FXEP(I)-Y1)/AN3Y0(J) + X1   !ABS DE N3  
                EXIT     
              ENDIF 
            ENDDO
C
            IF (AN3Y0(J)== ZERO)THEN ! extrapolation (outside of input curve points)
              X1=TF(NPF(FUND)+(NP2-2)*2)                                       
              X2=TF(NPF(FUND)+(NP2-2)*2+2)                                     
              Y1=TF(NPF(FUND)+(NP2-2)*2+1)                                     
              Y2=TF(NPF(FUND)+(NP2-2)*2+3) 
C
              XI1=TF(NPF(FUND))                                       
              XI2=TF(NPF(FUND)+2)                                     
              YI1=TF(NPF(FUND)+1)                                     
              YI2=TF(NPF(FUND)+3) 
              IF(FXEP(I)>Y2)AN3Y0(J)=(Y2-Y1)/ (X2-X1) 
              IF(FXEP(I)<YI1)AN3Y0(J)=(YI2-YI1)/ (XI2-XI1)
            ENDIF
C
C----       Crossing of compression/tension line - mix stiffness computed
            IF ((DXELA(J) < ZERO).AND.(ABS(DDX(J)) > ZERO)) THEN
              DDXT = -FXEP(I)/AN3Y0(J)
              DDXC = DDX(J) - DDXT
              AN3Y0(J) = (DDXT/DDX(J))*AN3Y0(J) + (DDXC/DDX(J))*XKC(I)
            ENDIF
C
            XX(J)=XX_OLD(I)+DDX(J)
          ELSE
C--- Compression - perfectly plastic behavior
            AN3Y0(J)= XKC(I)
          ENDIF
          FX(I)=FXEP(I)+AN3Y0(J)*DDX(J)
        ENDDO
      ELSEIF(JECROU(2)>0)THEN
        DO J=LFT,LLT_LOC
         I = INDEXA(J)
         IF(IFUNC(I)/=0.AND.IECROU(I)== 10)THEN
          FUND = IFUNC2(I)     ! N3 curve for unloading                                                             
          NP2  = (NPF(FUND+1)-NPF(FUND))*HALF                       
          AN3Y0(J)= ZERO
          DXELA(J)=DX(I)-DPX(I)
          IF (((DXELA(J) >= ZERO).OR.(FXEP(I) >= ZERO)).AND.(FUND > 0)) THEN
C--- Tension - load curve is used
            DO  K=2,NP2                                                       
              K1=2*(K-2)                                                
              X1=TF(NPF(FUND)+K1)                                       
              X2=TF(NPF(FUND)+K1+2)                                     
              Y1=TF(NPF(FUND)+K1+1)                                     
              Y2=TF(NPF(FUND)+K1+3) 
              IF((FXEP(I)< Y2.AND.FXEP(I)>=Y1))THEN  
                AN3Y0(J)=(Y2-Y1)/ (X2-X1)                     
                XN3FY0(I)=(FXEP(I)-Y1)/AN3Y0(J) + X1   !ABS OF N3  
                EXIT     
              ENDIF 
            ENDDO
C
            IF (AN3Y0(J)== ZERO)THEN ! extrapolation (outside of input curve points)
              X1=TF(NPF(FUND)+(NP2-2)*2)                                       
              X2=TF(NPF(FUND)+(NP2-2)*2+2)                                     
              Y1=TF(NPF(FUND)+(NP2-2)*2+1)                                     
              Y2=TF(NPF(FUND)+(NP2-2)*2+3) 
C
              XI1=TF(NPF(FUND))                                       
              XI2=TF(NPF(FUND)+2)                                     
              YI1=TF(NPF(FUND)+1)                                     
              YI2=TF(NPF(FUND)+3) 
              IF(FXEP(I)>Y2)AN3Y0(J)=(Y2-Y1)/ (X2-X1) 
              IF(FXEP(I)<YI1)AN3Y0(J)=(YI2-YI1)/ (XI2-XI1)
            ENDIF
C----       Crossing of compression/tension line - mix stiffness computed
            IF ((DXELA(J) < ZERO).AND.(ABS(DDX(J)) > ZERO)) THEN
              DDXT = -FXEP(I)/AN3Y0(J)
              DDXC = DDX(J) - DDXT
              AN3Y0(J) = (DDXT/DDX(J))*AN3Y0(J) + (DDXC/DDX(J))*XKC(I)
            ENDIF
C
            XX(J)=XX_OLD(I)+DDX(J)
          ELSE
C--- Compression - perfectly plastic behavior
            AN3Y0(J)= XKC(I)
          ENDIF
          FX(I)=FXEP(I)+AN3Y0(J)*DDX(J)
         ENDIF
        ENDDO
      ENDIF
C-------------------------------------
C        LINEAR ELASTIC in tension - perfleclty palstic in compression (same as 10 without curve)
C-------------------------------------
      IF(JECROU(3)==LLT_LOC)THEN
        DO J=LFT,LLT_LOC  
          I = INDEXA(J)                                                            
          AN3Y0(J)= ZERO
          DXELA(J)=DX(I)-DPX(I)
          AN3Y0(J)= XK(I)
          IF ((DXELA(J) >= ZERO).OR.(FXEP(I) >= ZERO)) THEN
C----       Crossing of compression/tension line - mix stiffness computed
            IF ((DXELA(J) < ZERO).AND.(ABS(DDX(J)) > ZERO)) THEN
              DDXT = -FXEP(I)/AN3Y0(J)
              DDXC = DDX(J) - DDXT
              AN3Y0(J) = (DDXT/DDX(J))*AN3Y0(J) + (DDXC/DDX(J))*XKC(I)
            ENDIF
          ELSE
            AN3Y0(J)= XKC(I)
          ENDIF                                                          
          FX(I)=FXEP(I)+AN3Y0(J)*DDX(J)
        ENDDO
      ELSEIF(JECROU(3)>0)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          IF(IECROU(I)== 11) THEN                      
            AN3Y0(J)= ZERO
            DXELA(J)=DX(I)-DPX(I)
            IF ((DXELA(J) >= ZERO).OR.(FXEP(I) >= ZERO)) THEN
              AN3Y0(J)= XK(I)
C----       Crossing of compression/tension line - mix stiffness computed
              IF ((DXELA(J) < ZERO).AND.(ABS(DDX(J)) > ZERO)) THEN
                DDXT = -FXEP(I)/AN3Y0(J)
                DDXC = DDX(J) - DDXT
                AN3Y0(J) = (DDXT/DDX(J))*AN3Y0(J) + (DDXC/DDX(J))*XKC(I)
              ENDIF
            ELSE
              AN3Y0(J)= XKC(I)
            ENDIF                                                          
            FX(I)=FXEP(I)+AN3Y0(J)*DDX(J)
          ENDIF
        ENDDO
      ENDIF
C-------------------------------------
C        NON LINEAR ELASTIC in tension with compression and no plasticity in compression - for 2D seatblets only
C-------------------------------------
      IF(JECROU(4)==LLT_LOC)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)                                          
          FUND = IFUNC2(I)     ! courbe N3 de unload                                                             
          NP2  = (NPF(FUND+1)-NPF(FUND))*HALF                       
          AN3Y0(J)= ZERO
          DXELA(J)=DX(I)-DPX(I)
          XXB = 0
C---      Tension - load curve is used
          DO  K=2,NP2                                                       
            K1=2*(K-2)                                                
            X1=TF(NPF(FUND)+K1)                                       
            X2=TF(NPF(FUND)+K1+2)                                     
            Y1=TF(NPF(FUND)+K1+1)                                     
            Y2=TF(NPF(FUND)+K1+3) 
            IF((FXEP(I)< Y2.AND.FXEP(I)>=Y1))THEN  
              X1S = X1
              X2S = X2
              AN3Y0(J)=(Y2-Y1)/ (X2-X1)                     
              XN3FY0(J)=(FXEP(I)-Y1)/AN3Y0(J) + X1   !ABS DE N3
              EXIT     
            ENDIF 
          ENDDO
C---      Extrapolation (outside of input curve points)
          IF (AN3Y0(J)== ZERO)THEN ! 
            X1=TF(NPF(FUND)+(NP2-2)*2)                                       
            X2=TF(NPF(FUND)+(NP2-2)*2+2)                                     
            Y1=TF(NPF(FUND)+(NP2-2)*2+1)                                     
            Y2=TF(NPF(FUND)+(NP2-2)*2+3) 
            XI1=TF(NPF(FUND))                                       
            XI2=TF(NPF(FUND)+2)                                     
            YI1=TF(NPF(FUND)+1)                                     
            YI2=TF(NPF(FUND)+3) 
            IF(FXEP(I)>Y2) THEN
              AN3Y0(J)=(Y2-Y1)/ (X2-X1) 
              XN3FY0(J)=(FXEP(I)-Y1)/AN3Y0(J) + X1
              X1S = X2
              X2S = EP20 
            ELSEIF(FXEP(I)<YI1) THEN
              AN3Y0(J)=(YI2-YI1)/ (XI2-XI1)
              XN3FY0(J)=(FXEP(I)-YI1)/AN3Y0(J) + XI1 
              X1S = -EP20
              X2S = XI1 
            ENDIF
            XK_TANSAV(J)=AN3Y0(J)
          ENDIF
          XXB =XN3FY0(J)+DDX(J)
          XK_TANSAV(J)=AN3Y0(J)
          IF (FXEP(I)==YIELD(I)) DPX(I) = XX_OLD(I) - XN3FY0(J)
C---      Next point is in another part of the curve
          IF (XXB< X1S.OR.XXB>X2S) THEN 
            XK_TANSAV(J)=ZERO       
            DO  K=2,NP2                                                       
              K1=2*(K-2)                                                
              X1=TF(NPF(FUND)+K1)                                       
              X2=TF(NPF(FUND)+K1+2)                                     
              Y1=TF(NPF(FUND)+K1+1)                                     
              Y2=TF(NPF(FUND)+K1+3)
              IF((XXB < X2.AND.XXB >=X1))THEN  
                XK_TANSAV(J)=(Y2-Y1)/ (X2-X1)
                FXB = Y1 + ((Y2-Y1)/(X2-X1))*(XXB-X1)
                AN3Y0(J)= (FXEP(I)-FXB)/ (XN3FY0(J)-XXB)
                EXIT     
              ENDIF 
            ENDDO
            IF (XK_TANSAV(J)== ZERO)THEN ! extrapolation (outside of input curve points)
              X1=TF(NPF(FUND)+(NP2-2)*2)                                       
              X2=TF(NPF(FUND)+(NP2-2)*2+2)                                     
              Y1=TF(NPF(FUND)+(NP2-2)*2+1)                                     
              Y2=TF(NPF(FUND)+(NP2-2)*2+3) 
              XI1=TF(NPF(FUND))                                       
              XI2=TF(NPF(FUND)+2)                                     
              YI1=TF(NPF(FUND)+1)                                     
              YI2=TF(NPF(FUND)+3) 
              IF(XXB>X2) THEN
                XK_TANSAV(J)=(Y2-Y1)/ (X2-X1) 
                FXB = Y2 + XK_TANSAV(J)*(XXB-X2)
              ELSEIF(XXB<XI1) THEN
                XK_TANSAV(J)=(YI2-YI1)/ (XI2-XI1) 
                FXB = YI1 + XK_TANSAV(J)*(XXB-XI1)
              ENDIF
              AN3Y0(J)= (FXEP(I)-FXB)/ (XN3FY0(J)-XXB)
            ENDIF
          ENDIF
          FX(I)=FXEP(I)+AN3Y0(J)*DDX(J)
          IF ((FXEP(I) < YIELD(I)).AND.(FX(I) > YIELD(I))) THEN
C----       Crossing of the yield line
            XX(J)=DPX(I) + XN3FY0(J) + DDX(J)
          ELSE
            XX(J)=XX_OLD(I)+DDX(J)
          ENDIF
        ENDDO
      ELSEIF(JECROU(4)>0)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          IF(IFUNC(I)/= 0.AND.IECROU(I)== 12)THEN                                           
            FUND = IFUNC2(I)     ! courbe N3 de unload                                                             
            NP2  = (NPF(FUND+1)-NPF(FUND))*HALF                       
            AN3Y0(J)= ZERO
            DXELA(J)=DX(I)-DPX(I)
            XXB = 0
C---        Tension - load curve is used
            DO  K=2,NP2                                                       
              K1=2*(K-2)                                                
              X1=TF(NPF(FUND)+K1)                                       
              X2=TF(NPF(FUND)+K1+2)                                     
              Y1=TF(NPF(FUND)+K1+1)                                     
              Y2=TF(NPF(FUND)+K1+3) 
              IF((FXEP(I)< Y2.AND.FXEP(I)>=Y1))THEN  
                X1S = X1
                X2S = X2
                AN3Y0(J)=(Y2-Y1)/ (X2-X1)                     
                XN3FY0(J)=(FXEP(I)-Y1)/AN3Y0(J) + X1   !ABS DE N3
                EXIT     
              ENDIF 
            ENDDO
C---        Extrapolation (outside of input curve points)
            IF (AN3Y0(J)== ZERO)THEN ! 
              X1=TF(NPF(FUND)+(NP2-2)*2)                                       
              X2=TF(NPF(FUND)+(NP2-2)*2+2)                                     
              Y1=TF(NPF(FUND)+(NP2-2)*2+1)                                     
              Y2=TF(NPF(FUND)+(NP2-2)*2+3) 
              XI1=TF(NPF(FUND))                                       
              XI2=TF(NPF(FUND)+2)                                     
              YI1=TF(NPF(FUND)+1)                                     
              YI2=TF(NPF(FUND)+3) 
              IF(FXEP(I)>Y2) THEN
                AN3Y0(J)=(Y2-Y1)/ (X2-X1) 
                XN3FY0(J)=(FXEP(I)-Y1)/AN3Y0(J) + X1
                X1S = X2
                X2S = EP20 
              ELSEIF(FXEP(I)<YI1) THEN
                AN3Y0(J)=(YI2-YI1)/ (XI2-XI1)
                XN3FY0(J)=(FXEP(I)-YI1)/AN3Y0(J) + XI1 
                X1S = -EP20
                X2S = XI1 
              ENDIF
              XK_TANSAV(J)=AN3Y0(J)
            ENDIF
            XXB =XN3FY0(J)+DDX(J)
            XK_TANSAV(J)=AN3Y0(J)
            IF (FXEP(I)==YIELD(I)) DPX(I) = XX_OLD(I) - XN3FY0(J)
C---        Next point is in another part of the curve
            IF (XXB< X1S.OR.XXB>X2S) THEN 
              XK_TANSAV(J)=ZERO       
              DO  K=2,NP2                                                       
                K1=2*(K-2)                                                
                X1=TF(NPF(FUND)+K1)                                       
                X2=TF(NPF(FUND)+K1+2)                                     
                Y1=TF(NPF(FUND)+K1+1)                                     
                Y2=TF(NPF(FUND)+K1+3)
                IF((XXB < X2.AND.XXB >=X1))THEN  
                  XK_TANSAV(J)=(Y2-Y1)/ (X2-X1)
                  FXB = Y1 + ((Y2-Y1)/(X2-X1))*(XXB-X1)
                  AN3Y0(J)= (FXEP(I)-FXB)/ (XN3FY0(J)-XXB)
                  EXIT     
                ENDIF 
              ENDDO
              IF (XK_TANSAV(J)== ZERO)THEN ! extrapolation (outside of input curve points)
                X1=TF(NPF(FUND)+(NP2-2)*2)                                       
                X2=TF(NPF(FUND)+(NP2-2)*2+2)                                     
                Y1=TF(NPF(FUND)+(NP2-2)*2+1)                                     
                Y2=TF(NPF(FUND)+(NP2-2)*2+3) 
                XI1=TF(NPF(FUND))                                       
                XI2=TF(NPF(FUND)+2)                                     
                YI1=TF(NPF(FUND)+1)                                     
                YI2=TF(NPF(FUND)+3) 
                IF(XXB>X2) THEN
                  XK_TANSAV(J)=(Y2-Y1)/ (X2-X1) 
                  FXB = Y2 + XK_TANSAV(J)*(XXB-X2)
                ELSEIF(XXB<XI1) THEN
                  XK_TANSAV(J)=(YI2-YI1)/ (XI2-XI1) 
                  FXB = YI1 + XK_TANSAV(J)*(XXB-XI1)
                ENDIF
                AN3Y0(J)= (FXEP(I)-FXB)/ (XN3FY0(J)-XXB)
              ENDIF
            ENDIF
            FX(I)=FXEP(I)+AN3Y0(J)*DDX(J)
            IF ((FXEP(I) < YIELD(I)).AND.(FX(I) > YIELD(I))) THEN
C----         Crossing of the yield line
              XX(J)=DPX(I) + XN3FY0(J) + DDX(J)
            ELSE
              XX(J)=XX_OLD(I)+DDX(J)
            ENDIF
          ENDIF
        ENDDO
      ENDIF
C-------------------------------------
c     VECTOR INTERPOLATION
C-------------------------------------
      DO J=LFT,LLT_LOC
        I = INDEXA(J)
        XX(J)  = XX(J) *LSCALE(I)        
      ENDDO                          
C-------------------------------------
C     SEATBELT - ELASTO PLASTIQUE (ECOUISSAGE ISOTROPE) in tension - perfleclty plastic in compression
C-------------------------------------
      IF(JECROU(2)==LLT_LOC)THEN
        CALL VINTER2(TF,JAD ,JPOS ,JLEN ,LLT_LOC,XX ,DYDX ,YY )
        DO J=LFT,LLT_LOC
           I = INDEXA(J)
           IF(FX(I)> ZERO.AND.FX(I)>YIELD(I))THEN
             POS(I) = JPOS(J)
C-- COMPUTE PLASTIC AND ELASTIC DEFORMATION (TOTAL)    
             DPX(I)=DPX(I)+(FX(I)-YY(J))/MAX(EM20,AN3Y0(J))
             FX(I)=YY(J)
             YIELD(I)=FX(I)
C-- ECR variable for hardening/softening - always incremented with positive value
             XX_OLD(I) = XX_OLD(I) + ABS(DDX(J))
             XK_TAN(I) = DYDX(J)
          ELSEIF(FX(I)<= -FX_MAX(I))THEN
             YY(J) = -FX_MAX(I)
C-- COMPUTE PLASTIC DEFORMATION (TOTAL)  
             IF (XKC(I) > ZERO) DPX(I)=DPX(I)+(-YY(J)+FX(I))/MAX(EM20,AN3Y0(J))
             FX(I)=YY(J)
             XK_TAN(I) = XK(I)
          ELSE
            XK_TAN(I) = AN3Y0(J)
          ENDIF
          FXEP(I)=FX(I)
        ENDDO
      ELSEIF(JECROU(2)>0)THEN
        CALL VINTER2(TF,JAD ,JPOS ,JLEN ,LLT_LOC,XX ,DYDX ,YY )
        DO J=LFT,LLT_LOC
         I = INDEXA(J)
         IF(IFUNC(I)/= 0.AND.IECROU(I)== 10)THEN
           IF(FX(I)> ZERO.AND.FX(I)>YIELD(I))THEN
             POS(I) = JPOS(J)
C-- COMPUTE PLASTIC AND ELASTIC DEFORMATION (TOTAL)    
             DPX(I)=DPX(I)+(FX(I)-YY(J))/MAX(EM20,AN3Y0(J))
             FX(I)=YY(J)
             YIELD(I)=FX(I)
C-- ECR variable for hardening/softening - always incremented with positive value
             XX_OLD(I) = XX_OLD(I) + ABS(DDX(J))
             XK_TAN(I) = DYDX(J)
          ELSEIF(FX(I)<= -FX_MAX(I))THEN
             YY(J) = -FX_MAX(I)
C-- COMPUTE PLASTIC DEFORMATION (TOTAL)  
             IF (XKC(I) > ZERO) DPX(I)=DPX(I)+(-YY(J)+FX(I))/MAX(EM20,AN3Y0(J))
             FX(I)=YY(J)
             XK_TAN(I) = XK(I)
          ELSE
            XK_TAN(I) = AN3Y0(J)
          ENDIF
          FXEP(I)=FX(I)
         ENDIF
        ENDDO
      ENDIF
C-------------------------------------
C     SEATBELT - LINEAR ELASTIC in tension - perfleclty plastic in compression
C-------------------------------------
      IF(JECROU(3)==LLT_LOC)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          IF(FX(I)<= -FX_MAX(I))THEN
            YY(J) = -FX_MAX(I)
C-- COMPUTE PLASTIC DEFORMATION (TOTAL)  
            IF (XKC(I) > ZERO) DPX(I)=DPX(I)+(-YY(J)+FX(I))/MAX(EM20,AN3Y0(J))
            FX(I)=YY(J)
            XK_TAN(I) = XK(I)
          ELSE
            XK_TAN(I) = AN3Y0(J)
          ENDIF
          FXEP(I)=FX(I)
        ENDDO
      ELSEIF(JECROU(3)>0)THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          IF(IECROU(I)== 11)THEN
            IF(FX(I)<= -FX_MAX(I))THEN
              YY(J) = -FX_MAX(I)
C-- COMPUTE PLASTIC DEFORMATION (TOTAL)  
              IF (XKC(I) > ZERO) DPX(I)=DPX(I)+(-YY(J)+FX(I))/MAX(EM20,AN3Y0(J))
              FX(I)=YY(J)
              XK_TAN(I) = XK(I)
            ELSE
              XK_TAN(I) = AN3Y0(J)
            ENDIF
            FXEP(I)=FX(I)
          ENDIF
        ENDDO
      ENDIF
C-------------------------------------
C     NON LINEAR ELASTIC in tension with compression and no plasticity in compression - for 2D seatblets only
C-------------------------------------
      IF(JECROU(4)==LLT_LOC)THEN
        CALL VINTER2(TF,JAD ,JPOS ,JLEN ,LLT_LOC,XX ,DYDX ,YY )
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          IF(FX(I)> ZERO.AND.FX(I)>YIELD(I))THEN
            POS(I) = JPOS(J)
C-- COMPUTE PLASTIC AND ELASTIC DEFORMATION (TOTAL)
            FX(I)=YY(J)
            YIELD(I)=FX(I)
C-- ECR variable for hardening/softening - always incremented with positive value
            XX_OLD(I) = MAX(XX_OLD(I),ABS(XX(J)))
            XK_TAN(I) = DYDX(J)
          ELSE
            XK_TAN(I) = XK_TANSAV(J)
          ENDIF
          FXEP(I)=FX(I)
        ENDDO
      ELSEIF(JECROU(4)>0)THEN
        CALL VINTER2(TF,JAD ,JPOS ,JLEN ,LLT_LOC,XX ,DYDX ,YY )
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          IF(IFUNC(I)/= 0.AND.IECROU(I)== 12)THEN
            IF(FX(I)> ZERO.AND.FX(I)>YIELD(I))THEN
              POS(I) = JPOS(J)
C-- COMPUTE PLASTIC AND ELASTIC DEFORMATION (TOTAL)
              FX(I)=YY(J)
              YIELD(I)=FX(I)
C-- ECR variable for hardening/softening - always incremented with positive value
              XX_OLD(I) = MAX(XX_OLD(I),ABS(XX(J)))
              XK_TAN(I) = DYDX(J)
            ELSE
              XK_TAN(I) = XK_TANSAV(J)
            ENDIF
            FXEP(I)=FX(I)
          ENDIF
        ENDDO
      ENDIF
C--------------------------------------------------------------------
C     NON LINEAR DAMPING
C--------------------------------------------------------------------
      IF(IMPL_S==0.OR.IDYNA>0) THEN
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          FX(I)= (AK(I)*FX(I) + XC(I)*DVX(J)) *OFF(I)
          E(I) = E(I) + (DX(I)-DXOLD(I)) * (FX(I)+FOLD(J)) * HALF
        ENDDO
      ELSE
        DO J=LFT,LLT_LOC
          I = INDEXA(J)
          FX(I)= FX(I)  *AK(I)* OFF(I)
          E(I) = E(I) + (DX(I)-DXOLD(I)) * (FX(I)+FOLD(J)) * HALF
        ENDDO
      ENDIF
c-------------------------  
      DO J=LFT,LLT_LOC
        I = INDEXA(J)
        DX(I)=DX(I)*XL0(I)
        DXOLD(I)=DXOLD(I)*XL0(I)
        E(I)=E(I)*XL0(I)
        XK_TAN(I) = XK_TAN(I)*FRAM_FACTOR(I)
      ENDDO
C
C----
      RETURN
      END
