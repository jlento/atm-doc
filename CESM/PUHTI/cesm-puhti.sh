#!/bin/bash

# Setting up and running CESM in puhti.csc.fi
# 2020-01-13, juha.lento@csc.fi
#
# Following https://escomp.github.io/CESM/release-cesm2/index.html

# Download the configuration files for puhti to HOME directory

cd $HOME
svn export https://github.com/jlento/atm-doc/trunk/CESM .cime

# Lines that more than likely need editing
#
# ~/.cime/config: PROJECT
# ~/.cime/config_machine.xml: <PROJECT>
# ~/.cime/config_machine.xml: <CHARGE_ACCOUNT>
# ~/.cime/config_machine.xml: <CIME_OUTPUT_ROOT>
# ~/.cime/config_machine.xml: <DIN_LOC_ROOT>
# ~/.cime/config_machine.xml: <>

# Verify config_machines.xml

xmllint --noout --schema cime/config/xml_schemas/config_machines.xsd $HOME/.cime/config_machines.xml


# Download the model either to $TMPDIR for a quick test or /projappl for
# more permanent storage

cd $TMPDIR
git clone -b release-cesm2.1.1 https://github.com/ESCOMP/CESM.git my_cesm_sandbox
cd my_cesm_sandbox
svn ls https://svn-ccsm-models.cgd.ucar.edu/ww3/release_tags
./manage_externals/checkout_externals
./manage_externals/checkout_externals -S




