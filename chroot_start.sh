#!/bin/sh
_usage(){
  echo """Start a nested linux in with a fake chroot using unshare.

Usage:
  $(basename $0) <root_dir> [<orig_dir>:[<dest_dir>] *] <home_dir> <cmdline>

Example:
  chroot_start.sh ../common_unprivileged/ubuntu_bionic home:/home/ubuntu etc: /home/ubuntu bash
  """
  exit 1
}

if [ `id -u` -gt 0 ] ; then
  which unshare > /dev/null 2>&1 || _usage 
  unshare -Urfp --mount-proc $0 "$@"
  exit 0
fi

_mounts=
_unmounts=
_home=
target=
_cmd=bash
while [ "$1" ]; do
  case "$1" in
    *:*)
      _morig="$(realpath $(echo ${1} | cut -d: -f1))"
      _mtgt="$(echo ${1} | cut -d: -f2)"
      if [ -z ${_mtgt} ]; then
        _mtgt="$(echo ${1} | cut -d: -f1)"
      fi
      _mtgt="$(echo "${_mtgt}" | sed 's,^/,,')"
      _mounts="${_mounts}mkdir -p ${_mtgt}; mount --bind ${_morig} ${_mtgt};"
      _unmounts="${_unmounts}umount ${_mtgt};"
      ;;
    *)
      if [ -z "${target}" ]; then
        target="$(realpath $1)"
      elif [ -z "${_home}" ]; then
        _home="$1"
      else
        _cmd="${1}"
      fi
      ;;
  esac
  shift
done

if [ -z "$target" ]; then
  _usage
fi
if [ ! -d "$target" ]; then
  echo "$target don't exist"
  exit 2
fi
PULSE_SERVER=${PULSE_SERVER:-10.0.3.1}
PULSE_SINK=${PULSE_SINK:-0}

_NB_SINK=$(pactl list short sinks | wc -l)
if [ $_NB_SINK -gt 1 ]; then
  echo "Choose you pulse sink:"
  PULSE_SINK=$(pactl list short sinks | fzy | cut -f1)
fi

ENV_VARS="PULSE_SERVER=$PULSE_SERVER PULSE_SINK=$PULSE_SINK"

set -x
xhost +local: > /dev/null

cd "$target"
mount -t proc /proc proc/
mount --rbind /sys sys/
mount --rbind /dev dev/
mkdir -p tmp/.X11-unix
mount --bind /tmp/.X11-unix tmp/.X11-unix
sh -c "${_mounts}"

chroot . /bin/bash -c "HOME=$_home; cd \$HOME; ${ENV_VARS} ${_cmd}"

umount proc/
mount --make-rslave sys/
umount -R sys/
mount --make-rslave dev/
umount -R dev/
umount tmp/.X11-unix
sh -c "${_unmounts}"
set +x
