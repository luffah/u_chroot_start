User start a chroot only for nesting app
========================================

This script can be used to run a nested system with rootfs.
It uses unshare, therefore, no root login is used.
The counterpart is that you can't login as another user.

Here an example usage ::
  
  # chroot_start.sh ROOT [MOUNTS:] HOME CMDLINE 
  
  # chroot on ../distrib
  # The following directories will be mounted
  #  ./home on /home/ali
  #  ./etc on /etc
  # The HOME variable is set as /home/ali
  # Finally, we run gvim from this directory
  chroot_start.sh ../distrib home:/home/ali etc: /home/ali "gvim"

For what ?
----------

The aim is to play games using another linux distribution in a nested environnement.
You can use this script if you have a linux rootfs in userspace (e.g. an lxc unprivileged container) or with sudo on any rootfs.

