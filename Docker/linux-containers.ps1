# https://docs.docker.com/docker-for-windows/wsl/

# Set WSL to default to v2
wsl --set-default-version 2

# check the version
wsl -l -v

# Output should show Ubuntu and version 2
# if not, you can upgrade the distro
# this usually takes 5-10 minutes
wsl --set-version Ubuntu 2

# move WSL2 to other disk
wsl --shutdown Ubuntu
wsl --export Ubuntu d:/temp/ubuntu-wsl.tar

wsl --unregister Ubuntu
wsl --import Ubuntu "f:/Virtual Machines/Virtual Hard Disks" d:/temp/ubuntu-wsl.tar

# Set default distro
wsl -s Ubuntu

# change default username
ubuntu config --default-user amanita

## WslRegisterDistribution failed with error: 0xffffffff
# Find the blocking processes and kill it
Get-Process -Id (Get-NetUDPEndpoint -LocalPort 53).OwningProcess | Stop-Process -Force
# Start ubuntu again
Get-Process -Id (Get-NetUDPEndpoint -LocalPort 53).OwningProcess
