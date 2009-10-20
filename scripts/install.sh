#!/bin/sh

# untitled.sh
# GitX
#
# Created by Andre Berg on 19.10.09.
# Copyright 2009 Berg Media. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Installs GitX.app to $CUSTOM_INSTALL_DIR from Install.xcconfig

# returns 1 if $1 contains $2
# and 0 if it does not
function strcont() {
    result="${1//*$2*/#}"
    result="${result//#/$2}"
    if [[ "$result" == "$2" ]]; then
        echo 1
    else
        echo 0
    fi
}

if [[ $(strcont $BUILD_STYLE "Install") == 1 ]]; then
    echo "Installing to ${CUSTOM_INSTALL_DIR}... (switch to build config other than Install to avoid)"
    if [[ -e /opt/local/bin/rsync ]]; then
        /opt/local/bin/rsync -rlHEptog --xattrs --acls "$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME" "$CUSTOM_INSTALL_DIR/"
    else
        /usr/bin/rsync -rlHEptog "$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME" "$CUSTOM_INSTALL_DIR/"
    fi
else
    echo '$BUILD_STYLE does not contain "Install"... nothing to copy'
fi