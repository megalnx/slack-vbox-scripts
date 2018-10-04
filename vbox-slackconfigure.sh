VMNAME=${VMNAME:-"Slackware"}
MNAME=${HNAME:-slack-it.com}
PKG=(${PKGS:-"mpfr"})
LILOTIMEOUT=100
VMKEYENTER='VBoxManage.exe controlvm "$VMNAME" keyboardputscancode "9c" "1c" "9d"'
VMKEYENTER='VBoxManage.exe controlvm "$VMNAME" keyboardputscancode "1c" "9c" "9d"'
INSTALLPKG='VBoxManage.exe controlvm "$VMNAME" keyboardputstring "find /var/log/mount -iname $PKG-*.t?z -exec installpkg --root /mnt {} \;"'
CCMD=($CMDS)

VBoxManage.exe list runningvms | grep $VMNAME
if [[ ! "$?" == "0" ]]; then
  VBoxManage.exe startvm $VMNAME; sleep 20
fi

function basecfg(){

  eval $VMKEYENTER; sleep 2
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'mount /dev/sda1 /mnt'
  eval $VMKEYENTER; sleep 2

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring "mount /dev/sr0 /var/log/mount"; sleep 2
  eval $VMKEYENTER; sleep 2

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring "echo $MNAME > /mnt/etc/HOSTNAME"; sleep 2
  eval $VMKEYENTER; sleep 2

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'sed -i "s/timeout = 1200/timeout = '$LILOTIMEOUT'/g"' /mnt/etc/lilo.conf; sleep 2
  eval $VMKEYENTER; sleep 2

  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'lilo -C /mnt/etc/lilo.conf'; sleep 3
  eval $VMKEYENTER; sleep 2
}

function networksetup(){
  # Network setup
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring 'sed -i "s/USE_DHCP\[0\]=\"\"/USE_DHCP[0]="yes"/g"' /mnt/etc/rc.d/rc.inet1.conf; sleep 2
  eval $VMKEYENTER; sleep 2
}

basecfg

if [[ "${#PKG[@]}" -gt "1" ]]; then
  for pkg in $PKGS; do 
    PKG=$pkg
    echo " -> Installing package: $pkg"
    eval $INSTALLPKG; sleep 1
    eval $VMKEYENTER; sleep 5
  done
elif [[ "${#PKG[@]}" == "1" ]]; then
  eval $INSTALLPKG; sleep 1
  eval $VMKEYENTER; sleep 4
fi
sleep 1


networksetup

if [[ "${#CMDS[@]}" -gt "1" ]]; then
  for cmd in $CMDS; do 
    echo " -> Running custom commands: "
    VBoxManage.exe controlvm "$VMNAME" keyboardputstring "$cmd";
    eval $VMKEYENTER; sleep 5
  done
elif [[ "${#CMDS[@]}" == "1" ]]; then
  VBoxManage.exe controlvm "$VMNAME" keyboardputstring "$cmd";
  eval $VMKEYENTER; sleep 4
fi

eval $VMKEYENTER; sleep 4


