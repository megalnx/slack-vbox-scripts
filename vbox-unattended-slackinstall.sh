#!/bin/sh
#
# Copyright 2018  William PC (Slack-IT), Seattle, WA, USA
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

VMNAME=${VMNAME:-"Slackware (32-bit)"}
VMHNAME=${VMHNAME:-"slack-it"}
SDEVICE=/dev/sr0
ROOTPART=/dev/sda1
INSTIME=180 # ~ 3min
RECORD=off
CMDFILE=$CMDFILE

VMKEYENTER='VBoxManage.exe controlvm "$VMNAME" keyboardputscancode "1c" "9c" "9d"'

if [ $RECORD == "on" ]; then
  VBoxManage.exe modifyvm "$VMNAME" --videocap on; sleep 2
else 
  VBoxManage.exe modifyvm "$VMNAME" --videocap off; sleep 2
fi


function boot(){
  VBoxManage.exe modifyvm "$VMNAME" --boot1 dvd --boot2 disk --boot3 none

  VBoxManage.exe startvm "$VMNAME" &
  echo "Waiting for VM "$VMNAME" to power on..."; sleep 22

  # boot
  eval $VMKEYENTER ; sleep 18
  eval $VMKEYENTER ; sleep 4.5
  eval $VMKEYENTER ; sleep 4.5
}

function disk_part(){
  # disk partition
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'fdisk /dev/sda'
  sleep 2; eval $VMKEYENTER; sleep 1

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'n'
  sleep 2; eval $VMKEYENTER; sleep 1

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'p'
  sleep 2; eval $VMKEYENTER; sleep 1

  sleep 2; eval $VMKEYENTER; sleep 1
  sleep 2; eval $VMKEYENTER; sleep 1
  sleep 2; eval $VMKEYENTER; sleep 1

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'w'
  sleep 2; eval $VMKEYENTER; sleep 1
}

function mkfs(){
  # create filesystem
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'mkfs.'"$1"' '"$ROOTPART"
  sleep 2; eval $VMKEYENTER; sleep 12
}

function setup_media(){
  # setup media
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'mount '"$SDEVICE"' /var/log/mount'
  sleep 2
  eval $VMKEYENTER
  sleep 3
}

function autoinstall(){
  # automated installation
	VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'mount '"$ROOTPART"' /mnt'
	sleep 2
	eval $VMKEYENTER

	VBoxManage.exe controlvm "$VMNAME" keyboardputstring '
	slackinstall --promptmode terse \
	  --srcpath /var/log/mount/slackware \
	  --mountpoint /var/log/mount \
	  --target /mnt \
	  --device /dev/sr0 \
	  --series "a#"';
	sleep 2
	eval $VMKEYENTER
	sleep $INSTIME
}

function liloconfig(){
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring "liloconfig /mnt \$(grep "/mnt" /etc/mtab | awk '{print \$1}' )"; sleep 2
  eval $VMKEYENTER
  sleep 2

  eval $VMKEYENTER
  sleep 3

  eval $VMKEYENTER
  sleep 3

  eval $VMKEYENTER
  sleep 3

  eval $VMKEYENTER
  sleep 3

  eval $VMKEYENTER
  sleep 4

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring "cp -av /etc/lilo.conf /mnt/etc/lilo.conf"; sleep 2
  eval $VMKEYENTER
}

if [[ "$1" == "install" ]]; then
  boot
  disk_part
  mkfs ext3
  setup_media
  autoinstall

  # configure system
  eval $VMKEYENTER
  sleep 2
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'cat /etc/mtab | sort | sed s#/mnt#/#g > /mnt/etc/mtab; cp -av /mnt/etc/mtab /mnt/etc/fstab'
  sleep 2; eval $VMKEYENTER; sleep 2
  liloconfig
  sleep 2; eval $VMKEYENTER; sleep 2  
fi


if [[ "$1" == "configure" ]]; then
  boot  
  sleep 2; eval $VMKEYENTER; sleep 2
  PKGS=$PKGS VMNAME=$VMNAME HNAME=$VMHNAME vbox-slackconfigure.sh
  if [[ ! -z $CMDFILE ]]; then
    while IFS= read -r cmd; do
      echo "$cmd"
      VBoxManage.exe controlvm "$VMNAME" keyboardputstring "$cmd"
      sleep 2; eval $VMKEYENTER; sleep 2;
    done < $CMDFILE
  fi
  sleep 2; eval $VMKEYENTER; sleep 2;
fi

# poweroff
VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'poweroff'
sleep 2
eval $VMKEYENTER
sleep 12

VBoxManage.exe modifyvm "$VMNAME" --boot1 disk --boot2 none --boot3 none

if [ $RECORD == "on" ]; then
  VBoxManage.exe modifyvm "$VMNAME" --videocap off
fi

