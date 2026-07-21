#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Azdal Mutation Check — Phase 4 Repeatable Artifact
# ─────────────────────────────────────────────────────────────────────────────
# Run from the project root: ./tool/mutation_check.sh
#
# Per suite: (1) perturb ONE line in the REAL service source (Python, no sed),
# (2) run flutter test on that suite — MUST FAIL (capture RED evidence),
# (3) revert via git checkout, re-run — MUST PASS.
# lib/ is net-unchanged when this script finishes.
#
# Evidence captured under test/fixtures/mutation_evidence/
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

EVIDENCE_DIR="test/fixtures/mutation_evidence"
mkdir -p "$EVIDENCE_DIR"

RED="\033[0;31m"
GREEN="\033[0;32m"
BOLD="\033[1m"
RESET="\033[0m"

PASS=0
FAIL=0

run_suite() {
  local test_path="$1"
  flutter test "$test_path" 2>&1
}

# ────────────────────────────────────────────────────────────────────────────
# SUITE 1: Integrity — re-introduce DEC-048 no_deletion_rate bug
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}═══ Suite 1: Integrity Score — DEC-048 re-introduction ═══${RESET}"
echo ""

INTEGRITY_SRC="lib/features/chat/services/integrity_score_service.dart"
INTEGRITY_TEST="test/integrity_score_service_test.dart"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Capture GREEN baseline
echo ">>> GREEN baseline (pre-perturbation)..."
run_suite "$INTEGRITY_TEST" | tail -5
echo ""

# Perturb: change `totalCount / totalEver` to `(totalCount - deletedCount) / totalCount`
# This re-introduces the DEC-048 bug: (kept-deleted)/kept can go negative
echo ">>> Perturbing: re-introducing DEC-048 bug (no_deletion_rate = (kept-deleted)/kept)..."
python3 -c "
import sys
with open('$INTEGRITY_SRC', 'r') as f:
    content = f.read()
# Replace the FIXED formula with the BUGGY one
old = 'noDeletionRate = (totalCount / totalEver * 100).clamp(0, 100);'
new = 'noDeletionRate = ((totalCount - deletedCount) / totalCount * 100).clamp(0, 100); // MUTATED: DEC-048 bug re-introduced'
if old not in content:
    print('ERROR: could not find integrity target line', file=sys.stderr)
    sys.exit(1)
content = content.replace(old, new)
with open('$INTEGRITY_SRC', 'w') as f:
    f.write(content)
print('Perturbation applied.')
"

# Run — MUST FAIL
echo ">>> RED phase (perturbed — expect FAIL)..."
RED_OUTPUT_FILE="$EVIDENCE_DIR/integrity_dec048_red_${TIMESTAMP}.txt"
set +e
run_suite "$INTEGRITY_TEST" > "$RED_OUTPUT_FILE" 2>&1
RED_EXIT=$?
set -e

if [ $RED_EXIT -ne 0 ]; then
  echo -e "${GREEN}PASS: Integrity suite went RED as expected (exit=$RED_EXIT)${RESET}"
  ((PASS++))
else
  echo -e "${RED}FAIL: Integrity suite did NOT go RED — mutation check broken!${RESET}"
  ((FAIL++))
fi
echo "RED evidence saved: $RED_OUTPUT_FILE"
tail -15 "$RED_OUTPUT_FILE"
echo ""

# Revert
echo ">>> Reverting perturbation via git checkout..."
git checkout -- "$INTEGRITY_SRC"

# Re-run — MUST PASS
echo ">>> GREEN phase (reverted — expect PASS)..."
GREEN_OUTPUT_FILE="$EVIDENCE_DIR/integrity_dec048_green_${TIMESTAMP}.txt"
set +e
run_suite "$INTEGRITY_TEST" > "$GREEN_OUTPUT_FILE" 2>&1
GREEN_EXIT=$?
set -e

if [ $GREEN_EXIT -eq 0 ]; then
  echo -e "${GREEN}PASS: Integrity suite GREEN after revert (exit=0)${RESET}"
  ((PASS++))
else
  echo -e "${RED}FAIL: Integrity suite did NOT recover after revert!${RESET}"
  ((FAIL++))
fi
echo "GREEN evidence saved: $GREEN_OUTPUT_FILE"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# SUITE 2: Purchase — weaken DTI cap to hide over-leveraged accounts
# ────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}═══ Suite 2: Purchase Decision — DTI cap weakening ═══${RESET}"
echo ""

PURCHASE_SRC="lib/features/chat/services/purchase_decision_service.dart"
PURCHASE_TEST="test/purchase_decision_service_test.dart"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Capture GREEN baseline
echo ">>> GREEN baseline (pre-perturbation)..."
run_suite "$PURCHASE_TEST" | tail -5
echo ""

# Perturb: change `if (dti > 0.33)` to `if (dti > 0.99)`
echo ">>> Perturbing: weakening DTI cap (0.33 → 0.99)..."
python3 -c "
import sys
with open('$PURCHASE_SRC', 'r') as f:
    content = f.read()
old = '    if (dti > 0.33) {'
new = '    if (dti > 0.99) { // MUTATED: DTI cap weakened from 0.33'
if old not in content:
    print('ERROR: could not find purchase target line', file=sys.stderr)
    sys.exit(1)
content = content.replace(old, new)
with open('$PURCHASE_SRC', 'w') as f:
    f.write(content)
print('Perturbation applied.')
"

# Run — MUST FAIL (DTI>33% test at :101 expects 'no' but now gets past)
echo ">>> RED phase (perturbed — expect FAIL)..."
RED_OUTPUT_FILE="$EVIDENCE_DIR/purchase_dti_red_${TIMESTAMP}.txt"
set +e
run_suite "$PURCHASE_TEST" > "$RED_OUTPUT_FILE" 2>&1
RED_EXIT=$?
set -e

if [ $RED_EXIT -ne 0 ]; then
  echo -e "${GREEN}PASS: Purchase suite went RED as expected (exit=$RED_EXIT)${RESET}"
  ((PASS++))
else
  echo -e "${RED}FAIL: Purchase suite did NOT go RED — mutation check broken!${RESET}"
  ((FAIL++))
fi
echo "RED evidence saved: $RED_OUTPUT_FILE"
tail -15 "$RED_OUTPUT_FILE"
echo ""

# Revert
echo ">>> Reverting perturbation via git checkout..."
git checkout -- "$PURCHASE_SRC"

# Re-run — MUST PASS
echo ">>> GREEN phase (reverted — expect PASS)..."
GREEN_OUTPUT_FILE="$EVIDENCE_DIR/purchase_dti_green_${TIMESTAMP}.txt"
set +e
run_suite "$PURCHASE_TEST" > "$GREEN_OUTPUT_FILE" 2>&1
GREEN_EXIT=$?
set -e

if [ $GREEN_EXIT -eq 0 ]; then
  echo -e "${GREEN}PASS: Purchase suite GREEN after revert (exit=0)${RESET}"
  ((PASS++))
else
  echo -e "${RED}FAIL: Purchase suite did NOT recover after revert!${RESET}"
  ((FAIL++))
fi
echo "GREEN evidence saved: $GREEN_OUTPUT_FILE"
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Final report
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}═══════════════════════════════════════════${RESET}"
echo -e "${BOLD}  MUTATION CHECK SUMMARY${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════${RESET}"
echo -e "  PASS: ${GREEN}${PASS}${RESET} / 4"
echo -e "  FAIL: ${RED}${FAIL}${RESET} / 4"
echo ""
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  ALL MUTATION CHECKS PASSED${RESET}"
  echo "  Both suites correctly detect perturbed source and recover after revert."
else
  echo -e "${RED}${BOLD}  SOME MUTATION CHECKS FAILED${RESET}"
  exit 1
fi
echo ""
echo "Evidence directory: $EVIDENCE_DIR"
echo "lib/ is net-unchanged (all perturbations reverted via git checkout)."
