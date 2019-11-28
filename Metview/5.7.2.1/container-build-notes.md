# Building Singularity container on a local machine (MacOS)

2019-11-28, juha.lento@csc.fi


## Install Singularity

First, install VirtualBox and Vagrant, as documented on their web
pages. Then install virtual machine with singularity as documented in
singularity web page.

`Vagrantfile` needs these extra options for X11 forwarding (to XQuartz)

```
config.ssh.forward_agent = true
config.ssh.forward_x11 = true
```


## Build Singularity container with Metview app

The definition file `metview.def` is in this directory.

NOTE: Wait for the build to finish, do not interrupt it, even when
knowing it will not produce intended container.

```
singularity build metview.sif metview.def
```

Test the container:

```
singularity run -H $HOME metview.sif
```

Copy the container to puhti...
