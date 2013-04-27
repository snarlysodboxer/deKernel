deKernel
========

## A simple Command Line Tool to help with removing old/unused kernels.
*(Especially when they have built up over time and are wasting disk space.)*

#### Simple Instructions:
1. `git clone git@github.com:snarlysodboxer/deKernel.git`
2. `cd deKernel`
3. `./deKernelScript` (or `./deKernelScript --dry-run` to tell apt-get to only pretend to make changes.)
4. Follow the directions! It will confirm with you before making any changes.

#### Command line Options:
* `-s`, `--dry-run`             Pass the '--dry-run' option to apt-get.  This option can be used in combination with any of the other commands.
* `-y`, `--assume-yes`          Pass the --assume-yes option to apt-get. This option can be used in combination with any of the other commands.
* `-n`, `--no-confirm`          Skip the "Are you sure?" step. Useful for scripting. *Use this with caution.* This option can be used in combination with any of the other commands.
* `-x`, `--all-except NUMBER`   Pass the number of *latest* kernels to *leave installed*, the rest are marked for removal.
* `-k`, `--kernels-list 'LIST'` Pass a quoted, space separated list of kernel numbers to be removed. I.E. `--kernels-list '3.2.0-8 3.2.0-11'`. This option is ignored if you pass the `--all-except` option.

### A few more advanced examples:
* `./deKernelScript -x 3` to auto-mark all but the latest three kernels. The marked kernels will be displayed and you will still be asked to confirm.
* `./deKernelScript -x 3 -y -n -s` to simulate removing all but the three latest kernels without any confirmation. Remove the `-s` to actually use this command inside you're own program without user feedback.
* `./deKernelScript -k '3.2.0-11 3.2.0-8' -y -n` to remove the '3.2.0-11' and '3.2.0-8' kernels without confirmation. Again, you could use this command inside you're own program without user feedback.

#### Notes:
* This has currently only been tested on Ubuntu systems. I welcome pull requests to make it compatible with other releases.

* This code essentially automates three commands for you:
  1. We `ls /boot` to gather a list of present `vmlinuz` kernels.
  2. We use `dpkg-query -f '${Package}\n' -W *[pass in each present kernel]*` to find which installed packages belong to those present kernels.
  3. We use `sudo apt-get purge [packages list]` to remove those packages.
