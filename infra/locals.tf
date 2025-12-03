locals {
  project = var.project
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Hamsa"
  }
}