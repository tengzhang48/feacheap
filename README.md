# feacheap

A lightweight, open-source finite element solver for developing and testing
Abaqus-compatible user subroutines (UEL, UMAT, VUEL, VUMAT) — without an
Abaqus license.

Code that works in feacheap runs in Abaqus without modification.

## History

feacheap was originally developed as **EN234_FEA** by
[Prof. Allan Bower](https://solidmechanics.org/)
at Brown University for the graduate course EN234: Computational Methods in
Structural and Solid Mechanics. Prof. Bower nicknamed the code "feacheap"
(FEA, cheap) — a finite element solver that doesn't need an expensive license.

This fork adds Linux/gfortran build support and minor quality-of-life
improvements. All solver code is unchanged from Prof. Bower's original.

**Original repository**: https://github.com/albower/EN234_FEA

## Capabilities

- Static linear and nonlinear analysis (Newton-Raphson with adaptive time stepping)
- Explicit dynamic analysis
- Abaqus UEL and UMAT subroutine interface (exact calling convention)
- Built-in stiffness and material tangent checking (finite difference verification)
- Direct (skyline) and conjugate gradient solvers
- Heterogeneous DOF counts per node (for multi-field elements)
- State variable persistence and PNEWDT time step control

## Quick Start

```bash
# Clone
git clone https://github.com/tengzhang48/feacheap.git
cd feacheap

# Build
bash build.sh

# Run (default: 3D linear elastic UEL)
./feacheap

# Run with a specific input file
./feacheap input_files/Abaqus_umat_linear_elastic_3d.in Output_Files/umat_test.out
```

### What You Should See

```
 ================================================
  feacheap: starting static analysis
  Elements:        2
  Nodes:          12
 ================================================
  Step     1  dt= 0.100E+01  converged in   3 iterations
  Step     2  dt= 0.100E+01  converged in   2 iterations
  Step     3  dt= 0.100E+01  converged in   2 iterations
 ================================================
  Static analysis complete
  Steps completed:        3
  Cutbacks:               0
  Final time:        0.3000E+01
 ================================================
  feacheap completed successfully
```

## Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get install gfortran

# macOS
brew install gcc
```

## Repository Structure

```
feacheap/
│
├── src/                          # Solver source code
│   ├── main.f90                  #   Entry point (accepts command-line args)
│   ├── staticstep.f90            #   Newton-Raphson solver loop
│   ├── solver_direct.f90         #   Global assembly + skyline direct solver
│   ├── solver_conjugate_gradient.f90  #   CG solver
│   ├── continuum_elements.f90    #   Built-in element library (CPE4, C3D8, etc.)
│   ├── checkstiffness.f90        #   FD check of element stiffness vs residual
│   ├── checktangent.f90          #   FD check of UMAT tangent vs stress
│   ├── read_input_file.f90       #   Input file parser
│   ├── printing.f90              #   Tecplot output
│   └── ...
│
├── modules/                      # Fortran modules (data structures)
│   ├── Types.f90                 #   Precision (real*8)
│   ├── Globals.f90               #   TIME, DTIME, global state
│   ├── Mesh.f90                  #   Node/element data structures
│   ├── Stiffness.f90             #   Stiffness storage (skyline format)
│   ├── Staticstepparameters.f90  #   Newton solver settings
│   ├── User_Subroutine_Storage.f90  #   Max DOF/SVARS per element
│   └── ...
│
├── user_codes/                   # --- YOU EDIT FILES HERE ---
│   ├── src/                      #   User subroutines
│   │   ├── abaqus_uel_3d.for    #     Example: 3D linear elastic UEL
│   │   ├── abaqus_umat_elastic.for  # Example: linear elastic UMAT
│   │   ├── abaqus_vuel.for      #     Example: VUEL (explicit dynamic)
│   │   ├── abaqus_vumat.for     #     Example: VUMAT (explicit dynamic)
│   │   └── ...
│   └── modules/                  #   Shared utilities for user codes
│       └── Element_Utilities.f90 #     Shape functions, integration, invert_small
│
├── input_files/                  # Example input files
│   ├── Abaqus_uel_linear_elastic_3d.in     # 3D UEL demo (2 elements)
│   ├── Abaqus_umat_linear_elastic_3d.in    # 3D UMAT demo (2 elements)
│   ├── Abaqus_uel_holeplate_3d.in          # Hole-in-a-plate (large mesh)
│   └── ...                                  # Homework problems
│
├── Output_Files/                 # Results written here
├── build.sh                      # Build script (handles dependencies)
├── ABA_PARAM.INC                 # Abaqus include stub for gfortran
├── FEACHEAP_GUIDE.md             # Full documentation
└── README.md                     # This file
```

## How It Works

feacheap mimics Abaqus's element/material dispatch. The solver loops over
elements and calls user subroutines by name:

- Elements with identifier > 99999 → calls `SUBROUTINE UEL(...)` (your code)
- Internal elements with a material → calls `SUBROUTINE UMAT(...)` (your code)
- Explicit dynamic variants → calls `VUEL(...)` or `VUMAT(...)`

You write a standard Abaqus UEL or UMAT in a `.for` file, place it in
`user_codes/src/`, rebuild, and run. **Only one subroutine named `UEL` (or `UMAT`)
can exist in the project** — rename any others before building.

## Using Your Own UEL or UMAT

```bash
# 1. Place your subroutine file
cp my_material.for user_codes/src/

# 2. Rename the existing subroutine to avoid conflicts
#    In user_codes/src/abaqus_uel_3d.for, change:
#      SUBROUTINE UEL(...)  →  SUBROUTINE UEL_UNUSED(...)

# 3. Rebuild
bash build.sh

# 4. Run with your input file
./feacheap input_files/my_test.in Output_Files/my_test.out
```

## Verifying Your Code

feacheap can check that your stiffness matrix is consistent with your
residual vector using finite differences. Add this to your input file:

```
CHECK STIFFNESS, U1
STOP
```

For UMAT tangent checking:

```
CHECK MATERIAL TANGENT, my_material
```

The coded and numerical values are printed to the output file. They
should agree to 5-7 significant figures.

## Differences from Original EN234_FEA

| Change | Why |
|--------|-----|
| `program feacheap` (was `en234fea`) | Real name |
| Command-line input/output file arguments | No recompile to switch inputs |
| `root_directory = './'` | Works on Linux out of the box |
| `IOPSYS = 0` | Linux path commands (`mv` not `move`) |
| Forward slashes in input files | Linux path separator |
| Convergence output to stdout | See iteration counts immediately |
| `error stop 1` on fatal failure | Nonzero exit code for scripting |
| `build.sh` with multi-pass compilation | One command build, handles module dependencies |
| `ABA_PARAM.INC` stub | gfortran compilation without Abaqus |

All solver algorithms, element dispatch, Newton-Raphson iteration,
stiffness checking, and output formats are **unchanged**.

## Full Documentation

See [FEACHEAP_GUIDE.md](FEACHEAP_GUIDE.md) for:
- Input file format (nodes, elements, materials, BCs, analysis)
- UEL and UMAT interface specifications
- Key data structures for developers
- Common issues and solutions
- Testing workflow

## Acknowledgments

feacheap is built entirely on [Prof. Allan Bower](https://vivo.brown.edu/display/albower)'s
EN234_FEA code. All solver design, element infrastructure, and Abaqus
interface compatibility are his work.

## License

See the original [EN234_FEA repository](https://github.com/albower/EN234_FEA)
for licensing terms.
