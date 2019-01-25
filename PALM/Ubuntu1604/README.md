PALM on Ubuntu 16.04 LTS
========================

These instructions follow [PALM install
instructions](https://palm.muk.uni-hannover.de/trac/wiki/doc/install)
as closely as possible.


Requirements
------------

The list of Ubuntu packages that contain PALM install requirements can
be found from file [playbook.yml](playbook.yml).


Running PALM in a virtual machine
---------------------------------

Install [VirtualBox](https://www.virtualbox.org) and
[Vagrant](https://www.vagrantup.com). Clone this repository, and in
the repository root type

    vagrant up

After the dust has settled, you should have a VM that is set up for
PALM running in the background. Log in to the VM with

    vagrant ssh

and proceed as normal. A tip: you can open GUI windows from the VM if
you log in with `vagrant ssh -- -Y`, and if you have an X-server
(Linux desktop, XQuartz in OS X, Xming in Windows) running on the
host.


PALM source code
----------------

Everything in the original install instructions is relative to palm directory

    export palm_dir=${HOME}/palm/current_version/

Replace `<#>`'s with appropriate credentials below.

    mkdir -p ${palm_dir}
    cd ${palm_dir}
    svn checkout --username <#> --password <#> https://palm.muk.uni-hannover.de/svn/palm/tags/release-4.0 trunk

Link the Ubuntu/gfortran make configuration from this repository to
PALM's `INSTALL` directory. If you are in the provided VM,

    ln -s /vagrant/MAKE.inc.gfortran.ubuntu1604 ${palm_dir}trunk/INSTALL/

for example.


Compile PALM
------------

    export PALM_BIN=${palm_dir}trunk/SCRIPTS
    export PATH=${PALM_BIN}:${PATH}
    palm_simple_install -i MAKE.inc.gfortran.ubuntu1604
    cd MAKE_DEPOSITORY_simple
    make


Run PALM test
-------------

    palm_simple_run -p 4 -n 4 -c example_cbl     # This fails, but it's ok
    cd $(ls -dt OUTPUT.* | tail -1)
    mpiexec -n 4 ./palm < runfile_atmos 
    diff RUN_CONTROL ${palm_dir}/trunk/INSTALL/example_cbl_rc
