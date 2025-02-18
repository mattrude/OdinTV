#!/bin/bash

buildDIR='/var/src/OdinTV'
httpDIR='/var/www/html'
architecture="aarch64"
devices="RPi4 RPi5"
branch="libreelec-12.0"
GITURL="https://github.com/LibreELEC/LibreELEC.tv.git"
masterName='libreelec-13.0'
FORCEBUILD=false
RELEASE=false
NIGHTLY=false
OPTIONS=true

######################################################################################

Help() {
    echo "Usage: build-odintv.sh [OPTION]..."
    echo
    echo "Options:"
    echo "  -a <arch>     Architecture: (ie: arm, aarch64)"
    echo "  -b <branch>   Branch: The name of the git branch to build built. (ie: master)"
    echo "  -d <device>   Device: The Raspberry device to be built. (ie: RPi4 RPi5)"
    echo "  -r <version>  Release: Enter the version number for the release. (ie: 12.0.1)"
    echo "  -n            Nightly: Create a nightly build"
    echo "  -f            Force: Force the build to happen"
    echo "  -o            Options: Use default options file"
    echo "  -h            Print this Help message"
    echo
    echo "Source:  https://gist.github.com/mattrude/4f490fa7df1b9fddb835fd609be06cbd"
}

while getopts ":hfa:d:b:r:no" flag
do
    case "${flag}" in
        h) Help
           exit;;
        f) FORCEBUILD=true;;
        a) architecture=${OPTARG};;
        b) branch=${OPTARG};;
        d) devices=${OPTARG};;
        r) RELEASE=${OPTARG};;
        n) NIGHTLY=true;;
        o) OPTIONS=false;;
        \?) echo "Error: Invalid Option!"
            Help
            exit;;
    esac
done

shift $((OPTIND-1))

######################################################################################

scriptName=$(basename -- "$0")
for pid in $(pidof -x ${scriptName}); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : $scriptName : Process is already running with PID $pid"
        exit 1
    fi
done

for pid in $(pidof -x media-syncer.sh); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : media-syncer.sh : Process is blocking this script with PID $pid"
        exit 1
    fi
done

######################################################################################

if [ "${LOGNAME}" != "matt" ]; then
    echo "[$(date)] : $scriptName : Process must be ran by the 'matt' user."
    exit 1
fi

######################################################################################
if [ ${RELEASE} == false ] && [ ${NIGHTLY} == false ]; then DEVEL=true; else DEVEL=false; fi

echo "--------------------------------------------------------------------------"
echo "The OdinTV Build Script was Started at `date`"
echo
if [ $FORCEBUILD == true ]; then echo "     *** This is a FORCED build! ***"; echo; fi
if [ $OPTIONS == false ]; then echo "     *** The default Options file will be used for this build! ***"; echo; fi
echo
echo "Current Build Options"
echo "------------------------------------"
echo "Architecture : ${architecture}"
echo "Branch       : ${branch}"
echo "Devices      : ${devices}"
echo
echo
echo "Current Build Style"
echo "------------------------------------"
echo "Development  : ${DEVEL}"
echo "Nightly      : ${NIGHTLY}"
echo "Release      : ${RELEASE}"
echo

######################################################################################

if [ "${RELEASE}" == "true" ] && [ "`echo ${branch} |wc -w`" != "1" ]; then
    echo "--------------------------------------------------------------------------"
    echo
    echo "                   #############################"
    echo "                   ##########  ERROR  ##########"
    echo "                   #############################"
    echo
    echo "You have selected to build a Release with version number ${RELEASE}, but"
    echo "  you did not select a single build or branch to build the release for."
    echo
    echo "You must add the '-b' flag and choose a single branch from \"${branch}\"."
    exit 1
fi

######################################################################################

for BRANCH in ${branch}
do
    if [ -d ${buildDIR}/${BRANCH}/.git ]; then
        OLDGITID=`git --git-dir=${buildDIR}/${BRANCH}/.git show-ref |grep "refs/remotes/origin/${BRANCH}" |awk '{print $1}' |cut -c -7`
    else
        OLDGITID='new-install'
    fi

    NEWGITID=`git ls-remote --heads ${GITURL} |grep "refs/heads/${BRANCH}" |awk '{ print $1 }' |cut -c -7`
    if [ -z ${NEWGITID} ]; then
        break
    fi

    if $FORCEBUILD; then
    	OLDGITID='forced-build'
    fi

    if [ "${OLDGITID}" != "${NEWGITID}" ]; then
        echo
        echo "Building OdinTV"
        if [ -d ${buildDIR}/${BRANCH}/ ]; then
            git -C ${buildDIR}/${BRANCH}/ reset --hard
            git -C ${buildDIR}/${BRANCH}/ pull
        else
            sudo mkdir -p ${buildDIR}
            sudo chown ${USER}:${USER} ${buildDIR}
            git clone -b ${BRANCH} --single-branch ${GITURL} ${buildDIR}/${BRANCH}
        fi

        mkdir -p ${buildDIR}/${BRANCH}/.libreelec
        echo 'LOGCOMBINE=${LOGCOMBINE:-fail}' 	> ${buildDIR}/${BRANCH}/.libreelec/options
        echo 'MTPROGRESS=${MTPROGRESS:-yes}' 	>> ${buildDIR}/${BRANCH}/.libreelec/options
        echo 'DISTRONAME="OdinTV"' 		>> ${buildDIR}/${BRANCH}/.libreelec/options
        if [ "$NIGHTLY" != "false" ]; then
            echo 'BUILD_PERIODIC="nightly"'	>> ${buildDIR}/${BRANCH}/.libreelec/options
        elif [ "$RELEASE" != "false" ]; then
            echo 'OFFICIAL="yes"'	 	>> ${buildDIR}/${BRANCH}/.libreelec/options
            echo 'BUILDER_NAME="official"' 	>> ${buildDIR}/${BRANCH}/.libreelec/options
            echo 'LIBREELEC_BRANCH="official"' 	>> ${buildDIR}/${BRANCH}/.libreelec/options
            echo "LIBREELEC_VERSION=\"${RELEASE}\"" >> ${buildDIR}/${BRANCH}/.libreelec/options
        fi

        for DEVICE in ${devices}
        do
            git -C ${buildDIR}/${BRANCH}/ reset --hard
            echo
            echo "--------------------------------------------------------------------------"
            echo
            echo "Branch: ${BRANCH}"
            echo "Device: ${DEVICE}"
            echo "Remote Ref ID: ${NEWGITID}"
            echo "Local  Ref ID: ${OLDGITID}"
            echo
            echo "--------------------------------------------------------------------------"
            echo

            if [ -f ${buildDIR}/files/${BRANCH}/options ] && [ ${OPTIONS} == true ]; then
                echo "Using Options File ${buildDIR}/files/${BRANCH}/options"
                cp ${buildDIR}/files/${BRANCH}/options ${buildDIR}/${BRANCH}/distributions/LibreELEC/options
            else
                echo "NOT using Options File!!!"
                exit 1
            fi
            if [ -d ${buildDIR}/packages/ ]; then
                echo "Patching Apps"
                echo "rsync -av ${buildDIR}/packages/ ${buildDIR}/${BRANCH}/packages/"
                rsync -av ${buildDIR}/packages/ ${buildDIR}/${BRANCH}/packages/
            else
                echo "NOT patching Apps!!!!!"
                exit 1
            fi
            cd ${buildDIR}/${BRANCH}/
	        sed -i 's/^HOME_URL.*/HOME_URL=\"https\:\/\/media\.theodin\.network\"/' scripts/image

            echo "Patching Kodi"
            cd ${buildDIR}/${BRANCH}/
            patch -p1 --forward < ../files/vendor_logo.patch || true

            sleep 15

            rm -rf ${buildDIR}/${BRANCH}/target/*
            PROJECT=RPi ARCH=${architecture} DEVICE=${DEVICE} make image

            if [ -f ${buildDIR}/${BRANCH}/target/*-${DEVICE}.aarch64-*img.gz ]; then
                if [ "${BRANCH}" == "master" ]; then RBRANCH=${masterName}; else RBRANCH=${BRANCH}; fi
                if [ "$NIGHTLY" == "true" ]; then IMGLOC="images/nightly"
                elif [ "${RELEASE}" != "false" ]; then IMGLOC="images/releases"
                else IMGLOC="images"; fi
                VERSION=`echo ${RBRANCH} |sed 's/libreelec-//g'`
                HTTPOUTDIR=${httpDIR}/${IMGLOC}/${VERSION}/${DEVICE}
                sudo mkdir -p ${HTTPOUTDIR}
                #echo "Creating GPG Signure file"
		        #gpg --detach-sign `ls ${buildDIR}/${BRANCH}/target/*-${DEVICE}.aarch64-*img.gz`
                sudo rsync -a ${buildDIR}/${BRANCH}/target/*-${DEVICE}.aarch64-*img.gz* ${HTTPOUTDIR}/
                cd ${HTTPOUTDIR}; ls -1tr |head -n -1: |sudo xargs -d '\n' rm -f --
		        sha256sum `ls -t *-${DEVICE}.aarch64-*img.gz |head -1` |sudo tee Current.txt > /dev/null
            fi
        done
    else
        echo "--------------------------------------------------------------------------"
        echo "No Update for branch ${BRANCH} found, skipping..."
        echo
    fi
done

echo "--------------------------------------------------------------------------"
echo "The OdinTV Build Script Finished at `date`"
