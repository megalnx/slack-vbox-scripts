VM="${VMNAME:-Slackware}"
VMHNAME="${VMHOSTNAME:-darkvbox}"
VMDISK="${VMDISK:-/Users/$(whoami)/Documents/VirtualBox/$VM/$VM.vdi}"
VMMEM=${VMMEM:-512}
VMVMEM=10
COUNTRY=US
VMDISKSIZE=2048
MEDIAISO="d:/slackware/slackware-14.1-iso/slackware-14.1-install-dvd.iso"
VMOSTYPE="Linux"
MACADDRESS=$MACADDRESS
AUDIO=$AUDIODEV


HLINE="########################"
 
if [[ "$#" -lt "1" ]]; then
  echo "Usage: $0 'unattended cfg file'"
  exit
else 
  source $1 || echo "Failed to open cfg file" 
  
fi


function new_instance() {
  echo "Creating VM instance: $VM"
  if [[ ! -z "$BASEFOLDER" ]]; then
    echo "Storage folder: $BASEFOLDER"
    VBoxManage createvm --name $VM --ostype "$VMOSTYPE" --basefolder $BASEFOLDER --register || exit 1
  else
    VBoxManage createvm --name $VM --ostype "$VMOSTYPE" --register || exit 1
  fi

  sleep 1
}

function cfg_storage() {
  echo "Configuring storage..."
  if [[ ! -f $VMDISK ]]; then 
    VBoxManage createhd --filename $VMDISK --size $VMDISKSIZE; sleep 1
  fi
  VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI --portcount 4; sleep 1
  VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VMDISK; sleep 1
  VBoxManage storagectl $VM --name "IDE Controller" --add ide; sleep 1
  VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$MEDIAISO"; sleep 1
}

function cfg_boot() {
  echo "Configuring VM boot"
  VBoxManage modifyvm $VM --boot1 none --boot2 none --boot3 none --boot4 none
  sleep 1
  VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none
}

function cfg_addon() {
  echo "Additional VM setup"
  VBoxManage modifyvm $VM --ioapic on
  sleep 1
  VBoxManage modifyvm $VM --memory $VMMEM --vram $VMVMEM
  sleep 1
  if [[ ! -z $MACADDRESS ]]; then
    VBoxManage modifyvm $VM --macaddress1 $MACADDRESS
    sleep 1
  fi

  if [[ -z $AUDIO ]]; then
    VBoxManage modifyvm $VM --audio none
    sleep 1
  fi
}

function createvboxvm() { 
  new_instance
  cfg_storage
  cfg_addon
}

if [[ "$#" -lt "2" ]]; then
  createvboxvm | tee > log/$VM-instance.log
fi

if [ "$2" == "install" ]; then
  cfg_boot
  echo $HLINE
  echo " Installing Slackware..."
  echo $HLINE
  #cd scripts/vbox
  VMNAME=$VM vbox-unattended-slackinstall.sh install | tee > log/$VM-install.log
elif [ "$2" == "configure" ]; then
  echo $HLINE
  echo " Configuring Slackware VM..."
  echo $HLINE
  cfg_addon
#  VBoxManage.exe startvm $VM;
  CMDFILE=$CMDFILE VMNAME=$VM VMHNAME=$VMHNAME vbox-unattended-slackinstall.sh configure
#  PKGS=$PKGS VMHNAME=$VM HNAME=$VMHNAME vbox-slackconfigure.sh
fi

exit

echo -n "Do you with to poweron the machine ? (y/N)" 
read reply
case  $reply in 
	y | Y)
	VBoxManage startvm $VM --type headless
	;;
	n | N)
	;;
	*)
	echo "Unknown option"
	;;
esac
