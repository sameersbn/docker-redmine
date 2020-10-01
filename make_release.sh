#!/bin/bash

set -e
set -x

git add -p
git commit -sS -m "release: $(cat VERSION)"
git tag -s $(cat VERSION) -m "$(cat VERSION)"
git push
git push origin --tags
