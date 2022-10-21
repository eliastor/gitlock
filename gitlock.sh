#!/bin/bash

function tagtrylock() {
    TAG="$1"
    OPERATION="$2"
    git fetch origin --prune --tags '+refs/tags/lock-*:refs/tags/lock-*'

    # check if lock already exists.

    git tag -a -m "user $(git config user.name)" -m "host   $(hostname -s)" -m "stime  $(date +%Y-%d-%m-%H%M%S)" -m "op $OPERATION"  $TAG
    git push origin $TAG >/dev/nul
    git fetch origin --prune --tags '+refs/tags/lock-*:refs/tags/lock-*'
}

function showlock() {
    TAG="$1"
    git tag -l --format='%0auser: %(taggername)%0a%0a%(body)' $TAG
}

function check() {
    TAG="$1"

    LOCALTAGTIME="$(git tag -l --format='%(taggerdate:unix)' $TAG)"

    # %(taggername)

    ALLTAGLINES="$(git tag -l --format='%(taggerdate:unix) %(tag)')"

    # add check of local tag existence
   
    if [[ "$ALLTAGLINES" != *"$TAG"* ]]; then
        return -3 # sync of upstream is errored
    fi

    TAGLINES="$(git tag -l --format='%(taggerdate:unix) %(tag)' | grep -v $TAG)"

    echo "${TAGLINES}" | while IFS= read -r TAGLINE; do
        if [[ "$TAGLINE" == "" ]]; then
            continue
        fi
        TAGTIME="$(echo $TAGLINE | cut -d " " -f1)"
        TAGNAME="$(echo $TAGLINE | cut -d " " -f2)"

        if (( "$TAGTIME" < "$LOCALTAGTIME" )); then
            return 1 #  this lock attempt is not successful
        elif (( "$TAGTIME" == "$LOCALTAGTIME" )); then
            if [[ "$TAG" < "$TAGNAME" ]]; then
                echo "Locked:"
                showlock $TAGNAME
                return 1 #  this lock attempt is not successful
            elif  [[ "$TAG" > "$TAGNAME" ]]; then
                continue # this lock attempt is successful
            else 
                return -1 # it's almost impossible to get same time and lock name
            fi
        else 
            continue
        fi
    done
    return $?
}

function clean()  {
    TAG="$1"
    git push origin --delete $TAG
    git fetch origin --prune --tags '+refs/tags/lock-*:refs/tags/lock-*'
}

function cycle() {
    TAG="$1"
    OPERATION="$2"
    tagtrylock "$TAG" "$OPERATION" && \
    check "$TAG"
    RESULT="$?"
    case "$RESULT" in
        0)  
            echo "Locked"
            return 0
        ;;
        1)
            echo "Waiting for unlock"
            clean "$TAG"
            return 1
        ;;
        *)
            echo "error:" "$RESULT"
            clean "$TAG"
            exit "$RESULT"
            return "$RESULT"
        ;;
    esac
    return $?
}

function lockloop() {
    OPERATION="$1"

    while true; do # in fact there must be timeout or number of tries limit
        TAG="lock-$(uuid -v4)"

        cycle "$TAG" "$OPERATION"
        RESULT="$?"
        
        case "$RESULT" in
        0)  
            return 0
        ;;
        1)
            sleep 5
        ;;
        *)
            echo "error:" "$RESULT"
            clean "$TAG"
            exit "$RESULT"
        ;;
        esac

    done

    return $?
}

function _usage() {
    echo "USAGE"
}

export OPERATION="lock"

while [ "$1" != "" ]; do
    case $1 in
      -h | --help)
        _usage
        exit
        ;;
      -o | --operation)
        export OPERATION="$1"
        ;;
      * )
        break
        ;;
    esac
    shift
done

lockloop "$OPERATION"

echo $TAG

$@

clean "$TAG"

exit $?