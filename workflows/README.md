# Workflows

Some ideas for generating more complex workflows with batch queue systems, SLURM
as an example.

It's a good idea to "script" a workflow:

- documents what was done
- allows easier re-running after all bug fixes and reviewer comments of the
  first attempt(s)
- can be shared with colleagues and other research heirs

Writing a workflow is an art of balance between the time and work you use to
craft the workflow and the time and work it takes to run it. As always with
scripting, *short and simple*** is the goal.

First, have a look at [taito documentation](https://research.csc.fi/taito-user-guide).

## Some concepts

### Idempotence

Usually all the steps in the script do not work with the first go. Try to write
the scrips so that all the steps in them can be run multiple times without
redoing what was already done (or even fail)! This way you can easier and more
efficiently iterate the development of the scripts (fix and simply re-run
cycle).

### Batch system job

When you submit a batch job, `sbatch myjob.sh`, batch queue system only reads
the resource request info. When the resources become available, it allocates all
the requested resources and starts the batch job script as a regular Bash script
on the first allocated core.

## Preparation

- draw a picture (graph) of the tasks that need to be performed
    - shows the dependencies between the tasks, which need to be run in a given
      order and which can be run in parallel
      
- estimate the number of CPU cores, memory and runtime for each task
    - helps to decide how to "chunk" the task into batch jobs

- plan a directory structure for the data, and list input and output files

- how many times you need to repeat the whole workflow, are you planning to
  share it with someone?
    - this guides to choose suitable level of "finesse" for the scripts

### Chuncking

The tasks need to be run in chunks, batch jobs, that fit nicely to the batch
queue system limits. As a rule of thumb, a single job in a workflow should be

- longer than five minutes
- short enough to get the whole workflow done in reasonable time
- smaller jobs (resource requests), with shortish run times and smallish number
  of reserved cores, are easier to fit, and start faster

### Setup

In general, it is useful to write a setup script, which creates all the
directories and moves the input files in place, before submitting the batch job
script(s). This keeps the actual batch job script minimal.

A separate setup step is especially useful if you are requesting multiple cores
for a parallel program, since you want to avoid single core work, such as file
copying, inside parallel reservation.

### Independent tasks

Multiple independent jobs can be run in parallel. SLURM batch queue system
supports [array jobs](https://research.csc.fi/taito-array-jobs), which suites
this perfectly, if the jobs have the same resource requirements.

### Sequential tasks

Some jobs need to be run in a given order. These kind of dependencies can be
given to the SLURM batch queue system using `--dependency` option, so that one
can submit also sequential jobs all at once. See `man sbatch` for details.

## Testing the workflow

Do not try to make the final workflow first. It does not work that way. Use
small test programs and/or test data sets for *quick development cycle* and
testing different ideas.

