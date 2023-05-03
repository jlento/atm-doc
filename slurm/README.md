# SLURM

## Introduction

### Batch queue system's main objectives

1. Pack the machine full
2. Give a fair share of the resources to all users
3. Direct jobs to most suitable resources

### Basic mode of operation

The basic mode of operation is through command `sbatch`, and a *batch job
script*. Batch job script is almost a regular shell script. The user gives it to
the batch system with `sbatch` command to execute on the compute nodes, instead
of regularily giving it to `bash` shell and executing on the current machine.

At the beginning fo the script there are lines beginning with `#SBATCH <option>`,
that provide the information about what kind of resources the user
would like to get for the job, how many cpu cores, how many compute nodes, how
much memory, for how long time, etc. Batch system finds the suitable resources,
and starts running the batch job script on the first node when the resources
become available.

If you are running an MPI parallel program, the launcher that is integrated with
SLURM is called `srun`, and it is used in place of `mpirun`, `aprun`, `mpiexec`,
etc. If you specified multiple cpus per task, for thread parallel program, you
may need to prepend the thread paralle program with `srun` command, too (to give
it access to multiple cores, instead of only the first one, that is runing the
script).

### Quirks

Slurm has three commands that can create reservations, `sbatch`, `srun` and
`salloc`. Each of these works differently, and they also have some overlap. In
addition to these commands, there is plethora of commands to query the status of
the jobs, resources and queues (partitions).


## FAQ

### Batch job FAQ

https://docs.csc.fi/support/faq/


- Why does my batch job fail?
- Why is my job queuing so long?
- How to estimate how much memory my job needs?
- When will my batch job run?
- How can I change which project is billed for my usage?
- Sending email when a job starts/finishes is not working?


## What's going on in the batch system?

### How to submit a quick test job?

```console
[jlento@puhti-login14 ~]$ sbatch -A $PROJECT -t 10 -p test --wrap='sleep 600'
Submitted batch job 16374989
```

Note, here I use the `--wrap` option, that creates a batch job scipt on the fly,
basically just wrapping the argument of the wrap option into a batch script.

### How to see my own jobs in the queue?

```console
[jlento@puhti-login14 ~]$ squeue -u $USER
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          16374989      test     wrap   jlento  R       0:11      1 r07c06
```

### How to see which jobs I have run (since some date)?

```console
[jlento@puhti-login14 ~]$ sacct -X -u $USER -S 2023-05-02
JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
------------ ---------- ---------- ---------- ---------- ---------- -------- 
16372060           bash interacti+ project_2+          4  COMPLETED      0:0 
16374989           wrap       test project_2+          1    RUNNING      0:0 
```

### How to see the status of the nodes in a partition (queue) and some limits?

```console
[jlento@puhti-login14 ~]$ sinfo -l -p test
Tue May 02 16:53:03 2023
PARTITION AVAIL  TIMELIMIT   JOB_SIZE ROOT OVERSUBS     GROUPS  NODES       STATE NODELIST
test         up      15:00        1-2   no       NO        all      1       mixed r07c06
test         up      15:00        1-2   no       NO        all      1   allocated r07c01
test         up      15:00        1-2   no       NO        all      4        idle r07c[02-05]
```

### How to see how many jobs I can have runing in parallel and in total in the queue?

```console
[jlento@puhti-login14 ~]$ sacctmgr list association Account=$PROJECT Partition=test
   Cluster    Account       User  Partition     Share   Priority GrpJobs       GrpTRES GrpSubmit     GrpWall   GrpTRESMins MaxJobs
   MaxTRES MaxTRESPerNode MaxSubmit     MaxWall   MaxTRESMins                  QOS   Def QOS GrpTRESRunMin
   ---------- ---------- ---------- ---------- --------- ---------- ------- ------------- --------- -----------
   ------------- ------- ------------- -------------- --------- ----------- ------------- -------------------- --------- ------------- 
   puhti project_2+     jlento       test         1                                                                            1
   2                                         normal
```

## What's going on in the node where my job is running?

### You can ssh into a compute node if your job is running there!

```console
[jlento@puhti-login14 ~]$ ssh r07c06
Last login: Tue May  2 16:58:06 2023 from 10.140.14.71

[jlento@r07c06 ~]$ 
```

### In the computing node you can use htop, ps, etc to see what's going on!

You can check if the cpu cores are actually working 100%, and does the number of
processes / threads match the number of reserved cpu cores, or at least is what
you expected.

```console
[jlento@r07c06 ~]$ module load htop
[jlento@r07c06 ~]$ htop
```

In the node you can even attach `gdb` debugger to a running process, and see
what is going on in the process.
