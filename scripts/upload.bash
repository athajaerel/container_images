#!/bin/bash
set -euo pipefail

# $1 = upload var (y)
# $2 = remote
# $3 = image
# $4 = tag

tag_date=$(<<<$4 cut -dT -f1)

if [ "x$1" == "xy" ]; then
	buildah login $2
	buildah push $3:latest
	buildah push $3:${tag_date}
	buildah push $3:$4
fi
