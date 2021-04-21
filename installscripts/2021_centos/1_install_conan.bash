#!/bin/bash

# These commands are based on essdaq installation activities done in April 2021

# Activate the conan environment
echo
echo "To install Conan, first run the check_conan script. Then execute one"
echo "or more of these commands depending on the error messages you get:"
echo
echo "Activate conan environment"
echo '> source /opt/dm_group/virtualenv/conan/bin/activate'
echo
echo "Upgrade conan"
echo '> sudo pip install --upgrade conan'
echo
echo "Create conan profile"
echo '> conan profile new --detect default'
echo
echo "Edit conan profile"
echo '> vi/edit/emacs ~/.conan/profiles/default'
echo
echo "Install conan remotes"
echo '> conan config install https://github.com/ess-dmsc/conan-configuration.git'
