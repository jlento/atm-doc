## Vocabulary

Below are some interpretations of different terms that are useful in this
context.

**Software package** contains related application executables, libraries and
data files, and metadata about from what other software packages they depend on.

**Package manager** is a tool that resolves dependencies between software
packages and can install packages with their dependencies, automatically. The
most common Linux package managers are yum and apt, for .deb and .rpm type
packages, respectively.

**Package repository** is a collection of compatible software packages, usually
accessible from Internet. Packages provided by different repositories are not
necessarily compatible, even when they use the same package manager.

**Linux distribution** is an operating system (OS) that consist of a Linux
kernel and other software packages that are installed from a single repository.
Some examples are Ubuntu, Debian, RedHat and CentOS. Linux distributions use
package managers, and install software system wide, usable to all users. One
needs administrator privileges to manage OS distribution packages.

**Software environment** in this context means a set of locally installed
software packages that are compatible with each other. The OS default
environment is provided by the Linux distribution. Software in the OS
environment in Linux is commonly installed under '/bin', '/lib', '/usr', '/etc'
directories in the root '/' of the file system.

**Environment module system** is a traditional tool to manage multiple software
environments in cluster machines. Environment modules usually modify user
software environment by changing environment variables that control from which
directories the shell looks for programs and libraries, such as 'PATH' and
'LD\_LIBRARY\_PATH'. In this model, different packages can be installed anywhere
in the file system.

**Virtual environment** is a user space (usually) environment that is on top of
the OS environment. It may temporarily override or extend parts of the OS
environment from a single user perspective. The root of the virtual environment
can be located anywhere, for example under '/home/$USER/'. All packages in the
virtual environment are installed under the same root.

Many virtual environments can coexist in the same machine. Virtual environments
are often needed when one needs to install complicated software dependencies
without root privileges, or many mutually incompatible software versions. Trying
out different Python or R packages is a common use case.

**Conda** is a user space package manager and a virtual environment management
tool. Conda uses it's own package format. Conda package contains the
pre-compiled binaries, the recipe how binaries were built, and the dependency
metadata. Conda packages are installed under virtual environments. Conda runs on
multiple platforms, Linux, Mac OS, and Windows.

**Channel** is a conda term for package repository. Similarily to other package
managers, conda allows installing packages from multiple channels to a single
environment. It is the users responsibility to check the compatibility of
packages from multiple channels. Usually it is a good idea to use mainly one
channel per virtual environment. Also, note that the quality of the packages,
especially outside anaconda and conda-forge repositories may vary a lot, as many
of smaller channels are not actively maintained.


## Basic guidelines for using Conda

- Simplest way to set up conda is to install it the same way in a cluster as in
  a local workstation or laptop, by running the install program from
  https://docs.conda.io/en/latest/miniconda.html , and following the
  instructions. As conda install root, choose a directory with enough space.

Example (in taito.csc.fi):

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $WRKDIR/DONOTREMOVE/miniconda3
```

- Usually it is a good idea to use only one environment management system at a
  time, for example, either environment module system or conda.

Example (in taito.csc.fi):

```
module purge
source $WRKDIR/DONOTREMOVE/miniconda3/etc/profile.d/conda.sh
```

- To create and update conda environments, use .yaml files for defining the
  environment, and `conda env create|update` commands. You can store the .yaml
  files that define your environment with the software projects sources in
  GitHub, for example.

Examples (in taito.csc.fi):

```
conda env create -f <envname>.yaml
conda env update -f <envname>.yaml
```

  
*c-ide.yaml* example (in taito.csc.fi):

```
name: c-ide
channels:
  - /wrk/jle/DONOTREMOVE/conda/channels/csc-forge-based
  - conda-forge
  - defaults
  - anaconda
dependencies:
  - git
  - font-ttf-source-code-pro
  - emacs
  - global
  - ctags
  - clangdev
  - cmake
  - make
```
