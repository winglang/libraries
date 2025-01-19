#!/bin/bash
set -euo pipefail

scriptdir=$(cd $(dirname $0) && pwd)

entrypoint=${1:-}

if [ -z "$entrypoint" ]; then
  echo "Usage: $0 <entrypoint>"
  exit 1
fi

basename=$(basename $entrypoint .w)
dirname=$(dirname $entrypoint)
echo $dirname

wing compile -t $scriptdir/lib/index.js $entrypoint

cd $dirname/target/${basename}.pulumi
pulumi up
