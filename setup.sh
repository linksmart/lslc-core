#!/bin/bash -e

###########################################################################
# Functions
#

# return 1 if global command line program installed, else 0
# example
# echo "node: $(program_is_installed node)"
function program_is_installed {
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}

# display a message in red with a cross by it
# example
# echo echo_fail "No"
function echo_fail {
  # echo first argument in red
  printf "\e[31m✘ ${1}"
  # reset colours back to normal
  printf "\033[0m\n"
}

# display a message in green with a tick by it
# example
# echo echo_fail "Yes"
function echo_pass {
  # echo first argument in green
  printf "\e[32m✔ ${1}"
  # reset colours back to normal
  printf "\033[0m\n"
}

# echo pass or fail
# example
# echo echo_if 1 "Passed"
# echo echo_if 0 "Failed"
function echo_if {
  if [ $1 == 1 ]; then
    echo_pass $2
  else
    echo_fail $2
  fi
}

###########################################################################
# Main
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "Checking required software"
echo " -> Checking git... $(echo_if $(program_is_installed git))"
echo " -> Checking grunt... $(echo_if $(program_is_installed grunt))"
#echo " -> Checking grip... $(echo_if $(program_is_installed grip))"


echo -n " -> dashboard repository... "
if [ -d "$PWD/static/dashboard" ]; then
    pushd "$PWD/static/dashboard" >> /dev/null
    git pull >> /dev/null
    popd >> /dev/null
else
    pushd "$PWD/static" >> /dev/null
    git clone https://linksmart.eu/redmine/linksmart-opensource/linksmart-local-connect/dgw-dashboard.git dashboard >> /dev/null
    popd >> /dev/null
fi
echo_pass

echo "Building dashboard"
pushd "$PWD/static/dashboard" >> /dev/null
npm install .
grunt
popd >> /dev/null

echo " -> Checking gb..."
  if [ $(program_is_installed gb) -eq 0 ]; then
    go get -u github.com/constabulary/gb/...
  fi

echo "DONE!"
exit 0
