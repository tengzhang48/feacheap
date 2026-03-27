# feacheap — Build, Run, and Development Guide

## Overview

feacheap is an open-source finite element analysis solver originally
developed as EN234_FEA by Prof. Allan Bower at Brown University. It
runs Abaqus-compatible UEL, UMAT, VUEL, and VUMAT subroutines without
requiring an Abaqus license. Code that works in feacheap will run in
Abaqus without modification.

**Upstream repository**: https://github.com/albower/EN234_FEA

**Capabilities**:
- Static linear and nonlinear analysis (Newton-Raphson)
- Explicit dynamic analysis
- Abaqus UEL and UMAT interface (exact calling convention)
- Built-in stiffness and material tangent checking (FD verification)
- Direct (skyline) and conjugate gradient solvers
- Support for heterogeneous DOF counts per node (multi-field elements)
- SVARS persistence, PNEWDT time step control, state variable commit

---

## 1. Setup

### 1.1 Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get install gfortran make git

# macOS (Homebrew)
brew install gcc git    # gcc includes gfortran

# Verify
gfortran --version
```

### 1.2 Create feacheap from EN234_FEA

Clone the upstream repository and copy the working directory into a
clean `feacheap/` folder:

```bash
# Clone upstream
git clone https://github.com/albower/EN234_FEA.git

# Copy the project directory into feacheap/
cp -r EN234_FEA/EN234_FEA feacheap

# Apply the patch files (from en234fea_patch/)
cp en234fea_patch/src/main.f90         feacheap/src/main.f90
cp en234fea_patch/src/staticstep.f90   feacheap/src/staticstep.f90
cp en234fea_patch/build.sh             feacheap/build.sh
cp en234fea_patch/ABA_PARAM.INC        feacheap/ABA_PARAM.INC
cp en234fea_patch/.gitignore           feacheap/.gitignore

# Optionally remove the upstream clone
rm -rf EN234_FEA

# Initialize as a new git repo
cd feacheap
git init
git add -A
git commit -m "feacheap: initial setup from EN234_FEA + build patch"
```

### 1.3 Build and Run

```bash
cd feacheap
bash build.sh           # release build (-O2)
./feacheap              # run default example (3D linear elastic UEL)
```

For debug builds with bounds checking and backtraces:

```bash
bash build.sh debug
```

### 1.4 Run with a Specific Input File

The patched `main.f90` accepts command-line arguments — no need to
edit source and recompile to switch inputs:

```bash
./feacheap input_files/Abaqus_uel_linear_elastic_3d.in Output_Files/uel_test.out
./feacheap input_files/Abaqus_umat_linear_elastic_3d.in Output_Files/umat_test.out
./feacheap input_files/my_custom_test.in Output_Files/my_test.out
```

If no arguments are given, the default input file (set in `src/main.f90`)
is used.

---

## 2. Directory Structure

```
feacheap/
├── src/                        # Core solver source files
│   ├── main.f90                # Entry point (program feacheap)
│   ├── staticstep.f90          # Newton-Raphson static solver
│   ├── solver_direct.f90       # Assembly + skyline direct solver
│   ├── solver_conjugate_gradient.f90  # CG solver
│   ├── checktangent.f90        # Material tangent FD check
│   ├── checkstiffness.f90      # Element stiffness FD check
│   ├── explicit_dynamic_step.f90      # Explicit dynamic time integration
│   ├── continuum_elements.f90         # Internal element library
│   ├── read_input_file.f90     # Input file parser
│   ├── printing.f90            # Output routines (Tecplot format)
│   ├── parse.f90               # String parsing utilities
│   ├── bandwidth_minimizer.f90 # Cuthill-McKee bandwidth optimization
│   └── traction_boundarycondition.f90 # Distributed load handling
├── modules/                    # Fortran modules (data structures, globals)
│   ├── Types.f90               # Precision types (prec = real*8)
│   ├── ParamIO.f90             # I/O parameters (unit numbers)
│   ├── Globals.f90             # Global variables (TIME, DTIME, etc.)
│   ├── Mesh.f90                # Mesh data structures (node, element types)
│   ├── Stiffness.f90           # Stiffness storage module
│   ├── Controlparameters.f90   # Analysis control parameters
│   ├── Staticstepparameters.f90    # Static step settings
│   ├── Dynamicstepparameters.f90   # Dynamic step settings
│   ├── Boundaryconditions.f90      # BC data structures
│   ├── Fileparameters.f90          # File path parameters
│   ├── Printparameters.f90         # Print control parameters
│   ├── Linkedlist_Handling.f90     # Linked list utilities
│   ├── Bandwidth.f90               # Bandwidth storage
│   └── User_Subroutine_Storage.f90 # UEL/UMAT storage parameters
├── input_files/                # Example input files
│   ├── Abaqus_uel_linear_elastic_3d.in
│   ├── Abaqus_uel_holeplate_3d.in
│   ├── Abaqus_umat_linear_elastic_3d.in
│   └── [other .in files]
├── user_codes/
│   └── src/                    # User element and material subroutines
│       ├── abaqus_uel_3d.for       # 3D linear elastic UEL example
│       ├── abaqus_uel_2d.for       # 2D UEL template
│       ├── abaqus_umat_elastic.for # Linear elastic UMAT example
│       ├── abaqus_vuel.for         # VUEL example (explicit)
│       ├── abaqus_vumat.for        # VUMAT example (explicit)
│       ├── user_element.f90        # Dispatcher for EN234-format elements
│       └── user_mesh.f90           # User mesh generation
├── Output_Files/               # Results written here
├── build.sh                    # Build script
├── ABA_PARAM.INC               # Abaqus include stub
└── .gitignore
```

---

## 3. Input File Format

Input files use a keyword-based format with `%` as the comment
character. The file has three major sections: mesh definition,
boundary conditions, and analysis definition.

### 3.1 Mesh Definition

#### Nodes

```
NODES
  PARAMETERS, 3, 3, 0    % n_coords, n_dof, flag
  COORDINATES
    0.0, 0.0, 0.0        % node 1
    1.0, 0.0, 0.0        % node 2
    1.0, 1.0, 0.0        % node 3
    0.0, 1.0, 0.0        % node 4
    ...
  END COORDINATES
END NODES
```

- `PARAMETERS, n_coords, n_dof, flag`:
  - `n_coords`: number of spatial coordinates (2 or 3)
  - `n_dof`: number of degrees of freedom per node
  - `flag`: integer identifier (optional, for distinguishing node types)
- Node numbers are sequential (first defined = node 1)
- For multi-physics with different DOF counts per node, use multiple
  PARAMETERS/COORDINATES blocks:

```
NODES
  PARAMETERS, 2, 4, 1      % corner nodes: 2 coords, 4 DOFs
  COORDINATES
    0.0, 0.0               % node 1 (corner)
    1.0, 0.0               % node 2 (corner)
    1.0, 1.0               % node 3 (corner)
    0.0, 1.0               % node 4 (corner)
  END COORDINATES
  PARAMETERS, 2, 3, 2      % midside nodes: 2 coords, 3 DOFs
  COORDINATES
    0.5, 0.0               % node 5 (midside)
    1.0, 0.5               % node 6 (midside)
    0.5, 1.0               % node 7 (midside)
    0.0, 0.5               % node 8 (midside)
  END COORDINATES
  DISPLACEMENT DOF, 1, 2   % DOFs 1 and 2 are displacements
END NODES
```

The `DISPLACEMENT DOF` keyword specifies which DOFs represent
displacements (for plotting the deformed mesh). Default: first 3 DOFs.

#### Materials (for UMAT/VUMAT with internal elements)

```
MATERIAL, steel
  STATE VARIABLES, 15
  PROPERTIES
    200000.d0, 0.3d0
  END PROPERTIES
END MATERIAL
```

#### Elements

**User elements (UEL/VUEL)**:

```
ELEMENTS, USER
  PARAMETERS, 8, 0, 100001   % n_nodes, n_state_vars, identifier
  PROPERTIES
    100.d0, 0.3d0             % element properties (passed as PROPS)
  END PROPERTIES
  CONNECTIVITY, zone1        % zone name for Tecplot output
    1, 2, 3, 4, 5, 6, 7, 8   % element 1: node connectivity
    ...
  END CONNECTIVITY
END ELEMENTS
```

- `PARAMETERS, n_nodes, n_state_vars, identifier`:
  - `n_nodes`: nodes per element
  - `n_state_vars`: total SVARS for the element (all integration points)
  - `identifier`: passed as JTYPE to UEL. The code adds 100000 internally,
    so identifier `1` becomes JTYPE = 100001 in the UEL call.
- PROPERTIES values are passed as the PROPS array to the UEL

**Internal elements (with UMAT)**:

```
ELEMENTS, INTERNAL
  TYPE, C3D20                 % element type
  MATERIAL, steel             % reference to material definition
  CONNECTIVITY, block
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
    ...
  END CONNECTIVITY
END ELEMENTS
```

Supported internal element types: CPE3, CPE4, CPE6, CPE8, C3D4, C3D8,
C3D10, C3D20. All use finite strain (NLGEOM equivalent).

#### User-defined mesh

```
MESH
  USER SUBROUTINE
    10, 20, 30.d0    % parameters passed to user_mesh.f90
  END USER SUBROUTINE
END MESH
```

### 3.2 Boundary Conditions

#### History definitions (time-dependent loading)

```
HISTORY, dof_history
  0.0, 0.0              % (time, value) pairs
  1.0, 0.01             % linear interpolation between points
END HISTORY
```

#### Node sets

```
NODE SET, left
  1, 4                  % node numbers in the set
NODE SET, right
  2, 3
NODE SET, node1
  3                     % single node
```

#### Element sets

```
ELEMENT SET, all_elements
  1, 2, 3, 4
```

#### Degree of freedom assignment

```
DEGREES OF FREEDOM
  left, 1, VALUE, 0.0          % fix DOF 1 on 'left' nodes to 0
  left, 2, VALUE, 0.0          % fix DOF 2
  right, 1, dof_history        % apply history to DOF 1 on 'right'
  node1, 3, VALUE, 0.0         % fix DOF 3 on a single node
END DEGREES OF FREEDOM
```

Format: `nodeset_name, dof_number, VALUE/history_name, value`

#### Distributed loads

```
DISTRIBUTED LOADS
  element_set, face_number, magnitude
END DISTRIBUTED LOADS
```

#### Constraints (tie constraints between DOFs)

```
CONSTRAINTS
  TIE, node1, dof1, node2, dof2    % simple 2-node tie
END CONSTRAINTS
```

### 3.3 Analysis Definition

#### Static analysis

```
STATIC STEP
  INITIAL TIME STEP, 1.d0
  MAX TIME STEP, 1.d0
  MIN TIME STEP, 1.d-6
  MAX NUMBER OF STEPS, 10
  MAX TOTAL TIME, 1.d0
  PRINT STEPS, 1
  STATE PRINT STEPS, 1
  USER PRINT STEPS, 100000
  USER PRINT TIME, 100000.d0

  % Solver options (uncomment ONE):
  LINEAR, DIRECT          % Linear analysis, direct solver
  % LINEAR, CONJUGATE GRADIENT
  % NONLINEAR, DIRECT, 0.0001, 15       % NR with tol=0.0001, max 15 iters
  % NONLINEAR, CONJUGATE GRADIENT, 0.0001, 15
  % NONLINEAR, DIRECT, 0.0001, 15, UNSYMMETRIC   % for unsymmetric tangent

END STATIC STEP
```

**Solver keywords**:
- `LINEAR`: single solve per step, no Newton iteration
- `NONLINEAR`: Newton-Raphson iteration with convergence check
- `DIRECT`: skyline direct solver (most robust)
- `CONJUGATE GRADIENT`: iterative CG solver (faster for large problems)
- `UNSYMMETRIC`: required if stiffness matrix is unsymmetric (e.g.,
  multi-field coupling, friction)
- Tolerance (e.g., 0.0001): convergence criterion for residual norm
- Max iterations (e.g., 15): if exceeded, time step is halved

#### Explicit dynamic analysis

```
EXPLICIT DYNAMIC STEP
  INITIAL TIME STEP, 1.d-7
  MAX TIME STEP, 1.d-7
  MIN TIME STEP, 1.d-12
  MAX NUMBER OF STEPS, 10000
  MAX TOTAL TIME, 0.001
  ...
END EXPLICIT DYNAMIC STEP
```

### 3.4 Output / Printing

```
STATE PRINT
  DEGREES OF FREEDOM
  FIELD VARIABLES, S11, S22, S33, S12, S13, S23
  DISPLACED MESH
  % ZONES, COMBINE
  %   zone1, zone2
  % END ZONES
END STATE PRINT
```

- `FIELD VARIABLES`: names are passed to user subroutine and used as
  Tecplot headers. The user code must compute and store these values.
- `DISPLACED MESH`: plots the deformed configuration
- `ZONES, COMBINE`: merges multiple element zones into one Tecplot zone

### 3.5 Stiffness / Tangent Checking

```
% Add these lines to activate checking:
CHECK STIFFNESS, U1           % U1 = user element identifier
STOP                          % stop after checking (optional)

% Or for UMAT material tangent:
CHECK MATERIAL TANGENT, steel  % material name
```

The stiffness check computes a finite-difference approximation of the
element stiffness by perturbing each DOF and comparing against the
coded stiffness matrix. Results are printed to the output file.

---

## 4. Running and Checking Output

### 4.1 Running

```bash
cd feacheap
./feacheap
./feacheap input_files/Abaqus_uel_linear_elastic_3d.in Output_Files/uel_test.out
```

### 4.2 Console Output (stdout)

The patched `staticstep.f90` prints convergence info to the console:

```
 ================================================
  feacheap: starting static analysis
  Elements:     2688
  Nodes:        3375
 ================================================
  Step     1  dt= 1.000E+00  converged in   1 iterations
  Step     2  dt= 1.000E+00  converged in   3 iterations
  Step     3  dt= 5.000E-01  NOT converged after  15 iters - cutting back
  Step     3  dt= 2.500E-01  converged in   5 iterations
 ================================================
  Static analysis complete
  Steps completed:        3
  Cutbacks:               1
  Final time:      0.2250E+01
 ================================================
 feacheap completed successfully
```

Key things to check:
- **Iteration count**: 2-3 = quadratic convergence (correct tangent);
  10+ = linear convergence (tangent error); max iters + cutback = bug
- **Cutbacks**: zero for well-posed problems with correct tangent
- **Exit code**: 0 on success, 1 on fatal failure

### 4.3 Log File (.out)

Detailed solver info: profile, bandwidth, time step adjustments,
error messages and warnings.

### 4.4 Field Output (contourplots.dat)

Results in Tecplot format. Can be viewed with Tecplot 360
(commercial), ParaView (free, requires conversion), or parsed
in Python.

---

## 5. User Element (UEL) Interface

### 5.1 Abaqus UEL Calling Convention

```fortran
SUBROUTINE UEL(RHS,AMATRX,SVARS,ENERGY,NDOFEL,NRHS,NSVARS,
     1   PROPS,NPROPS,COORDS,MCRD,NNODE,U,DU,V,A,JTYPE,TIME,DTIME,
     2   KSTEP,KINC,JELEM,PARAMS,NDLOAD,JDLTYP,ADLMAG,PREDEF,NPREDF,
     3   LFLAGS,MLVARX,DDLMAG,MDLOAD,PNEWDT,JPROPS,NJPROP,PERIOD)

      INCLUDE 'ABA_PARAM.INC'

      DIMENSION RHS(MLVARX,*),AMATRX(NDOFEL,NDOFEL),PROPS(*),
     1   SVARS(*),ENERGY(8),COORDS(MCRD,NNODE),U(NDOFEL),
     2   DU(MLVARX,*),V(NDOFEL),A(NDOFEL),TIME(2),PARAMS(*),
     3   JDLTYP(MDLOAD,*),ADLMAG(MDLOAD,*),DDLMAG(MDLOAD,*),
     4   PREDEF(2,NPREDF,NNODE),LFLAGS(*),JPROPS(*)
```

**Key outputs** (must be defined by user):
- `RHS(MLVARX,1)`: element residual (negative of internal force)
- `AMATRX(NDOFEL,NDOFEL)`: element stiffness matrix
- `SVARS(NSVARS)`: state variables (read old values, write new)
- `PNEWDT`: set < 1.0 to request time step cutback

**Key inputs**:
- `U(NDOFEL)`: total accumulated DOF values
- `DU(MLVARX,1)`: DOF increment for current step
- `COORDS(MCRD,NNODE)`: reference coordinates
- `PROPS(NPROPS)`: element properties from input file
- `JTYPE`: element identifier (from input file + 100000)
- `TIME(2)`: [step time, total time]
- `DTIME`: current time increment

### 5.2 UEL File Format

UEL files use fixed-format Fortran (`.for` extension):
- Lines start at or after column 7
- Continuation lines have a character in column 6
- Lines must not exceed column 72 (code) or 80 (with comments)

### 5.3 Using a Custom UEL

1. Place your `.for` file in `user_codes/src/`
2. The file must contain a subroutine named `UEL` with the exact
   Abaqus calling convention
3. Remove or rename any existing `UEL` subroutine in other files
   (only one `UEL` subroutine can exist in the project)
4. Recompile
5. Create an input file with `ELEMENTS, USER` and set the identifier
   to match your JTYPE - 100000

---

## 6. User Material (UMAT) Interface

### 6.1 Abaqus UMAT Calling Convention

```fortran
SUBROUTINE UMAT(STRESS,STATEV,DDSDDE,SSE,SPD,SCD,
     1   RPL,DDSDDT,DRPLDE,DRPLDT,
     2   STRAN,DSTRAN,TIME,DTIME,TEMP,DTEMP,PREDEF,DPRED,CMNAME,
     3   NDI,NSHR,NTENS,NSTATV,PROPS,NPROPS,COORDS,DROT,PNEWDT,
     4   CELENT,DFGRD0,DFGRD1,NOEL,NPT,LAYER,KSPT,JSTEP,KINC)
```

**Key outputs**:
- `STRESS(NTENS)`: updated Cauchy stress (Voigt notation)
- `DDSDDE(NTENS,NTENS)`: material tangent (Jaumann rate form)
- `STATEV(NSTATV)`: state variables

**Key inputs**:
- `STRAN(NTENS)`: total strain at start of increment
- `DSTRAN(NTENS)`: strain increment
- `DFGRD0(3,3)`: deformation gradient at start of increment
- `DFGRD1(3,3)`: deformation gradient at end of increment
- `DROT(3,3)`: rotation increment matrix
- `PROPS(NPROPS)`: material properties

### 6.2 Using a Custom UMAT

The UMAT is used with internal elements (not USER elements):

```
MATERIAL, my_material
  STATE VARIABLES, 15
  PROPERTIES
    200000.d0, 0.3d0
  END PROPERTIES
END MATERIAL

ELEMENTS, INTERNAL
  TYPE, C3D20
  MATERIAL, my_material
  CONNECTIVITY, block
    ...
  END CONNECTIVITY
END ELEMENTS
```

---

## 7. Key Source Files for Developers

### 7.1 Data Structures

The `node` type (defined in `Mesh.f90`):

```fortran
type node
    sequence
    integer :: flag           ! Integer identifier
    integer :: coord_index    ! Index of first coordinate in coord array
    integer :: n_coords       ! Total coordinates for the node
    integer :: dof_index      ! Index of first DOF in DOF array
    integer :: n_dof          ! Total DOFs for this node
end type node
```

Each node carries its own `n_dof`, supporting heterogeneous DOF
counts within a single element. This enables multi-field elements
where corner nodes have more DOFs than midside nodes.

### 7.2 Element Dispatch (solver_direct.f90)

The assembly loop in `assemble_direct_stiffness` dispatches to
different element routines based on `element_list(lmn)%flag`:

- `flag == 10002`: internal 2D continuum element (calls UMAT)
- `flag == 10003`: internal 3D continuum element (calls UMAT)
- `flag > 99999`: Abaqus UEL format (calls `SUBROUTINE UEL(...)`)
- Other: EN234 internal format (calls `user_element_static`)

The UEL dispatch packs the Abaqus-format arguments from EN234_FEA's
internal storage and calls the UEL with the exact Abaqus signature.

### 7.3 Newton-Raphson Loop (staticstep.f90)

```
compute_static_step:
  1. assemble_direct_stiffness (or CG variant)
  2. apply_direct_boundaryconditions
  3. solve_direct
  4. Newton iteration loop:
     a. assemble_direct_stiffness
     b. apply_direct_boundaryconditions
     c. convergencecheck → if converged, exit
     d. solve_direct
  5. On convergence:
     - dof_total += dof_increment
     - initial_state_variables = updated_state_variables
     - TIME += DTIME
  6. On failure:
     - DTIME = DTIME / 2
     - dof_increment = 0
     - retry
```

### 7.4 Time Step Control

- If Newton fails to converge: DTIME halved
- If PNEWDT < 1.0 from UEL/UMAT: DTIME = PNEWDT * DTIME
- If convergence fast (< max_iter/5): DTIME *= 1.25
- DTIME bounded by [timestep_min, timestep_max]

### 7.5 Element Utilities

Located in `modules/` or `user_codes/src/` (check actual location in repo):

```fortran
! Integration points and weights
call initialize_integration_points(n_points, n_nodes, xi, w)

! Shape functions and derivatives
call calculate_shapefunctions(xi, n_nodes, N, dNdxi)

! Matrix inversion (2x2 or 3x3)
call invert_small(A, A_inverse, determinant)
```

---

## 8. Common Issues and Solutions

### 8.1 Compilation Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Cannot open include file 'ABA_PARAM.INC'` | Missing Abaqus include | Create stub file (see Section 2.6) |
| `Module file not found` | Wrong compilation order | Compile modules in `modules/` before `src/` |
| `Multiple definitions of UEL` | Two files define `SUBROUTINE UEL` | Rename the unused one |
| `Line truncated` | Fixed-format line > 72 chars | Use `-ffixed-line-length-none` |
| `Unresolved reference to SUBROUTINE` | Missing object in link step | Include all `.o` files in link |

### 8.2 Runtime Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Error opening input or output file` | Wrong path in main.f90 | Set `root_directory = './'` |
| `Time step reduced to minimum` | Newton not converging | Check stiffness, reduce initial step |
| `Insufficient storage for element dof` | `length_dof_array` too small | Increase in `User_Subroutine_Storage.f90` |
| `Insufficient storage for coords` | `length_coord_array` too small | Increase in `User_Subroutine_Storage.f90` |

### 8.3 Storage Parameters

If using elements with many DOFs per element (multi-field problems),
increase the storage parameters in `modules/User_Subroutine_Storage.f90`:

```fortran
integer, parameter :: length_coord_array = 120    ! max coords per element
integer, parameter :: length_dof_array = 120       ! max DOFs per element
integer, parameter :: length_node_array = 30       ! max nodes per element
integer, parameter :: length_state_variable_array = 200  ! max SVARS per element
```

These must be large enough for your largest element. For a Quad8
element with 4 DOFs per node: `length_dof_array >= 32`.

---

## 9. Testing Workflow

### 9.1 Recommended Sequence

1. **Start with a known-good example**: Run the built-in linear
   elastic UEL (`Abaqus_uel_linear_elastic_3d.in`) to verify
   the build works.

2. **Check your element stiffness**: Add `CHECK STIFFNESS, U1`
   (with your element identifier) to the input file. The code
   perturbs each DOF by a small amount and computes a numerical
   derivative of the residual. Compare against your coded stiffness.
   Agreement to 5-7 significant figures indicates correct tangent.

3. **Check your material tangent**: Add `CHECK MATERIAL TANGENT, name`
   for UMAT testing. This perturbs each strain component and compares
   the numerical derivative of stress against your DDSDDE.

4. **Run a simple problem**: Single element with known analytical
   solution. Verify stress, displacement, and reaction forces.

5. **Run a multi-element problem**: Hole-in-a-plate or similar
   benchmark. Verify convergence and mesh independence.

### 9.2 Interpreting the Stiffness Check

The output file shows columns of stiffness entries:

```
 Row    1 Stiffness  1.23456D+05 Numerical deriv  1.23456D+05
 Row    2 Stiffness  4.56789D+04 Numerical deriv  4.56789D+04
```

- Match to 5+ digits: tangent is correct
- Match to 3-4 digits: possible small error (check stress-strain
  consistency, large deformation corrections)
- No match: bug in tangent computation

---

## 10. Quick Reference: Testing a Custom UEL in feacheap

```bash
# 1. Set up feacheap (one time)
git clone https://github.com/albower/EN234_FEA.git
cp -r EN234_FEA/EN234_FEA feacheap
cp en234fea_patch/src/main.f90       feacheap/src/main.f90
cp en234fea_patch/src/staticstep.f90 feacheap/src/staticstep.f90
cp en234fea_patch/build.sh           feacheap/build.sh
cp en234fea_patch/ABA_PARAM.INC      feacheap/ABA_PARAM.INC
cp en234fea_patch/.gitignore         feacheap/.gitignore

# 2. Place your UEL in user_codes/src/
cp /path/to/my_uel.for feacheap/user_codes/src/

# 3. Rename the existing UEL subroutine
#    (only one SUBROUTINE UEL can exist in the project)
#    Edit feacheap/user_codes/src/abaqus_uel_3d.for:
#    change "SUBROUTINE UEL" to "SUBROUTINE UEL_UNUSED"

# 4. Create your input file
cp feacheap/input_files/Abaqus_uel_linear_elastic_3d.in \
   feacheap/input_files/my_test.in
# Edit my_test.in: change element properties, BCs, etc.

# 5. Build and run
cd feacheap
bash build.sh
./feacheap input_files/my_test.in Output_Files/my_test.out

# 6. Check results
cat Output_Files/my_test.out
```
