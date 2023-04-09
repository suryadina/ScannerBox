# Taken from https://github.com/six2dez/reconftw/blob/main/Terraform/terraform-reconFTW.tf
# Modified to GCP by ChatGPT

provider "google" {
  project = "YOUR_PROJECT_ID"
  region  = "us-west1-a"
}

resource "google_compute_network" "reconFTW_network" {
  name = "reconFTW-network"
}

resource "google_compute_firewall" "reconFTW_firewall" {
  name    = "reconFTW-firewall"
  network = google_compute_network.reconFTW_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["61111"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "reconFTW_Instance" {
  name         = "reconFTW-instance"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  network_interface {
    network = google_compute_network.reconFTW_network.self_link
  }

  metadata_startup_script = "sudo hostname"

  metadata = {
    "ssh-keys" = "admin:${file("${path.root}/terraform-keys.pub")}"
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file("${path.root}/terraform-keys")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostname"
    ]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${google_compute_instance.reconFTW_Instance.network_interface[0].access_config[0].nat_ip},' -u admin --private-key terraform-keys reconFTW.yml"
  }
}
