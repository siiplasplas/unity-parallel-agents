#!/usr/bin/env bash
# Check one agent's worktree headless: EditMode tests, PlayMode tests and a player build.
# A job is done when this passes, not when the agent says so.
#
# Usage:  UNITY="/path/to/Unity" scripts/unity-check.sh <unity-project-path> [editmode|playmode|build|all]
#   UNITY must be the editor version the project uses.
#   The project must not be open in an editor at the same time (Unity locks the folder).
#   "build" needs AgentBuild.cs in the project's Assets/Editor/ folder (see unity/Assets/Editor).
#
# Exit code: 0 = everything passed, 1 = something failed. Logs and results: <project>/Logs/agent-check/
set -uo pipefail

: "${UNITY:?Set UNITY to the Unity editor executable}"
proj="$(cd "${1:?usage: unity-check.sh <unity-project-path> [editmode|playmode|build|all]}" && pwd)"
what="${2:-all}"
out="$proj/Logs/agent-check"
mkdir -p "$out"
failed=0

tests() {
  local platform="$1"
  echo "== $platform tests"
  "$UNITY" -batchmode -projectPath "$proj" -runTests -testPlatform "$platform" \
    -testResults "$out/$platform-results.xml" -logFile "$out/$platform.log"
  case $? in
    0) echo "   passed" ;;
    2) echo "   FAILED: some tests failed, see $out/$platform-results.xml"; failed=1 ;;
    *) echo "   ERROR: tests did not run, see $out/$platform.log"; failed=1 ;;
  esac
}

build() {
  echo "== player build"
  if "$UNITY" -batchmode -quit -projectPath "$proj" -executeMethod AgentBuild.Build \
       -buildPath "$out/build" -logFile "$out/build.log"; then
    echo "   passed"
  else
    echo "   FAILED: see $out/build.log"; failed=1
  fi
}

case "$what" in
  editmode) tests EditMode ;;
  playmode) tests PlayMode ;;
  build)    build ;;
  all)      tests EditMode; tests PlayMode; build ;;
  *) echo "unknown check: $what"; exit 2 ;;
esac

exit $failed
