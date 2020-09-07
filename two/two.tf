terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create a web server
resource "digitalocean_droplet" "web" {
  image              = var.droplet_image
  name               = "webserver"
  region             = var.droplet_region
  size               = var.droplet_size
  backups            = true
  monitoring         = true
  private_networking = true
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

# Create a database server
resource "digitalocean_droplet" "database" {
  image              = var.droplet_image
  name               = "dbserver"
  region             = var.droplet_region
  size               = var.droplet_size
  backups            = true
  monitoring         = true
  private_networking = true
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

resource "digitalocean_firewall" "common-firewall" {
  name = "only-allow-ssh-http-and-https"

  droplet_ids = [digitalocean_droplet.web.id, digitalocean_droplet.database.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "mysql-traffic" {
  name = "allow-mysql-traffic-form-webserver"

  droplet_ids = [digitalocean_droplet.database.id]

  inbound_rule {
    protocol           = "tcp"
    port_range         = "3306"
    source_droplet_ids = [digitalocean_droplet.web.id]
  }
}
