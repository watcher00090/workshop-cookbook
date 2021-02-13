# this is snippet included in ../main.tf via templatefile()
# All dollar-sign+curly braces are interpolated by terraform; escape by doubling dollar sign.
# Without curly braces dollar signs are safe.

# NOTE: This script is to be run by root

sudo hostnamectl set-hostname "${hostname}"

# set up multiple ssh public keys for both ${user} and root - allowing ssh to root account which is disabled in authorized_keys by AWS by default
mkdir -p "/home/${user}/.ssh" /root/.ssh/
# sudo rm "/home/${user}/.ssh/authorized_keys" /root/.ssh/authorized_keys || true

%{for ssh_public_key in ssh_public_keys~}
echo '${lookup(ssh_public_key, "key_file", "__missing__") == "__missing__" ? trimspace(lookup(ssh_public_key, "key_data")) : trimspace(file(lookup(ssh_public_key, "key_file")))}' >> /home/ubuntu/.ssh/authorized_keys
echo '${lookup(ssh_public_key, "key_file", "__missing__") == "__missing__" ? trimspace(lookup(ssh_public_key, "key_data")) : trimspace(file(lookup(ssh_public_key, "key_file")))}' | sudo tee -a /root/.ssh/authorized_keys
%{endfor~}

# Install additional packages requested by configuration
#apt-get -q update
#apt-get -qy install \
#%{for install_package in install_packages~}
#	${install_package} \
#%{endfor~}

while ! apt-get -qy update; do 
	sleep 10
done

%{for install_package in install_packages~}
	while ! apt-get -qy install ${install_package}; do
		sleep 10
	done
%{endfor~}

# Install kubeadm and Docker
echo "
Package: docker-ce
Pin: version ${docker_version}.*
Pin-Priority: 1000
" > /etc/apt/preferences.d/docker-ce
echo "
Package: kubelet
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubelet

echo "
Package: kubeadm
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubeadm
while ! apt-get update; do
	sleep 10
done
while ! apt-get install -y apt-transport-https curl; do
	sleep 10
done
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list
while ! apt-get update; do 
	sleep 10
done
while ! apt-get install -y docker.io kubeadm; do
	sleep 10
done
