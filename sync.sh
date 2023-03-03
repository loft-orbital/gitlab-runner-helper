#!/usr/bin/env sh

set -e

git tag > local.list
tags=$(glab release list -R gitlab-org/gitlab-runner | tail -n +3 | awk '{ print $1 }' | grep -vf local.list)

for tag in $tags
do
  manifest-tool push from args \
    --platforms linux/x86_64,linux/arm64,linux/arm,linux/s390x,linux/ppc64le \
    --template registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:alpine-latest-ARCH-$(version):$tag \
    --target ghcr.io/loft-orbital/gitlab-runner-helper:$tag
  gh release create $tag --generate-notes
done

