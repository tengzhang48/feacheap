#!/bin/bash
# ============================================================
# build.sh ? Build FEACHEAP with gfortran
#
# Handles Fortran module dependencies automatically via
# multi-pass compilation: files are compiled repeatedly until
# all succeed or no further progress is made.
#
# Usage:
#   cd /feacheap
#   bash build.sh [debug|release]
#
# Default is release (-O2). Debug mode adds bounds checking.
# ============================================================

set -e

# --- Configuration ---
FC="gfortran"
TARGET="feacheap"
MODDIR="compiled_mods"    # directory for .mod files

if [ "$1" = "debug" ]; then
    FFLAGS="-O0 -g -fcheck=all -fbacktrace -Wall"
    echo "=== Building feacheap (DEBUG) ==="
else
    FFLAGS="-O2"
    echo "=== Building feacheap (RELEASE) ==="
fi

FFLAGS_FREE="$FFLAGS -ffree-form -J$MODDIR -I$MODDIR -I."
FFLAGS_FIXED="$FFLAGS -ffixed-form -ffixed-line-length-none -J$MODDIR -I$MODDIR -I."

# --- Create directories ---
mkdir -p "$MODDIR"
mkdir -p Output_Files
mkdir -p Output_files    # some input files may use lowercase

# --- Create ABA_PARAM.INC if missing ---
if [ ! -f ABA_PARAM.INC ]; then
    echo "Creating ABA_PARAM.INC stub..."
    cat > ABA_PARAM.INC << 'ENDOFABA'
C     ABA_PARAM.INC - Abaqus parameter include file
C     Stub for use with EN234_FEA / gfortran
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (NPRECD=2)
ENDOFABA
fi

# --- Clean old objects ---
echo "Cleaning old build artifacts..."
rm -f *.o "$MODDIR"/*.mod "$TARGET" 2>/dev/null || true

# --- Collect source files ---
# Modules first (both top-level and user_codes/modules), then user codes, then src (main.f90 last)
MOD_FILES=$(find modules/ -name '*.f90' 2>/dev/null | sort)
USR_MOD_FILES=$(find user_codes/modules/ -name '*.f90' 2>/dev/null | sort)
USR_F90=$(find user_codes/src/ -name '*.f90' 2>/dev/null | sort)
USR_FOR=$(find user_codes/src/ -name '*.for' 2>/dev/null | sort)
SRC_FILES=$(find src/ -name '*.f90' ! -name 'main.f90' 2>/dev/null | sort)
MAIN_FILE="src/main.f90"

# Verify main.f90 exists
if [ ! -f "$MAIN_FILE" ]; then
    echo "ERROR: $MAIN_FILE not found. Are you in EN234_FEA/EN234_FEA/ ?"
    exit 1
fi

# ============================================================
# Multi-pass compilation function
#
# Tries to compile each file in the list. Files that fail
# (typically due to missing .mod) are retried in the next pass.
# Stops when all files compile or no progress is made.
# ============================================================
compile_multipass() {
    local label="$1"
    local flags="$2"
    shift 2
    local files=("$@")

    if [ ${#files[@]} -eq 0 ]; then
        return 0
    fi

    echo ""
    echo "--- Compiling $label (${#files[@]} files) ---"

    local remaining=("${files[@]}")
    local pass=0
    local max_passes=20

    while [ ${#remaining[@]} -gt 0 ] && [ $pass -lt $max_passes ]; do
        pass=$((pass + 1))
        local failed=()
        local compiled=0

        for f in "${remaining[@]}"; do
            local base=$(basename "$f" .f90)
            base=$(basename "$base" .for)
            local obj="${base}.o"

            if $FC $flags -c "$f" -o "$obj" 2>/dev/null; then
                compiled=$((compiled + 1))
            else
                failed+=("$f")
            fi
        done

        echo "  Pass $pass: ${compiled} compiled, ${#failed[@]} remaining"

        # No progress ? show actual errors and exit
        if [ $compiled -eq 0 ] && [ ${#failed[@]} -gt 0 ]; then
            echo ""
            echo "ERROR: No progress in pass $pass. Showing errors:"
            echo ""
            for f in "${failed[@]}"; do
                echo "=== $f ==="
                $FC $flags -c "$f" 2>&1 | head -20
                echo ""
            done
            exit 1
        fi

        remaining=("${failed[@]}")
    done

    if [ ${#remaining[@]} -gt 0 ]; then
        echo "ERROR: Could not compile all files after $max_passes passes."
        echo "Remaining: ${remaining[*]}"
        exit 1
    fi
}

# ============================================================
# Build phases
# ============================================================

# Phase 1: Top-level modules (these define the .mod files other code needs)
compile_multipass "modules" "$FFLAGS_FREE" $MOD_FILES

# Phase 1b: User modules (e.g., Element_Utilities)
compile_multipass "user_codes/modules" "$FFLAGS_FREE" $USR_MOD_FILES

# Phase 2: User codes ? fixed-format .for files
compile_multipass "user codes (.for)" "$FFLAGS_FIXED" $USR_FOR

# Phase 3: User codes ? free-format .f90 files
compile_multipass "user codes (.f90)" "$FFLAGS_FREE" $USR_F90

# Phase 4: Solver source files (excluding main.f90)
compile_multipass "solver source" "$FFLAGS_FREE" $SRC_FILES

# Phase 5: main.f90 (always last ? depends on everything)
echo ""
echo "--- Compiling main.f90 ---"
$FC $FFLAGS_FREE -c "$MAIN_FILE" -o main.o
echo "  OK"

# Phase 6: Link
echo ""
echo "--- Linking ---"
OBJ_FILES=$(ls *.o 2>/dev/null)
$FC $FFLAGS -o "$TARGET" $OBJ_FILES
echo "  Built: $TARGET"

# --- Summary ---
echo ""
echo "============================================"
echo "  BUILD SUCCESSFUL"
echo "  Executable: ./$TARGET"
echo "  Object files: $(ls *.o | wc -l)"
echo "  Module files: $(ls $MODDIR/*.mod 2>/dev/null | wc -l)"
echo "============================================"
echo ""
echo "To run:"
echo "  ./$TARGET"
echo "  ./$TARGET input_files/your_input.in Output_Files/your_output.out"
echo ""
echo "Default input file is set in src/main.f90."
