#!/bin/bash
set -euo pipefail

# $1 = upload var (y)
# $2 = remote
# $3 = image
# $4 = tag_date
# $5 = tag

if [ "x$1" == "xy" ]; then
	buildah login $2
	buildah push $3:latest
	buildah push $3:$4
	buildah push $3:$5
fi
