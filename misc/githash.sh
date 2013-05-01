#!/bin/sh

# based on require_clean_work_tree from git dist
is_clean_work_tree() {
    # Update the index, fails if in rebase etc
    if ! git update-index -q --ignore-submodules --refresh > /dev/null ; then
        return 1
    fi

    # Disallow unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules -- ; then
        return 1
    fi

    # Disallow uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules -- ; then
        return 1
    fi

    return 0
}

head_hash_string() {
    SUFFIX="-dirty"
    if is_clean_work_tree ; then
        SUFFIX=""
    fi

    HASH=`git rev-parse HEAD`

    echo "$HASH$SUFFIX"
}

echo "#define GIT_HASH \"`head_hash_string`\""

