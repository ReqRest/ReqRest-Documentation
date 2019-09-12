# Builds the documentation from source.
# Run this script from the root of the repository.
#
# Requirements:
# 1) DocFX must be installed (e.g. via 'choco install docfx -y').
# 2) The git submodule must be initialized (at ./ReqRest).
#    Futhermore, this script should be able to checkout master and pull the latest changes.

# Ensure that we are building against the latest release of ReqRest.
Set-Location ReqRest
git checkout master
git pull

Set-Location src
dotnet restore


Set-Location ../../doc

# Clean any potentially left over files from a recent build.
# DocFX should automatically do this, but let's be safe.
Remove-Item _site -Recurse -ErrorAction Ignore
Remove-Item obj   -Recurse -ErrorAction Ignore
Remove-Item api/.manifest  -ErrorAction Ignore
Remove-Item api/*.yml      -ErrorAction Ignore

docfx metadata -f
docfx build --serve

Set-Location ..