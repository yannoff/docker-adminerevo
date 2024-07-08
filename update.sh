#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
    echo "Usage: $0 <full-version>"
    exit 1
fi
versions=( "${versions[@]%/}" )

for fullVersion in "${versions[@]}"; do
    version=$(echo $fullVersion | awk -F "." '{ printf "%s", $1 }')
    commit=$(git ls-remote --tags https://github.com/adminerevo/adminerevo.git | awk -v "prefix=refs/tags/v" -v "tag=${fullVersion}" '($2 ~ prefix "" tag) { printf "%s", $1;  }') 
    echo "commit: $commit"
	downloadSha256="$(
		curl -fsSL "https://github.com/adminerevo/adminerevo/releases/download/v${fullVersion}/adminer-${fullVersion}.php" \
			| sha256sum \
			| cut -d' ' -f1
	)"
	echo "Version: $version - adminer-${fullVersion}.php: $downloadSha256"

	sed -ri \
		-e 's/^(ENV\s+ADMINER_VERSION\s+).*/\1'"$fullVersion"'/' \
		-e 's/^(ENV\s+ADMINER_DOWNLOAD_SHA256\s+).*/\1'"$downloadSha256"'/' \
		-e 's/^(ENV\s+ADMINER_COMMIT\s+).*/\1'"$commit"'/' \
		"$version/fastcgi/Dockerfile" \
		"$version/Dockerfile"
done
