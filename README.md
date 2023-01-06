# Azure-Terraform-OMEC
OMEC Setup using terraform to setup cloud infrastructure 

Adapted OMEC Intel project for use on Azure.
https://github.com/aws-samples/aws-intel-5g/blob/master/OMEC-UPF-AWS-Deployment-Guide.docx

Files can be used to deploy OMEC userplance and controlplane functions.Bastion Host can be added via Azure portal GUI

![image](https://user-images.githubusercontent.com/117586519/211009448-7bf487ca-ce0c-4d4e-93fc-4b65e3ad18c4.png)


# For MEC/GILAN/CORE
Clone the source code using the command git clone https://github.com/omec-project/ngic-rtc-tmo.git

1.cd ngic-rtc-tmo

2.Install NGIC and its dependencies using included install script ./install.sh

3.make clean

4.make


# For RAN/Onprem
Clone the source code using the command git clone  https://github.com/omec-project/il_trafficgen.git

Install ILT_GEN and its dependencies: follow steps in ./install.sh

# If There are pktgen-dpdk issues please follow the following page for insight into getting packet generator up and running.

https://pktgen-dpdk.readthedocs.io/en/latest/commands.html

Set up the environmental variables required by DPDK:

export RTE_SDK=<DPDKInstallDir>
export RTE_TARGET=x86_64-native-linuxapp-gcc
  
make install T=x86_64-native-linuxapp-gcc

Create the DPDK build tree:
cd $RTE_SDK
  
make install T=x86_64-native-linuxapp-gcc
  
Pktgen can then be built as follows:
cd <PktgenInstallDir>
  
make
