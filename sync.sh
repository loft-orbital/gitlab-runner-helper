#!/usr/bin/env sh

set -e

git tag > local.list
tags=$(glab release list -R gitlab-org/gitlab-runner | tail -n +3 | awk '{ print $1 }' | grep -vf local.list)

archs="x86_64 arm64 arm s390x ppc64le"
flavors="alpine3.18 alpine-latest ubuntu"

for tag in $tags
do
	echo "Syncing tag $tag..."
	for flavor in $flavors
	do
	  for arch in $archs
	  do
	    arch_target=$arch
	    if [ $arch_target = "x86_64" ]; then
	      arch_target="amd64"
	    fi
	    skopeo copy --dest-creds="$:$GITHUB_TOKEN" \
	      docker://registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:$flavor-$arch-$tag \
	      docker://ghcr.io/loft-orbital/gitlab-runner-helper:$flavor-$arch_target-$tag
	  done
	 
	  echo "Reconstructing manifest for $tag..."
	  manifest-tool push from-args \
	    --platforms linux/amd64,linux/arm64,linux/arm,linux/s390x,linux/ppc64le \
	    --template ghcr.io/loft-orbital/gitlab-runner-helper:$flavor-ARCH-$tag \
	    --target ghcr.io/loft-orbital/gitlab-runner-helper:$flavor-$tag
	done
	echo "Creating release $tag..."
	gh release create $tag --generate-notes
	echo "Done."
done
