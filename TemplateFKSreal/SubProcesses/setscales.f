c Functions that set the scales and compute alphaS
c
c The renormalization, the two factorization, and the Ellis-Sexton scales
c are treated independently. For each of them, one has
c
c   scale = ratio_over_ref * reference_scale
c
c The values of ratio_over_ref must be given in run_card.dat
c (muR_over_ref, muF1_over_ref, muF2_over_ref, QES_over_ref).
c The reference scale is either a fixed value, given in run_card.dat
c (muR_ref_fixed, muF1_ref_fixed, muF2_ref_fixed, QES_ref_fixed),
c or is computed dynamically, by the functions:
c  
c   function muR_ref_dynamic(pp)
c   function muF_ref_dynamic(pp)
c   function QES_ref_dynamic(pp)
c
c which can be found in this file. Note, then, that when choosing
c dynamic factorization scales the reference scale for the two legs
c is the same; the scales can still be different, if muF1_over_ref is
c not equal to muF2_over_ref. This condition can be easily relaxed.
c However, in order to do so we must first implement formulae that
c take the muF1#muF2 case into account at the NLO. With fixed reference
c scales, this condition is easily enforced before starting the integration.
c
c The bodies of the functions above are independent of each other.
c The easiest way to set them all equal is that of choosing
c imurtype=1, imuftype=1, and iQEStype=1 (these parameters are
c local to the bodies of the correspondent functions). This 
c will set the function above equal to the return value of
c   function scale_global_reference(pp)
c which again can be found in this file
c 
c When calling set_alphaS for the first time, that routine will print
c out the numerical values of the scales, and a string which is supposed
c to give the functional form used for the reference scales. This will
c be done automatically, provided that for each new functional form
c introduced one stores a corresponding ID string in the variable
c   temp_scale_id
c in the bodies of the functions
c   function muR_ref_dynamic(pp)
c   function muF_ref_dynamic(pp)
c   function QES_ref_dynamic(pp)
c   function scale_global_reference(pp)
c


      subroutine set_alphaS(xp)
c This subroutine sets the values of the renormalization, factorization,
c and Ellis-Sexton scales, and computes the value of alpha_S through the
c call to set_ren_scale (for backward compatibility).
c The scale and couplings values are updated in the relevant common blocks
c (mostly in run.inc, and one  in coupl.inc)
      implicit none
      include "genps.inc"
      include "nexternal.inc"
      include "run.inc"
      include "coupl.inc"

      double precision xp(0:3,nexternal)
      double precision dummy,dummyQES,dummies(2)
      integer i,j

      character*80 muR_id_str,muF1_id_str,muF2_id_str,QES_id_str
      common/cscales_id_string/muR_id_str,muF1_id_str,
     #                         muF2_id_str,QES_id_str

c put momenta in common block for couplings.f
      double precision PP(0:3,max_particles)
      COMMON /MOMENTA_PP/PP

      logical firsttime
      data firsttime/.true./

c After recomputing alphaS, be sure to set 'calculatedBorn' to false
      double precision hel_fac
      logical calculatedBorn
      integer get_hel,skip
      common/cBorn/hel_fac,calculatedBorn,get_hel,skip
c
      if (firsttime) then
        firsttime=.false.
c Set scales and check that everything is all right
c Renormalization
        call set_ren_scale(xp,dummy)
        if(dummy.lt.0.2d0)then
          write(*,*)'Error in set_alphaS: muR too soft',dummy
          stop
        endif
c Factorization
        call set_fac_scale(xp,dummies)
        if(dummies(1).lt.0.2d0.or.dummies(2).lt.0.2d0)then
          write(*,*)'Error in set_alphaS: muF too soft',
     #              dummies(1),dummies(2)
          stop
        endif
c Ellis-Sexton
        call set_QES_scale(xp,dummyQES)
        if(scale.lt.0.2d0)then
          write(*,*)'Error in set_alphaS: QES too soft',dummyQES
          stop
        endif
c
        write(*,*)'Scale values (may change event by event):'
        write(*,200)'muR,  muR_reference: ',dummy,
     #              dummy/muR_over_ref,muR_over_ref
        write(*,200)'muF1, muF1_reference:',dummies(1),
     #              dummies(1)/muF1_over_ref,muF1_over_ref
        write(*,200)'muF2, muF2_reference:',dummies(2),
     #              dummies(2)/muF2_over_ref,muF2_over_ref
        write(*,200)'QES,  QES_reference: ',dummyQES,
     #              dummyQES/QES_over_ref,QES_over_ref
        write(*,*)' '
        write(*,*)'muR_reference [functional form]:'
        write(*,*)'   ',muR_id_str(1:len_trim(muR_id_str))
        write(*,*)'muF1_reference [functional form]:'
        write(*,*)'   ',muF1_id_str(1:len_trim(muF1_id_str))
        write(*,*)'muF2_reference [functional form]:'
        write(*,*)'   ',muF2_id_str(1:len_trim(muF2_id_str))
        write(*,*)'QES_reference [functional form]: '
        write(*,*)'   ',QES_id_str(1:len_trim(QES_id_str))
        write(*,*)' '
        write(*,*) 'alpha_s=',g**2/(16d0*atan(1d0))
c
        if(fixed_ren_scale) then
          call setpara('param_card.dat',.false.)
        endif
c Put momenta in the common block to zero to start
        do i=0,3
          do j=1,max_particles
            pp(i,j) = 0d0
          enddo
        enddo
      endif
c
c Recompute scales if dynamic
c Note: Ellis-Sexton scale must be computed before calling setpara(),
c since some R2 couplings depend on it
      if(.not.fixed_ren_scale) then
        call set_ren_scale(xp,dummy)
      endif

      if(.not.fixed_fac_scale) then
        call set_fac_scale(xp,dummies)
      endif

      if(.not.fixed_QES_scale) then
        call set_QES_scale(xp,dummyQES)
      endif
c

c Pass momenta to couplings.f
      if ( .not.fixed_ren_scale.or.
     &         .not.fixed_couplings.or.
     &             .not.fixed_QES_scale) then
        if (.not.fixed_couplings)then
          do i=0,3
            do j=1,nexternal
              PP(i,j)=xp(i,j)
            enddo
          enddo
        endif
         call setpara('param_card.dat',.false.)
      endif

c Reset calculatedBorn, because the couplings might have been changed.
c This is needed in particular for the MC events, because there the
c coupling should be set according to the real-emission kinematics,
c even when computing the Born matrix elements.
      calculatedBorn=.false.

 200  format(1x,a,2(1x,d12.6),2x,f4.2)

      return
      end


      subroutine set_ren_scale(pp,muR)
c Sets the value of the renormalization scale, returned as muR.
c For backward compatibility, computes the value of alpha_S, and sets 
c the value of variable scale in common block /to_scale/
      implicit none
      include 'genps.inc'
      include 'nexternal.inc'
      include 'run.inc'
      include 'coupl.inc'
      double precision pp(0:3,nexternal),muR
      double precision mur_temp,mur_ref_dynamic,alphas
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      character*80 muR_id_str,muF1_id_str,muF2_id_str,QES_id_str
      common/cscales_id_string/muR_id_str,muF1_id_str,
     #                         muF2_id_str,QES_id_str
      character*80 temp_scale_id
      common/ctemp_scale_id/temp_scale_id
c
      temp_scale_id='  '
      if(fixed_ren_scale)then
        mur_temp=muR_ref_fixed
        temp_scale_id='fixed'
      else
        mur_temp=muR_ref_dynamic(pp)
      endif
      muR=muR_over_ref*mur_temp
      muR2_current=muR**2
      muR_id_str=temp_scale_id
c The following is for backward compatibility. DO NOT REMOVE
      scale=muR
      g=sqrt(4d0*pi*alphas(scale))
c
      return
      end


      function muR_ref_dynamic(pp)
c This is a function of the kinematic configuration pp, which returns
c a scale to be used as a reference for renormalization scale
      implicit none
      include 'genps.inc'
      include 'nexternal.inc'
      double precision muR_ref_dynamic,pp(0:3,nexternal)
      double precision tmp,scale_global_reference,pt
      external pt
      character*80 temp_scale_id
      common/ctemp_scale_id/temp_scale_id
      integer i,imurtype
      parameter (imurtype=1)
c
      tmp=0
      if(imurtype.eq.1)then
        tmp=scale_global_reference(pp)
      elseif(imurtype.eq.2)then
        do i=nincoming+1,nexternal
          tmp=tmp+pt(pp(0,i))
        enddo
        temp_scale_id='sum_i pT(i), i=final state'
      else
        write(*,*)'Unknown option in muR_ref_dynamic',imurtype
        stop
      endif
      muR_ref_dynamic=tmp
c
      return
      end


      subroutine set_fac_scale(pp,muF)
c Sets the values of the factorization scales, returned as muF().
c For backward compatibility, sets the values of variables q2fact()
c in common block /to_collider/
c Note: the old version returned the factorization scales squared
      implicit none
      include 'genps.inc'
      include 'nexternal.inc'
      include 'run.inc'
      include 'coupl.inc'
      double precision pp(0:3,nexternal),muF(2)
      double precision muf_temp(2),muF_ref_dynamic
      character*80 muR_id_str,muF1_id_str,muF2_id_str,QES_id_str
      common/cscales_id_string/muR_id_str,muF1_id_str,
     #                         muF2_id_str,QES_id_str
      character*80 temp_scale_id,temp_scale_id2
      common/ctemp_scale_id/temp_scale_id
c
      temp_scale_id='  '
      temp_scale_id2='  '
      if(fixed_fac_scale)then
        muf_temp(1)=muF1_ref_fixed
        muf_temp(2)=muF2_ref_fixed
        temp_scale_id='fixed'
        temp_scale_id2='fixed'
      else
        muf_temp(1)=muF_ref_dynamic(pp)
        muf_temp(2)=muf_temp(1)
        temp_scale_id2=temp_scale_id
      endif
      muF(1)=muF1_over_ref*muf_temp(1)
      muF(2)=muF2_over_ref*muf_temp(2)
      muF12_current=muF(1)**2
      muF22_current=muF(2)**2
      muF1_id_str=temp_scale_id
      muF2_id_str=temp_scale_id2
c The following is for backward compatibility. DO NOT REMOVE
      q2fact(1)=muF12_current
      q2fact(2)=muF22_current
c
      return
      end


      function muF_ref_dynamic(pp)
c This is a function of the kinematic configuration pp, which returns
c a scale to be used as a reference for factorizations scales
      implicit none
      include 'genps.inc'
      include 'nexternal.inc'
      double precision muF_ref_dynamic,pp(0:3,nexternal)
      double precision tmp,scale_global_reference,pt
      external pt
      character*80 temp_scale_id
      common/ctemp_scale_id/temp_scale_id
      integer i,imuftype
      parameter (imuftype=1)
c
      tmp=0
      if(imuftype.eq.1)then
        tmp=scale_global_reference(pp)
      elseif(imuftype.eq.2)then
        do i=nincoming+1,nexternal
          tmp=tmp+pt(pp(0,i))**2
        enddo
        tmp=sqrt(tmp)
        temp_scale_id='Sqrt[sum_i pT(i)**2], i=final state'
      else
        write(*,*)'Unknown option in muF_ref_dynamic',imuftype
        stop
      endif
      muF_ref_dynamic=tmp
c
      return
      end


      subroutine set_QES_scale(pp,QES)
c Sets the value of the Ellis-Sexton scale, returned as QES.
c For backward compatibility, sets the value of variable QES2 
c (Ellis-Sexton scale squared) in common block /COUPL_ES/
      implicit none
      include 'genps.inc'
      include 'nexternal.inc'
      include 'run.inc'
      include 'coupl.inc'
      include 'q_es.inc'
      double precision pp(0:3,nexternal),QES
      double precision QES_temp,QES_ref_dynamic
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      character*80 muR_id_str,muF1_id_str,muF2_id_str,QES_id_str
      common/cscales_id_string/muR_id_str,muF1_id_str,
     #                         muF2_id_str,QES_id_str
      character*80 temp_scale_id
      common/ctemp_scale_id/temp_scale_id
c
      temp_scale_id='  '
      if(fixed_QES_scale)then
        QES_temp=QES_ref_fixed
        temp_scale_id='fixed'
      else
        QES_temp=QES_ref_dynamic(pp)
      endif
      QES=QES_over_ref*QES_temp
      QES2_current=QES**2
      QES_id_str=temp_scale_id
c The following is for backward compatibility. DO NOT REMOVE
      QES2=QES2_current
c
      return
      end


      function QES_ref_dynamic(pp)
c This is a function of the kinematic configuration pp, which returns
c a scale to be used as a reference for Ellis-Sexton scale
      implicit none
      include 'genps.inc'
      include 'nexternal.inc'
      double precision QES_ref_dynamic,pp(0:3,nexternal)
      double precision tmp,scale_global_reference,pt
      external pt
      character*80 temp_scale_id
      common/ctemp_scale_id/temp_scale_id
      integer i,iQEStype
      parameter (iQEStype=1)
c
      tmp=0
      if(iQEStype.eq.1)then
        tmp=scale_global_reference(pp)
      elseif(iQEStype.eq.2)then
        do i=nincoming+1,nexternal
          tmp=tmp+pt(pp(0,i))
        enddo
        temp_scale_id='sum_i pT(i), i=final state'
      else
        write(*,*)'Unknown option in QES_ref_dynamic',iQEStype
        stop
      endif
      QES_ref_dynamic=tmp
c
      return
      end


      function scale_global_reference(pp)
c This is a function of the kinematic configuration pp, which returns
c a scale to be used as a reference for renormalization scale
      implicit none
      include 'genps.inc'
      include 'nexternal.inc'
      double precision scale_global_reference,pp(0:3,nexternal)
      double precision tmp,pt,et,dot
      external pt,et,dot
      integer i,itype
      parameter (itype=1)
      character*80 temp_scale_id
      common/ctemp_scale_id/temp_scale_id
c
      tmp=0
      if(itype.eq.1)then
c Sum of transverse energies
        do i=nincoming+1,nexternal
          tmp=tmp+et(pp(0,i))
        enddo
        temp_scale_id='sum_i eT(i), i=final state'
      elseif(itype.eq.2)then
c Sum of transverse masses
        do i=nincoming+1,nexternal
          tmp=tmp+sqrt(pt(pp(0,i))**2+dot(pp(0,i),pp(0,i)))
        enddo
        temp_scale_id='sum_i mT(i), i=final state'
      else
        write(*,*)'Unknown option in scale_global_reference',itype
        stop
      endif
      scale_global_reference=tmp
c
      return
      end