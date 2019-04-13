sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt-get update -qq
#sudo apt-get install -y cmake gcc gfortran g++ liblapack-dev libopenmpi-dev openmpi-bin
sudo apt-get install -y cmake gcc gfortran g++

pip --version
pip install --upgrade pip
pip install --upgrade fprettify
which fprettify
