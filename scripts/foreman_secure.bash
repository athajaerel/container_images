#!/bin/bash
set -euo pipefail

find / -perm /6000 \
	-type f    \
	-exec chmod a-s {} \; 2>/dev/null || true
