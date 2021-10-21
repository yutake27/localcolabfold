#!/bin/bash

# Setup for localcolabfold
# Add colabfold and alphafold as submodules to the parent directory of this directory.

ALPHAFOLD_GIT_REPO="https://github.com/yutake27/alphafold" # repository forked from official alphafold
COLABFOLD_GIT_REPO="https://github.com/yutake27/ColabFold" # repository forked from colabfold
SOURCE_URL="https://storage.googleapis.com/alphafold/alphafold_params_2021-07-14.tar"
ALPHAFOLD_INSTALL_DIR="$(dirname $(pwd))"
COLABFOLD_INSTALL_DIR="$(dirname $(pwd))"
LOCALCOLABFOLD_DIR=`pwd`
ALPHAFOLD_INSTALL_NAME="alphafold"
COLABFOLD_INSTALL_NAME="colabfold"
ALPHAFOLD_DIR="${ALPHAFOLD_INSTALL_DIR}/${ALPHAFOLD_INSTALL_NAME}"
COLABFOLD_DIR="${COLABFOLD_INSTALL_DIR}/${COLABFOLD_INSTALL_NAME}"
PARAMS_DIR="${ALPHAFOLD_DIR}/alphafold/data/params"

# Add colabfold as a submodule in "${COLABFOLD_DIR}"
if [ ! -d ${COLABFOLD_DIR} ]; then
    echo "Add ColabFold as a submodule in ${COLABFOLD_DIR}..."
    pushd ${COLABFOLD_INSTALL_DIR}
    git submodule add ${COLABFOLD_GIT_REPO} ${COLABFOLD_INSTALL_NAME}
    (cd ${COLABFOLD_DIR} && git checkout 9546d8fbbf77a0d59c9b234486e6e6e1c7765dd4 --quiet && git checkout -b local)
    popd
fi

# Add original alphafold as a submodule in "${ALPHAFOLD_DIR}"
if [ ! -d ${ALPHAFOLD_DIR} ]; then
    echo Add original alphafold as a submodule in "${ALPHAFOLD_DIR}"
    pushd ${ALPHAFOLD_INSTALL_DIR}
    git submodule add ${ALPHAFOLD_GIT_REPO} ${ALPHAFOLD_INSTALL_NAME}
    (cd ${ALPHAFOLD_DIR} && git checkout 1d43aaff941c84dc56311076b58795797e49107b --quiet && git checkout -b colabfold)
    popd
fi

# colabfold patches
echo "Applying several patches to Alphafold..."
pushd ${ALPHAFOLD_DIR}
# copy colabfold.py and colabfold_alphafold.py from ColabFold
cp ${COLABFOLD_DIR}/beta/colabfold.py .
cp ${COLABFOLD_DIR}/beta/colabfold_alphafold.py .
cp ${COLABFOLD_DIR}/beta/pairmsa.py .
# donwload reformat.pl from hh-suite
wget -qnc https://raw.githubusercontent.com/soedinglab/hh-suite/master/scripts/reformat.pl
# Apply multi-chain patch from Lim Heo @huhlim
patch -u alphafold/common/protein.py -i ${COLABFOLD_DIR}/beta/protein.patch
patch -u alphafold/model/model.py -i ${COLABFOLD_DIR}/beta/model.patch
patch -u alphafold/model/modules.py -i ${COLABFOLD_DIR}/beta/modules.patch
patch -u alphafold/model/config.py -i ${COLABFOLD_DIR}/beta/config.patch
popd

# Enable GPU-accelerated relaxation.
echo "Enable GPU-accelerated relaxation..."
(cd ${ALPHAFOLD_DIR} && patch -u alphafold/relax/amber_minimize.py -i ${LOCALCOLABFOLD_DIR}/gpurelaxation.patch)

# Copy execution file for localcolabfold
pushd ${ALPHAFOLD_DIR}
cp ${LOCALCOLABFOLD_DIR}/runner.py .
cp ${LOCALCOLABFOLD_DIR}/runner_af2advanced.py .
popd

echo "Setup for local colabfold finished."