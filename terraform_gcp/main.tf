provider "google" {
  credentials = file("account.json")
  project     = var.project_name
  region      = "us-central1"
}
#### out of packer    ///####  "ssh_private_key_file": "/home/citizenx/.ssh/id_rsa",


resource "google_compute_instance" "tfansible" {
   machine_type = "f1-micro"
  zone         = "us-central1-a"

  count = length(var.vm)
  name = var.vm[count.index]

  tags = ["web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Local SSD disk


  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

metadata = {
    ssh-keys = "${var.private_key_path}:${file(var.public_key_path)}"
  }


  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  #############################################################################
  # This is the 'local exec' method.
  # Ansible runs from the same host you run Terraform from
  #############################################################################

  provisioner "remote-exec" {
    inline = ["echo 'Hello World'"]

    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)

    }
  }
  ## command = "ansible-playbook -i '${google_compute_instance.tfansible.network_interface.0.access_config.0.assigned_nat_ip},' --private-key ${var.private_key_path} ../ansible/httpd.yml"
  #}

  #############################################################################
  # This is the 'remote exec' method.
  # Ansible runs on the target host.
  #############################################################################

  # provisioner "remote-exec" {
  #   inline = [
  #     "mkdir /home/${var.ssh_user}/files",
  #     "mkdir /home/${var.ssh_user}/ansible",
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = "${var.ssh_user}"
  #     private_key = "${file("${var.private_key_path}")}"
  #   }
  # }
  # provisioner "file" {
  #   source      = "../ansible/httpd.yml"
  #   destination = "/home/${var.ssh_user}/ansible/httpd.yml"

  #   connection {
  #     type        = "ssh"
  #     user        = "${var.ssh_user}"
  #     private_key = "${file("${var.private_key_path}")}"
  #   }
  # }
  # provisioner "file" {
  #   source      = "../files/index.j2"
  #   destination = "/home/${var.ssh_user}/files/index.j2"

  #   connection {
  #     type        = "ssh"
  #     user        = "${var.ssh_user}"
  #     private_key = "${file("${var.private_key_path}")}"
  #   }
  # }
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo yum -y install ansible",
  #     "cd ansible; ansible-playbook -c local -i \"localhost,\" httpd.yml",
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = "${var.ssh_user}"
  #     private_key = "${file("${var.private_key_path}")}"
  #   }
  # }
  # Don't comment out this next line.
}

resource "google_compute_firewall" "default" {
  name    = "web-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}
