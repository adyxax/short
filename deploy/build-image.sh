#!/usr/bin/env bash
set -eu

ret=0; output=$(buildah images adyxax/alpine &>/dev/null) || ret=$?
if [ $ret != 0 ]; then
	ALPINE_LATEST=$(curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/ |
		perl -lane '$latest = $1 if $_ =~ /^<a href="(alpine-minirootfs-\d+\.\d+\.\d+-x86_64\.tar\.gz)">/; END {print $latest}'
	)
	if [ ! -e "./${ALPINE_LATEST}" ]; then
		echo "Fetching ${ALPINE_LATEST}..."
		curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/${ALPINE_LATEST} \
			--output ./${ALPINE_LATEST}
	fi

	ctr=$(buildah from scratch)
	buildah add $ctr ${ALPINE_LATEST} /
	buildah run $ctr /bin/sh -c 'apk add --no-cache pcre sqlite-libs'
	buildah commit $ctr adyxax/alpine
else
	ctr=$(buildah from adyxax/alpine)
	#buildah run $ctr /bin/sh -c 'apk upgrade --no-cache'
fi

ret=0; buildah images adyxax/nim &>/dev/null || ret=$?
if [ $ret != 0 ]; then
	nim=$(buildah from adyxax/alpine)
	# Alpine edge is necessary to get a nim package for now
	buildah add $nim repositories /etc/apk/
	buildah run $nim /bin/sh -c 'apk upgrade --no-cache'
	buildah run $nim /bin/sh -c 'apk add --no-cache nim nimble git pcre sqlite gcc musl-dev'
	buildah config --workingdir /code $nim
	buildah commit $nim adyxax/nim
else
	nim=$(buildah from adyxax/nim)
	#buildah run $nim /bin/sh -c 'apk upgrade --no-cache'
fi

buildah copy $nim .././ /code
buildah config --workingdir /code $nim
buildah run $nim nimble build
buildah copy --from $nim $ctr /code/short ./

### Committing the nim work environment ###
buildah config --workingdir / $nim
buildah run $nim rm -rf /code
buildah commit $nim adyxax/nim
buildah rm $nim

### Finishing ###
buildah config \
	--author 'Julien Dessaux' \
	--cmd /short \
	--port 5000 \
	$ctr

buildah commit $ctr adyxax/short
buildah rm $ctr
