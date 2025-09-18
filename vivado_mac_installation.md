# Install Xilinx Vivado Installer on Apple Silicon (with Docker)

## 0. Installations
Install Docker and XQuartz.

## 1. Pre-Container Setup
Enter the following into the terminal to set up your directories:
```
mkdir -p ~/Xilinx
mkdir -p ~/workspace
```
Enter the following into the terminal to enable XQuartz for the Vivado GUI:
```
xhost +127.0.0.1
```

## 2. Setting up the Container
Enter the following to create and open:
```
docker start -ai vivado_2025 2>/dev/null || docker run --platform=linux/amd64 -it \
  --name vivado_2025 \
  -e DISPLAY=host.docker.internal:0 \
  -v ~/Xilinx:/mnt/xilinx \
  -v ~/workspace:/workspace \
  ubuntu:22.04 /bin/bash
```
Now in the container, set up support for XQuartz:
```
apt-get update
apt-get install -y libxtst6 libxi6 libxrender1 libxft2 x11-apps
```
Enter the following, and you should see a small white clock appear:
```
xclock
```

## 3. Running the Installer
Enter the following to run the installer in your container:
```
cd /workspace
chmod +x FPGAs_AdaptiveSoCs_Unified_SDI_2025.1_0530_0145_Lin64.bin
./FPGAs_AdaptiveSoCs_Unified_SDI_2025.1_0530_0145_Lin64.bin --target /mnt/xilinx/AMD/2025.1
```