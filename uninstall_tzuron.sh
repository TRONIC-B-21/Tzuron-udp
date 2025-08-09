#!/bin/bash
# - Tzuron Remover -

clear
echo -e "Uninstalling Tzuron ..."
systemctl stop tzuron.service 1> /dev/null 2> /dev/null
systemctl disable tzuron.service 1> /dev/null 2> /dev/null
rm /etc/systemd/system/tzuron.service 1> /dev/null 2> /dev/null
killall tzuron 1> /dev/null 2> /dev/null
rm -rf /etc/tzuron 1> /dev/null 2> /dev/null
rm /usr/local/bin/tzuron 1> /dev/null 2> /dev/null
if pgrep "tzuron" >/dev/null; then
  echo -e "Server Running"
else
  echo -e "Server Stopped"
fi
file="/usr/local/bin/tzuron" 1> /dev/null 2> /dev/null
if [ -e "$file" ] 1> /dev/null 2> /dev/null; then
  echo -e "Files still remaining, try again"
else
  echo -e "Successfully Removed"
fi
echo "Cleaning Cache & Swap"
echo 3 > /proc/sys/vm/drop_caches
sysctl -w vm.drop_caches=3
swapoff -a && swapon -a
echo -e "Done."


