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
# Installs gitx to $CLI_CUSTOM_INSTALL_DIR from Install.xcconfig using gitx_askpasswd

export SUDO_ASKPASS="$BUILT_PRODUCTS_DIR/gitx_askpasswd"
export GITX_ASKPASSWD_DIALOG_TITLE="Please enter sudo pass for Install"

if [[ $BUILD_STYLE =~ "Install" ]]; then
    if [[ $TARGET_NAME =~ "$PRODUCT_NAME" ]]; then
        # install GitX
        echo "Installing ${FULL_PRODUCT_NAME} to ${CUSTOM_INSTALL_DIR}... "
        echo "(switch to build config other than Install to avoid)"
        if [[ ! -d "$CUSTOM_INSTALL_DIR" ]]; then
            echo "$CUSTOM_INSTALL_DIR doesn't exist. Will create it for you..."
            sudo -A -E /bin/mkdir -p "${CUSTOM_INSTALL_DIR}"
        fi
        if [[ -e /opt/local/bin/rsync ]]; then
            /opt/local/bin/rsync -rlHEptog --xattrs --acls "$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME" "$CUSTOM_INSTALL_DIR/"
        else
            /usr/bin/rsync -rlHEptog "$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME" "$CUSTOM_INSTALL_DIR/"
        fi
    elif [[ $TARGET_NAME =~ "cli tool" ]]; then
        # install cli tool
        echo "Installing gitx command line tool to ${CLI_CUSTOM_INSTALL_DIR}..."
        echo "(switch to build config other than Install to avoid)"
        if [[ ! -d "$CLI_CUSTOM_INSTALL_DIR" ]]; then
            echo "$CLI_CUSTOM_INSTALL_DIR doesn't exist. Will create it for you..."
            sudo -A -E /bin/mkdir -p "${CLI_CUSTOM_INSTALL_DIR}"
        fi 
        if [[ -e /opt/local/bin/rsync ]]; then
            sudo -A -E /opt/local/bin/rsync -rlHEptog --xattrs --acls "$BUILT_PRODUCTS_DIR/gitx" "$CLI_CUSTOM_INSTALL_DIR/"
        else
            sudo -A -E /usr/bin/rsync -rlHEptog "$BUILT_PRODUCTS_DIR/gitx" "$CLI_CUSTOM_INSTALL_DIR/"
        fi
    fi
else
    echo '$BUILD_STYLE does not contain "Install"... nothing to copy'
fi