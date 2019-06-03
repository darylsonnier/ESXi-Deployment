# ESXi-Deployment
Scripts to export/import OVA files from ESXi using VMware PowerCLI.  

FullDeploy.ps1 -- deploys VMs as OVAs to ESXi host.  Sets up remote access using VNC built into ESXi.  Sets up autostart order (0 no autostart), any other integer numbers define order.

ExportVMs.ps1 -- exports VMs as OVAs to a specified folder using VMware PowerCLI.

vms.txt -- comma delimited list containing VM name, port to use with VNC and auto start order

vnc-1.0.0-10.x86_64.vib -- Community supported level package that contains firewall rules to allow incoming VNC connections for VMs in ESXi and to allow incoming connections to the ESXi NTP daemon.  





*VIB files can be opened as an archive with 7 zip to confirm file content.  This should ALWAYS be done with any VIB found on the Internet prior to installation.
