# ReqRest Documentation [![Build Status](https://dev.azure.com/ManuelRoemer/ReqRest/_apis/build/status/ReqRest%20Documentation?branchName=master)](https://dev.azure.com/ManuelRoemer/ReqRest/_build/latest?definitionId=16&branchName=master)

This repository hosts the documentation for the [ReqRest](https://github.com/manuelroemer/ReqRest) 
libraries.
The documentation is built using [DocFX](https://github.com/dotnet/docfx) and thus consists of
both manually written and automatically generated content.


## Build Process

The documentation is automatically built whenever

* a push to `master` is made in this repository.
* a new release is triggered from the [ReqRest](https://github.com/manuelroemer/ReqRest)
  repository (i.e. if a push to `master` is made and the triggered build of the libraries succeeds).

This means that the documentation can be updated when both manually written content is updated in this
repository and when the ReqRest APIs get updated.


## Building locally

You can locally build the documentation via the `build.ps1` script.
Be aware that it is written with the CI system in mind, so you will have to ensure
that the requirements are met.

You will have to:

* install [DocFX](https://github.com/dotnet/docfx).
* initialize the ReqRest submodule: `git submodule init`,  `git submodule update`.
* launch the script from the repository's root directory.


## Known Problems

There are some known problems with the documentation which unfortunately cannot be fixed
(at least I didn't find a way - if you have a solution, please notify me!).

### Some auto-generated methods don't have any comments/descriptions.
  
**Reason:** These are usually documented with the `<inheritdoc cref="foo" />` tag. DocFX doesn't
support generating the correct documentation for these.


### Some auto-generated members are listed as `Nullable<...>`, even though they are reference types.

**Reason:** DocFX doesn't correctly handle Nullable Reference Types of C# 8.0. 


## Contributing

Contributions to the documentation are welcome!

If you notice any mistakes, be it typos, outdated content or simply wrongly written sections, feel
free to either [create an issue](https://github.com/manuelroemer/ReqRest-Documentation/issues/new)
or simply fix the problem yourself and [create a pull request](https://github.com/manuelroemer/ReqRest-Documentation/compare)
afterwards.

> **Note:** Any modifications in the automatically generated API documentation must be done in the
> source code of the [ReqRest](https://github.com/manuelroemer/ReqRest) repository,
> because it requires changing the XML comments.
> Note that any of these changes require a new release of the libraries to appear in the documentation.


## Acknowledgments

Thanks to [Oscar Vásquez](https://github.com/ovasquez) for creating the
[DocFX Material Theme](https://github.com/ovasquez/docfx-material)!