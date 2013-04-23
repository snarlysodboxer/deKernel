deKernel
========

## A simple Command Line Tool to help with removing old/unused kernels.
*(Especially when they have built up over time and are waisting disk space.)*

#### Instructions
1. `git clone git@github.com:snarlysodboxer/deKernel.git`
2. `cd deKernel`
3. `./deKernelScript`
4. Follow the directions! It will confirm with you before making any changes.

#### NOTES
* This has currently only been tested on Ubuntu systems. I welcome pull requests to make it compatible with other releases.

* This code essentially automates three commands for you:
  1. We `ls /boot` to gather a list of present `vmlinuz` kernels.
  2. We use `dpkg-query -f '${Package}\n' -W *[pass in each present kernel]*` to find which installed packages belong to those present kernels.
  3. We use `sudo apt-get purge [packages list]` to remove those packages.
