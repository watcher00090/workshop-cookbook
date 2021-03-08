terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14"
}

provider "google" {
  project = "gcp-k3s-experiment"
  region  = "us-central1"
  zone    = "us-central1-c"
}

provider "null" {}

provider "random" {}

resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = "root:${file("~/.ssh/id_rsa.pub")}"
  }
  project = "gcp-k3s-experiment"
}

data "google_compute_image" "machine_image" {
  project = "ubuntu-os-cloud"
  name = "ubuntu-2004-focal-v20210119a"
}

variable "server_upload_dir" {
  default = "/root/"
}

resource "google_compute_instance" "master" {
  depends_on = [google_compute_project_metadata.ssh_keys]
  name = "master"
  machine_type = "e2-standard-2"
  metadata = {
    block-project-ssh-key = false
  }

  # allow root ssh login
  metadata_startup_script =  "sudo sed -i '/^[[:space:]]*PermitRootLogin/d' /etc/ssh/sshd_config && echo 'PermitRootLogin prohibit-password' | sudo tee -a /etc/ssh/sshd_config"
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.machine_image.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }
  }

  connection {
    host  = self.network_interface.0.access_config.0.nat_ip
    type  = "ssh"
    user  = "root"
    agent = true
  }

  #provisioner "file" {
  #  source = "${path.module}/k3s-config-master.sh"
  #  destination = "${var.server_upload_dir}/k3s-config-master.sh"
  #}

  #provisioner "remote-exec" {
  #  inline = ["chmod +x ${var.server_upload_dir}/k3s-config-master.sh && ${var.server_upload_dir}/k3s-config-master.sh"]
  #}

  provisioner "remote-exec" {
    inline = ["export K3S_KUBECONFIG_MODE=\"644\" && export INSTALL_K3S_EXEC=\" --no-deploy servicelb --no-deploy traefik --tls-san ${self.network_interface.0.access_config.0.nat_ip}\" && sudo apt-get update -y && sudo apt-get install -y curl && curl -sfL https://get.k3s.io | sh - "]
  }

}

resource "null_resource" "save-k8s-join-token" {
  depends_on = [google_compute_instance.master]
  provisioner "local-exec" {
    command = "scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${google_compute_instance.master.network_interface.0.access_config.0.nat_ip}:/var/lib/rancher/k3s/server/node-token ${path.module}/node-token"
  }
}

data "local_file" "k8s-join-token" {
  depends_on = [null_resource.save-k8s-join-token]
  filename = "${path.module}/node-token"
}

resource "null_resource" "copy-config-file-to-local-machine" {
  depends_on = [google_compute_instance.master]
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/copy-config-file-to-local-machine.sh && ${path.module}/copy-config-file-to-local-machine.sh"
    environment = {
      MASTER_PUBLIC_IP = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
      MASTER_PRIVATE_IP = google_compute_instance.master.network_interface.0.network_ip
    }
  }
}

resource "google_compute_instance" "worker" {
  depends_on = [data.local_file.k8s-join-token]
  count = 2
  name = "worker-${count.index}"
  machine_type = "e2-standard-2"
  metadata = {
    block-project-ssh-key = false
  }

  # allow root ssh login
  metadata_startup_script =  "sudo sed -i '/^[[:space:]]*PermitRootLogin/d' /etc/ssh/sshd_config && echo 'PermitRootLogin prohibit-password' | sudo tee -a /etc/ssh/sshd_config"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.machine_image.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {

    }
  }

  connection {
    host  = self.network_interface.0.access_config.0.nat_ip
    type  = "ssh"
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = ["export K3S_KUBECONFIG_MODE=\"644\" && export K3S_URL=\"https://${google_compute_instance.master.network_interface.0.access_config.0.nat_ip}:6443\" && export K3S_TOKEN=\"${data.local_file.k8s-join-token.content}\" && sudo apt-get update -y && sudo apt-get install -y curl && curl -sfL https://get.k3s.io | sh -"]
  }
}