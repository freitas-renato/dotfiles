bass source /opt/ros/melodic/setup.bash

set PATH $PATH /home/renato/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin
set PATH $PATH /usr/local/share/gcc-arm-none-eabi-8-2019-q3-update/bin /usr/local/share/gcc-arm-none-eabi-8-2019-q3-update/arm-none-eabi/bin/

set -gx CUBE_PATH /home/renato/STMicroelectronics/STM32Cube/STM32CubeMX

alias jetson-usb='sudo ip a add 192.168.55.2/24 dev enp0s20f0u3'

alias oe-env='set -e LD_LIBRARY_PATH; bass source /usr/local/oecore-x86_64/environment-setup-armv7at2hf-neon-angstrom-linux-gnueabi'

alias dhcp-server='/etc/init.d/isc-dhcp-server restart'

