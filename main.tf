terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "my_key" {
  name       = "DO-WSL-Key"
  public_key = file(var.ssh_key_path)
}

resource "digitalocean_droplet" "dovps" {
  image    = "ubuntu-24-04-x64"
  name     = "dovps"
  region   = "fra1"
  size     = "s-1vcpu-2gb-70gb-intel"
  ssh_keys = [digitalocean_ssh_key.my_key.fingerprint]

  user_data = <<-EOF
              #!/bin/bash
              useradd -m -s /bin/bash do
              usermod -aG sudo do
              echo "do ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
              mkdir -p /home/do/.ssh
              cp /root/.ssh/authorized_keys /home/do/.ssh/
              chown -R do:do /home/do/.ssh
              chmod 700 /home/do/.ssh
              chmod 600 /home/do/.ssh/authorized_keys
              EOF
}
