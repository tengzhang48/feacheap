program feacheap
  use Types
  use ParamIO
  use Globals
  use Controlparameters
  implicit none
 
  integer :: nargs
  character (len=256) :: arg1, arg2

! ============================================================
!   feacheap — Finite element analysis code
!
!   Originally EN234_FEA by Prof. Allan Bower, Brown University.
!   Renamed feacheap for use as a standalone research solver.
!
!   Usage:
!     ./feacheap                              (uses default input below)
!     ./feacheap input.in                     (output auto-named)
!     ./feacheap input.in output.out          (explicit paths)
!
!   The root_directory is prepended to relative paths.
!   Set to './' for command-line builds (Linux/macOS/gfortran).
!   Change to an absolute path for Visual Studio builds on Windows.
! ============================================================

  root_directory = './'

! --- Parse command-line arguments ---
  nargs = command_argument_count()

  if (nargs >= 2) then
!     Both input and output specified on command line
      call get_command_argument(1, arg1)
      call get_command_argument(2, arg2)
      infil  = trim(arg1)
      outfil = trim(arg2)

  else if (nargs == 1) then
!     Input file specified; derive output file name
      call get_command_argument(1, arg1)
      infil  = trim(arg1)
      outfil = trim(arg1) // '.out'

  else
!     No arguments — use the default input file below.
!     Uncomment ONE pair of infil/outfil lines.

!   -------------------------------------------------------
!   Demo codes
!   -------------------------------------------------------

!   Small strain linear elasticity UEL (3D)
   infil = 'input_files/Abaqus_uel_linear_elastic_3d.in'
   outfil = 'Output_Files/Abaqus_uel_linear_elastic_3d.out'

!   Hole-in-a-plate with ABAQUS UEL
!   infil = 'input_files/Abaqus_uel_holeplate_3d.in'
!   outfil = 'Output_Files/Abaqus_uel_holeplate_3d.out'

!   ABAQUS VUEL (explicit dynamic, 1 element)
!   infil = 'input_files/Abaqus_vuel_linear_elastic_3d.in'
!   outfil = 'Output_Files/Abaqus_vuel_linear_elastic_3d.out'

!   Hole-in-a-plate explicit dynamic with VUEL
!   infil = 'input_files/Abaqus_uel_holeplate_3d.in'
!   outfil = 'Output_Files/Abaqus_uel_holeplate_3d.out'

!   ABAQUS UMAT (linear elastic, 2 elements)
!   infil = 'input_files/Abaqus_umat_linear_elastic_3d.in'
!   outfil = 'Output_Files/Abaqus_umat_linear_elastic_3d.out'

!   UMAT hole-in-a-plate
!   infil = 'input_files/Abaqus_umat_holeplate_3d.in'
!   outfil = 'Output_Files/Abaqus_umat_holeplate_3d.out'

!   VUMAT hole-in-a-plate
!   infil = 'input_files/Abaqus_vumat_linear_elastic_3d.in'
!   outfil = 'Output_Files/Abaqus_vumat_linear_elastic_3d.out'

!   -------------------------------------------------------
!   Homework problems
!   -------------------------------------------------------

!   HW3: 2D linear elastic UEL
!   infil = 'input_files/Abaqus_uel_linear_elastic_2d.in'
!   outfil = 'Output_Files/Abaqus_uel_linear_elastic_2d.out'

!   HW3: Hole-in-a-plate, 4-noded quads
!   infil = 'input_files/Abaqus_uel_holeplate_2d_quad4.in'
!   outfil = 'Output_Files/Abaqus_uel_holeplate_2d_quad4.out'

!   HW3: Hole-in-a-plate, 8-noded quads
!   infil = 'input_files/Abaqus_uel_holeplate_2d_quad8.in'
!   outfil = 'Output_Files/Abaqus_uel_holeplate_2d_quad8.out'

!   HW3: Hole-in-a-plate, 3-noded triangles
!   infil = 'input_files/Abaqus_uel_holeplate_2d_tri3.in'
!   outfil = 'Output_Files/Abaqus_uel_holeplate_2d_tri3.out'

!   HW3: Hole-in-a-plate, 6-noded triangles
!   infil = 'input_files/Abaqus_uel_holeplate_2d_tri6.in'
!   outfil = 'Output_Files/Abaqus_uel_holeplate_2d_tri6.out'

!   HW5: Cantilever beam (incompatible modes)
!   infil = 'input_files/Abaqus_uel_cantilever.in'
!   outfil = 'Output_Files/Abaqus_uel_cantilever.out'

!   HW6: Porous elasticity UMAT
!   infil = 'input_files/Abaqus_umat_porous_elastic.in'
!   outfil = 'Output_Files/Abaqus_umat_porous_elastic.out'

!   HW7: Hyperelastic UEL
!   infil = 'input_files/Abaqus_uel_hyperelastic.in'
!   outfil = 'Output_Files/Abaqus_uel_hyperelastic.out'

!   HW7: Hyperelastic UMAT
!   infil = 'input_files/Abaqus_umat_hyperelastic2.in'
!   outfil = 'Output_Files/Abaqus_umat_hyperelastic.out'

!   HW8: Phase-field with elasticity (1 element)
!   infil = 'input_files/Abaqus_uel_phasefield_1el.in'
!   outfil = 'Output_Files/Abaqus_uel_phasefield_1el.out'

!   HW8: Phase-field coarse mesh
!   infil = 'input_files/Abaqus_uel_phasefield_coarse.in'
!   outfil = 'Output_Files/Abaqus_uel_phasefield_coarse.out'

!   HW8: Phase-field fine mesh
!   infil = 'input_files/Abaqus_uel_phasefield_fine.in'
!   outfil = 'Output_Files/Abaqus_uel_phasefield_fine.out'

!   HW9: McCormick model (explicit dynamic, 1 element)
!   infil = 'input_files/Abaqus_vumat_McCormick.in'
!   outfil = 'Output_Files/Abaqus_vumat_McCormick.out'

!   HW10: Continuum beam element
!   infil = 'input_files/Abaqus_uel_continuum_beam.in'
!   outfil = 'Output_Files/Abaqus_uel_continuum_beam.out'

  endif

! --- Open files and run ---
   infil = trim(root_directory)//trim(infil)
   outfil = trim(root_directory)//trim(outfil)

   write(6,'(A,A)') ' Input:  ', trim(infil)
   write(6,'(A,A)') ' Output: ', trim(outfil)

   open (unit = IOR, file = trim(infil), status = 'old', ERR=500)
   open (UNIT = IOW, FILE = trim(outfil), STATUS = 'unknown', ERR=500)
   
   call read_input_file
  
   if (printinitialmesh) call print_initial_mesh

   if (checkstiffness) call check_stiffness(checkstiffness_elementno)
   if (checktangent) call check_tangent(checktangent_materialno)

   if (staticstep) then
      call compute_static_step
      if (checkstiffness) call check_stiffness(checkstiffness_elementno)
      if (checktangent) call check_tangent(checktangent_materialno)
   endif
  
   if (explicitdynamicstep) call explicit_dynamic_step
  
   write(6,*) ' feacheap completed successfully '

   stop
  
  500 write(6,*) ' Error opening input or output file '
      write(6,'(A,A)') '   Input:  ', trim(infil)
      write(6,'(A,A)') '   Output: ', trim(outfil)
      error stop 1

end program feacheap
