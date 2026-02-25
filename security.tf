resource "null_resource" "security_hardening" {
  depends_on = [digitalocean_droplet.dovps]

  triggers = {
    droplet_id = digitalocean_droplet.dovps.id
  }

  connection {
    type        = "ssh"
    host        = digitalocean_droplet.dovps.ipv4_address
    user        = "do"
    private_key = file(replace(var.ssh_key_path, ".pub", ""))
  }

  # Disable root SSH login
  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sudo systemctl restart ssh",
    ]
  }

  # Install and configure fail2ban
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -qq",
      "sudo apt-get install -y -qq fail2ban > /dev/null",
      "sudo tee /etc/fail2ban/jail.local > /dev/null <<'CONF'",
      "[sshd]",
      "enabled = true",
      "port = ssh",
      "filter = sshd",
      "logpath = /var/log/auth.log",
      "maxretry = 3",
      "bantime = 3600",
      "findtime = 600",
      "CONF",
      "sudo systemctl enable fail2ban",
      "sudo systemctl restart fail2ban",
    ]
  }

  # Configure UFW firewall
  provisioner "remote-exec" {
    inline = [
      "sudo ufw allow OpenSSH",
      "sudo ufw allow 80/tcp",
      "sudo ufw allow 443/tcp",
      "sudo ufw --force enable",
    ]
  }

  # Update packages
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get upgrade -y -qq > /dev/null",
    ]
  }
}
