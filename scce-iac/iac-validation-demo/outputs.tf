output "vpc_name" {
  description = "The name of the newly created VPC"
  value       = google_compute_network.demo_vpc.name
}

output "subnetwork_name" {
  description = "The name of the newly created subnetwork"
  value       = google_compute_subnetwork.demo_subnet.name
}

output "firewall_name" {
  description = "The name of the firewall rule allowing all egress traffic"
  value       = google_compute_firewall.allow_all_egress.name
}

output "bigquery_dataset_id" {
  description = "The ID of the publicly accessible BigQuery dataset"
  value       = google_bigquery_dataset.demo_dataset.dataset_id
}

output "bigquery_table_id" {
  description = "The ID of the publicly accessible BigQuery table"
  value       = google_bigquery_table.demo_table.table_id
}

output "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL instance without authorized networks"
  value       = google_sql_database_instance.demo_sql.name
}

output "cloud_sql_database_name" {
  description = "The name of the Cloud SQL database"
  value       = google_sql_database.demo_db.name
}

output "storage_bucket_name" {
  description = "The name of the public Storage bucket"
  value       = google_storage_bucket.demo_bucket.name
}

