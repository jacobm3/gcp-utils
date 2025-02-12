variable "project_id" {
  type        = string
  description = "ID of the GCP project where resources will be created"
}

variable "region" {
  type        = string
  description = "GCP region for resources (e.g., us-central1)"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone for resources (e.g., us-central1-a)"
  default     = "us-central1-a"
}

