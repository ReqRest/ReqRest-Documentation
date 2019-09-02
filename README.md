# ReqRest Documentation

This repository hosts the documentation for the [ReqRest](https://github.com/manuelroemer/ReqRest-Documentation) 
libraries.
The documentation is built using [DocFX](https://github.com/dotnet/docfx) and thus consists of
both manually written and automatically generated content.


## Build Process

The documentation is automatically built whenever

* a push to `master` is made in this repository.
* a new release is triggered from the [ReqRest](https://github.com/manuelroemer/ReqRest-Documentation)
  repository (i.e. if a push to `master` is made and the triggered build of the libraries succeeds).

This means that the documentation can be updated when both manually written content is updated in this
repository and when the ReqRest APIs get updated.


## Contributing

Contributions to the documentation are welcome!

If you notice any mistakes, be it typos, outdated content or simply wrongly written sections, feel
free to either [create an issue](https://github.com/manuelroemer/ReqRest-Documentation/issues/new)
or simply fix the problem yourself and [create a pull request](https://github.com/manuelroemer/ReqRest-Documentation/compare)
afterwards.

> **Note:** Any modifications in the automatically generated API documentation must be done in the
> source code of the [ReqRest](https://github.com/manuelroemer/ReqRest-Documentation) repository,
> because it requires changing the XML comments.
> Note that any of these changes require a new release of the libraries to appear in the documentation.


## Acknowledgments

Thanks to [Oscar Vásquez](https://github.com/ovasquez) for creating the
[DocFX Material Theme](https://github.com/ovasquez/docfx-material)!