#!/bin/bash

echo ""
echo "Installing dotnet cli..."
echo ""

export DOTNET_INSTALL_DIR="./.dotnet/"

tools/install.sh

origPath=$PATH
export PATH="./dotnet/bin/:$PATH"

if [ $? -ne 0 ]; then
  echo >&2 ".NET Execution Environment installation has failed."
  exit 1
fi

export DOTNET_HOME="$DOTNET_INSTALL_DIR/cli"
export PATH="$DOTNET_HOME/bin:$PATH"

export autoGeneratedVersion=false

# Generate version number if not set
if [[ -z "$BuildSemanticVersion" ]]; then
    autoVersion="$((($(date +%s) - 1451606400)/60))-$(date +%S)"
    export BuildSemanticVersion="rc2-$autoVersion"
    autoGeneratedVersion=true
    
    echo "Set version to $BuildSemanticVersion"
fi

sed -i '' "s/99.99.99-rc2/1.0.0-$BuildSemanticVersion/g" */*/project.json 

# Restore packages and build product
dotnet restore -v Minimal # Restore all packages
dotnet pack "Dapper" --configuration Release --output "artifacts/packages"
dotnet pack "Dapper.Contrib" --configuration Release --output "artifacts/packages"

# Build all
# Note the exclude: https://github.com/dotnet/cli/issues/1342
for d in Dapper*/; do 
    if [ "$d" != "*.EntityFramework.StrongName" ]; then
        echo "Building $d"
        pushd "$d"
        dotnet build
        popd
    fi
done

# Run tests
for d in *.Tests*/; do 
    echo "Testing $d"
    pushd "$d"
    dotnet test
    popd
done

sed -i '' "s/1.0.0-$BuildSemanticVersion/99.99.99-rc2/g" */*/project.json 

if [ $autoGeneratedVersion ]; then
    unset BuildSemanticVersion
fi

export PATH=$origPath