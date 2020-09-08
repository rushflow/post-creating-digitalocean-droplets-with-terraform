terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "webserver" {
  count              = 2
  image              = var.droplet_image
  name               = "webserver-${count.index}"
  region             = var.droplet_region
  size               = var.droplet_size
  backups            = true
  monitoring         = true
  private_networking = true
  ssh_keys = [
    var.ssh_fingerprint
  ]
}

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

resource "digitalocean_firewall" "ssh-icmp-and-outbound" {
  name = "allow-ssh-and-icmp"

  droplet_ids = concat(digitalocean_droplet.webserver.*.id, [digitalocean_droplet.database.id])

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
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

resource "digitalocean_firewall" "http-https" {
  name = "allow-http-and-https"

  droplet_ids = digitalocean_droplet.webserver.*.id

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
}

resource "digitalocean_firewall" "mysql" {
  name = "allow-mysql-traffic-form-webservers"

  droplet_ids = [digitalocean_droplet.database.id]

  inbound_rule {
    protocol           = "tcp"
    port_range         = "3306"
    source_droplet_ids = digitalocean_droplet.webserver.*.id
  }
}
