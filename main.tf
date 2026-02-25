# 1. Визначаємо провайдера
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# 2. Налаштовуємо змінну для токена
variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

# 3. Додаємо ваш SSH-ключ
resource "digitalocean_ssh_key" "my_key" {
  name       = "DO-WSL-Key"
  public_key = file("~/.ssh/do.pub")
}

# 4. Описуємо Droplet (Параметри згідно зі скріншотом)
resource "digitalocean_droplet" "dovps" {
  image    = "ubuntu-24-04-x64"
  name     = "dovps"                # Назва самого сервера в панелі DO
  region   = "fra1"
  
  # "s-1vcpu-2gb-intel" відповідає обраному на скріні плану:
  # Premium Intel, 2GB RAM, 70GB NVMe SSD ($16/mo)
  size = "s-1vcpu-2gb-70gb-intel"

  ssh_keys = [digitalocean_ssh_key.my_key.fingerprint]

# Скрипт автоматичного створення користувача
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
# 5. Виводимо IP адресу після створення
output "droplet_ip" {
  value = digitalocean_droplet.dovps.ipv4_address
}
