#!/bin/bash
set -x
source /etc/lsb-release
echo $DISTRIB_RELEASE
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

sudo apt-get update
sudo apt install -y gnupg ca-certificates curl openjdk-11-jdk-headless
sudo apt-get install -y autoconf automake pkg-config libtool numactl clang cmake g++ make curl unzip zip

go_tar=go1.22.3.linux-amd64.tar.gz
wget https://go.dev/dl/${go_tar} -O $HOME/${go_tar}
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $HOME/${go_tar} || true
echo 'export PATH=$PATH:/usr/local/go/bin' >>$HOME/.profile
rm $HOME/${go_tar} || true

if ! which rustc; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	source ~/.cargo/env
fi

source $HOME/.cargo/env

# install gotask
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get update
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
	sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
sudo usermod -aG docker $USER

curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v26.1/protoc-26.1-linux-x86_64.zip
unzip protoc-26.1-linux-x86_64.zip -d $HOME/.local
rm protoc-26.1-linux-x86_64.zip

/usr/local/go/bin/go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
/usr/local/go/bin/go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

if [[ "$DISTRIB_RELEASE" = "20.04" ]]; then
	sudo apt-get install python-is-python3
fi

# install aws-cli
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle-1.19.96.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

curl -s "https://get.sdkman.io" | bash
source "/home/ubuntu/.sdkman/bin/sdkman-init.sh"
sdk install gradle 8.5
