#!/usr/bin/env bash
set -euo pipefail

# Lambda 함수 디렉토리 내 requirements.txt를 자동 설치해 패키징 용이화
# 사용법
#   ./build.sh              # 모든 함수 빌드
#   ./build.sh iot-to-cache # 특정 함수만 빌드
#   RUNTIME_PY=python3.11 ./build.sh  # 사용할 파이썬 지정

cd "$(dirname "$0")"

RUNTIME_PY=${RUNTIME_PY:-python3.11}
if ! command -v "$RUNTIME_PY" >/dev/null 2>&1; then
  echo "[!] $RUNTIME_PY not found. Falling back to python3"
  RUNTIME_PY=python3
fi

PIP="$RUNTIME_PY -m pip"

build_one() {
  local fn_dir="$1"
  local path="functions/$fn_dir"
  if [ ! -d "$path" ]; then
    echo "[!] function directory not found: $path" >&2
    return 1
  fi

  echo "=== Building: $fn_dir ==="
  if [ -f "$path/requirements.txt" ]; then
    echo "-> Installing deps into $path"
    $PIP install --upgrade pip >/dev/null
    $PIP install -r "$path/requirements.txt" -t "$path" --no-cache-dir
  else
    echo "-> No requirements.txt; skip deps"
  fi

  # 정리(선택): 불필요한 캐시/테스트 파일 제거
  find "$path" -type d -name "__pycache__" -prune -exec rm -rf {} + || true
  find "$path" -type f -name "*.pyc" -delete || true

  echo "=== Done: $fn_dir ==="
}

if [ $# -gt 0 ]; then
  build_one "$1"
else
  for d in functions/*; do
    [ -d "$d" ] || continue
    build_one "$(basename "$d")"
  done
fi

echo "\nBuild complete. Now run:"
echo "  (cd .. && terraform apply)"