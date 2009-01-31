#!/bin/sh

# strip svk and git-svn noise, retaining tags
git filter-branch --tag-name-filter cat --msg-filter "perl -ne 'print qq{Merge\\n} and exit if \$. == 1 and /^\\s*r\\d+\\@.*\\(orig r\\d+\\):/; next if /^git-svn-id:/; \$s++, next if /^\\s*r\\d+\\@.*:.*\\|/; s/^ // if \$s; print'" -- --all

# remove the backup refs
git for-each-ref --format='%(refname)' refs/original/ | while read ref; do
    git update-ref -d "$ref"
done

git gc

# remove merged branches
git for-each-ref --format='%(refname)' refs/heads | while read branch; do
    git rev-parse --quiet --verify "$branch" || continue # make sure it still exists
    git symbolic-ref HEAD "$branch"
    git branch -d $( git branch --merged | grep -v '^\*' )
done

git checkout master

# ditch all pre-conversion objects forcefully
git reflog expire --all --expire=now
git gc --aggressive

git prune
git fsck --full
