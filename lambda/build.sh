#!/usr/bin/env bash
set -euo pipefail

# Lambda 함수 디렉토리 내 requirements.txt를 자동 설치해 패키징 용이화
# 사용법
#   ./build.sh              # 모든 함수 빌드
#   ./build.sh iot-to-cache # 특정 함수만 빌드
#   RUNTIME_PY=python3.11 ./build.sh  # 사용할 파이썬 지정

cd "$(dirname "$0")"

# pyenv 초기화
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  
  # .python-version 파일이 있으면 그 버전 사용, 없으면 가장 최신 버전 자동 선택
  if [ -f ".python-version" ]; then
    RUNTIME_PY=$(cat .python-version)
    echo "[*] Using Python version from .python-version: $RUNTIME_PY"
  else
    # 설치된 Python 중 가장 최신 3.x 버전 찾기
    RUNTIME_PY=$(pyenv versions --bare | grep '^3\.' | sort -V | tail -1)
    if [ -z "$RUNTIME_PY" ]; then
      echo "[!] No Python 3.x version found in pyenv. Using system python3"
      RUNTIME_PY=python3
    else
      echo "[*] Using latest installed Python version: $RUNTIME_PY"
      pyenv shell "$RUNTIME_PY"
    fi
  fi
else
  # pyenv가 설치되어 있지 않으면 환경변수 또는 기본값 사용
  RUNTIME_PY=${RUNTIME_PY:-python3.11}
  echo "[*] pyenv not found. Using: $RUNTIME_PY"
fi

# 최종 확인
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