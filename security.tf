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
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      # UFW first — ensure SSH stays open before enabling
      "sudo ufw allow OpenSSH",
      "sudo ufw allow 80/tcp",
      "sudo ufw allow 443/tcp",
      "sudo ufw --force enable",

      # Disable root SSH login
      "sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sudo systemctl restart ssh",

      # Install and configure fail2ban
      "sudo apt-get update -qq",
      "sudo apt-get install -y -qq fail2ban > /dev/null",
      "printf '[sshd]\\nenabled = true\\nport = ssh\\nfilter = sshd\\nlogpath = /var/log/auth.log\\nmaxretry = 5\\nbantime = 3600\\nfindtime = 600\\n' | sudo tee /etc/fail2ban/jail.local > /dev/null",
      "sudo systemctl enable fail2ban",
      "sudo systemctl restart fail2ban",

      # Update packages
      "sudo apt-get upgrade -y -qq > /dev/null",
    ]
  }
}
