#!/bin/bash

echo "Installing PINF.it toolchain for OSX."

if ! hash git 2>/dev/null; then
	echo "ERROR: 'git' command not found. Please install from: http://git-scm.com/download/mac"
	exit 1
fi
if ! hash curl 2>/dev/null; then
	echo "ERROR: 'curl' command not found. Please install (it should have come with the base OS)."
	exit 1
fi

VERBOSE=""
DEBUG=""

# `-v` for verbose; `-d` for debug
while getopts ":vd" opt; do
  case $opt in
    v)
      VERBOSE="*"
      ;;
    d)
      DEBUG="*"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# TODO: Make toolchain location configurable.
TOOLCHAIN_PATH="/pinf"

# @credit http://stackoverflow.com/a/246128/330439
BASE_PATH="$(cd "$(dirname "$0")"; pwd)/pinf-it-install"

if [ ! -d "$BASE_PATH" ]; then
	mkdir $BASE_PATH
fi
cd $BASE_PATH

if [ ! -d "node_modules" ]; then
	echo "Downloading bootstrap code packages into: $BASE_PATH"
	mkdir node_modules
fi
cd node_modules;

if [ ! -f "node.tar.gz" ]; then
	echo "Downloading NodeJS (Server-Side JavaScript Runtime):"
    curl -# -o node.tar.gz http://nodejs.org/dist/v0.10.0/node-v0.10.0-darwin-x64.tar.gz
fi
if [ ! -d "node" ]; then
	mkdir node
	tar -C node --strip 1 -zxf node.tar.gz
fi

if [ ! -f "sm.tar.gz" ]; then
	echo "Downloading 'sm' (Sourcemint Package Manager):"
    curl -# --location -o sm.tar.gz https://s3.amazonaws.com/s3.sourcemint.org/github.com/sourcemint/sm/-archives/sm-0.3.6-pre.62.tgz
fi
if [ ! -d "sm" ]; then
	mkdir sm
	tar -C sm --strip 1 -zxf sm.tar.gz
fi

cd ..

if [ ! -d ".sm" ]; then
	echo "Bootstrapping 'sm'"
	mkdir .sm
fi
if [ ! -d ".sm/bin" ]; then
	mkdir .sm/bin
fi
if [ ! -L ".sm/bin/node" ]; then
	ln -s ../../node_modules/node/bin/node .sm/bin/node
fi
if [ ! -L ".sm/bin/sm" ]; then
	ln -s ../../node_modules/sm/bin/sm-cli .sm/bin/sm
fi

export SM_HOME="$BASE_PATH"
export SM_BIN_PATH="$BASE_PATH/.sm/bin/sm"

if [ ! -d "$TOOLCHAIN_PATH" ]; then
	echo "Initializing toolchain at: $TOOLCHAIN_PATH"
	echo "NOTE: We temporarily need 'sudo' to create directory at: $TOOLCHAIN_PATH"
	sudo mkdir $TOOLCHAIN_PATH
	sudo chown $USER:staff $TOOLCHAIN_PATH
	if [ ! -d "/usr/local/bin" ]; then
		sudo mkdir /usr/local/bin
	fi
	echo "NOTE: A browser should open to authenticate 'sm' with github."
	echo "      After you click 'Continue' the installation will proceed."	
	if [ -z "$DEBUG" ]; then
		if [ -z "$VERBOSE" ]; then
			$SM_BIN_PATH --init-toolchain github.com/pinf-it/pinf-it-seed --dir $TOOLCHAIN_PATH > /dev/null
		else
			$SM_BIN_PATH --init-toolchain github.com/pinf-it/pinf-it-seed --dir $TOOLCHAIN_PATH
		fi  
	else
		$SM_BIN_PATH --init-toolchain github.com/pinf-it/pinf-it-seed --dir $TOOLCHAIN_PATH --debug
	fi
	if [ $? -ne 0 ] ; then
		exit 1
	fi	
	if [ ! -L "$TOOLCHAIN_PATH/.sm/bin/sm" ]; then
		ln -s ../../node_modules/sm/bin/sm-cli $TOOLCHAIN_PATH/.sm/bin/sm
	fi
	export SM_HOME=$TOOLCHAIN_PATH
	export SM_BIN_PATH="$SM_HOME/.sm/bin/sm"
	if [ -z "$DEBUG" ]; then
		if [ -z "$VERBOSE" ]; then
			$SM_BIN_PATH status . --dir $SM_HOME > /dev/null
		else
			$SM_BIN_PATH status . --dir $SM_HOME
		fi
	else
		$SM_BIN_PATH status . --dir $SM_HOME --debug
	fi
	if [ $? -ne 0 ] ; then
		exit 1
	fi	
	if [ ! -f "$SM_HOME/profiles/default/credentials.json" ]; then
		cp $BASE_PATH/profiles/default/credentials.json $SM_HOME/profiles/default/credentials.json
	fi
	echo "Installing 'sm' on PATH:"
	if [ -z "$DEBUG" ]; then
		sudo $SM_BIN_PATH --install-command
	else
		sudo $SM_BIN_PATH --install-command --debug
	fi
	if [ $? -ne 0 ] ; then
		exit 1
	fi	
else
	echo "You already have an install at: $SM_HOME"
fi

echo ""
echo "Success! Opening 'http://mac.pinf.it/intro' to get you started."
echo ""

open http://mac.pinf.it/intro

exit 0
