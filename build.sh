#!/bin/sh
# build.sh: build SAW
# usage: ./build.sh [target]
#
# Valid targets are:
#    build (the default)
#    gitrev (included in build, needed before building)
#    submodules (included in build, at least for now)
#    clean
#
# Setting environment variable SAW_SUPPRESS_GITREV suppresses updating
# GitRev.hs. See savegitinfo.sh.

set -e

##############################
# gitrev

tgt_gitrev() {
    # fetch/update the compiled-in git version info
    saw-version/src/SAWVersion/savegitinfo.sh
}

##############################
# submodules

tgt_submodules() {
    echo "git submodule update --init"
    git submodule update --init
}

##############################
# build

install() {
  PROG=$(cabal list-bin -v0 exe:$1)
  echo "cp $PROG bin/"
  cp $PROG bin/
}

tgt_build() {
    tgt_gitrev
    tgt_submodules

    # Keep the list of tests in sync. There are four lists of tests:
    #   - here
    #   - .github/workflows/ci.yml
    #   - doc/developer/developer.md
    #   - and of course the definitions in the *.cabal files

    echo "cabal build ..."
    cabal build exe:cryptol exe:saw exe:saw-remote-api \
                exe:crux-mir-comp exe:extcore-info exe:verif-viewer \
                test-suite:integration-tests test-suite:saw-core-tests \
                test-suite:cryptol-saw-core-tests \
                test-suite:saw-core-coq-tests \
                test-suite:heapster-prover-tests

    echo "rm -rf bin && mkdir bin"
    rm -rf bin && mkdir bin

    install cryptol
    install saw
    install saw-remote-api
    install crux-mir-comp
    install extcore-info
    install verif-viewer

    echo
    echo "COPIED EXECUTABLES TO `pwd`/bin."
}

##############################
# clean

tgt_clean() {
    echo "cabal clean"
    cabal clean
    if [ -d bin ]; then
        echo "rm -rf bin"
        rm -rf bin
    fi
}

##############################
# top level

case "X$1" in
    Xgitrev) tgt_gitrev;;
    Xsubmodules) tgt_submodules;;
    X|Xbuild) tgt_build;;
    Xclean) tgt_clean;;
    *)
        echo "$0: Don't know how to build $1" 1>&2
        exit 1
        ;;
esac
exit 0
