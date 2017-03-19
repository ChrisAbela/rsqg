#!/bin/bash

# A script to generate sbopkg queue files recursively.

# Copyright 2017 Chris Abela <kristofru@gmail.com>, Malta
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

CONF=${CONF:-/etc/sbopkg/sbopkg.conf}
TEMP=${TEMP:-$HOME/.rsqg}
ITERATION=1

function read_deps() {
  echo "#${APP}" > ${APP}.sqf
  source $REPO_ROOT/$REPO_NAME/$REPO_BRANCH/*/$APP/${APP}.info
  REQUIRES=$( echo $REQUIRES | sed 's/%README%//' )
  if [ -n "$REQUIRES" ]; then
    echo "  Application $APP has these dependencies:"
    echo "    $REQUIRES"
  else echo "  Application $APP has no dependencies."
  fi
  for DEP in $REQUIRES; do
    DEP="@$DEP"
    LIVE=1 ; # We are not finished yet.
    echo $DEP >> ${APP}.sqf
  done
  echo $APP >> ${APP}.sqf
}

function get_deps(){
  # Check if arguments are in the SBo repository
  if ls $REPO_ROOT/$REPO_NAME/$REPO_BRANCH/*/$APP > /dev/null 2>&1; then
    # If we already have the queue file do nothing
    if ! ls ${APP}.sqf > /dev/null 2>&1; then
      echo "  Application $APP is not here, so let's get the dependencies."
      read_deps
    else echo "  Queue file for $APP was found in the repository, so we will not touch it."
    fi
  else echo "  Application $APP was not found in the SBo repository."
  fi
}

source $CONF
mkdir -p $TEMP
cd $TEMP
[ $# -eq 0 ] && exit
echo "Iteration 1:"
while [ $# -gt 0 ]; do
  APP=$1
  get_deps
  shift 1
done

LIVE=1
while [ $LIVE -eq 1 ]; do
  let 'ITERATION += 1';
  echo "Iteration $ITERATION:"
  LIVE=0
  for SQF in *.sqf; do
    if [ -r "$SQF" ]; then
      echo "  Let's check the dependencies of $SQF:"
      DEP_STRING=$( grep -v %README% $SQF | grep -v '^#' |  sed 's/^@//' )
      for APP in $DEP_STRING; do
        get_deps
      done
    fi
  done
done
