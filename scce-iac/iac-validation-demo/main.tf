terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

###############################################################################
# 1. VPC that allows all egress traffic
###############################################################################
resource "google_compute_network" "demo_vpc" {
  name                    = "demo-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "demo_subnet" {
  name                    = "demo-subnet"
  ip_cidr_range           = "10.0.0.0/24"
  region                  = var.region
  network                 = google_compute_network.demo_vpc.self_link
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_all_egress" {
  name    = "allow-all-egress"
  network = google_compute_network.demo_vpc.self_link

  direction = "EGRESS"
  allow {
    protocol = "all"
  }
  destination_ranges = ["0.0.0.0/0"]
}

###############################################################################
# 2. BigQuery dataset and table, publicly accessible
###############################################################################
resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id                  = "demo_dataset"
  location                    = "US"
  default_table_expiration_ms = 3600000  # 1 hour
  project                     = var.project_id

  # Publicly accessible using specialGroup="allUsers"
  access {
    role          = "READER"
    special_group = "allUsers"
  }
}

resource "google_bigquery_table" "demo_table" {
  dataset_id = google_bigquery_dataset.demo_dataset.dataset_id
  table_id   = "demo_table"
  project    = var.project_id

  schema = <<EOF
[
  {
    "name": "id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "value",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}

###############################################################################
# 3. Cloud SQL instance without authorized networks
###############################################################################
resource "google_sql_database_instance" "demo_sql" {
  name             = "demo-sql-instance"
  database_version = "POSTGRES_13"
  project          = var.project_id
  region           = var.region

  settings {
    tier = "db-f1-micro"
  }

  # Intentionally not specifying authorized networks
  # This is a bad practice for demonstration only.
}

resource "google_sql_database" "demo_db" {
  name      = "demo_database"
  instance  = google_sql_database_instance.demo_sql.name
  project   = var.project_id
}

###############################################################################
# 4. Public Storage bucket without uniform bucket-level access
###############################################################################
resource "google_storage_bucket" "demo_bucket" {
  name                        = "my-demo-bucket-${var.project_id}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = false  # intentionally disabled
}

resource "google_storage_bucket_acl" "demo_bucket_acl" {
  bucket = google_storage_bucket.demo_bucket.name

  role_entity = [
    "READER:allUsers",  # Public read access for demonstration
  ]
}

