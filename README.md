# ESXi-Deployment
Scripts to export/import OVA files from ESXi using VMware PowerCLI.  

FullDeploy.ps1 -- deploys VMs as OVAs to ESXi host.  Sets up remote access using VNC built into ESXi.  Sets up autostart order (0 no autostart), any other integer numbers define order.

ExportVMs.ps1 -- exports VMs as OVAs to a specified folder using VMware PowerCLI.

vms.txt -- comma delimited list containing VM name, port to use with VNC and auto start order


