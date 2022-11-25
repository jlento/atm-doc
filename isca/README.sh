# How to build Isca model in puhti.csc.fi
#
# Change paths below according to what applies to you
#
# 2022-11-25, juha.lento@csc.fi

cd $SCRATCH/
git clone https://github.com/ExeClim/Isca.git
cd Isca/
module purge
module load tykky
mkdir isca_env
conda-containerize new --prefix isca_env ci/environment-py3.9.yml

# Copy file puhti from this repo to src/extra/env/puhti. Remember to edit file paths.

source src/extra/env/puhti

cd $GFDL_BASE/exp/test_cases/held_suarez

# Next command should build the executable but fail at runtime
python held_suarez_test_case.py

# To run properly, create a batch job script
#
# For a simple test in file
#     /scratch/project_2002239/gfdl_work/experiment/held_suarez_default/run/run.sh
# edit the line with mpirun to something like
#     srun -n 16 --account=project_... .../held_suarez.x

bash /scratch/project_2002239/gfdl_work/experiment/held_suarez_default/run/run.sh

# Or better, fix the python stuff so that it creates a proper batch job for puhti (TODO).
