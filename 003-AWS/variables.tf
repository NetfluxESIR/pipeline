variable "github_username" {
  description = "GitHub username"
  default     = "backend-automation"
}
variable "github_token" {
  description = "GitHub token"
  sensitive   = true
}

variable "admin_account_email" {
  description = "Admin account email"
  default     = "admin@admin.com"
}

variable "admin_account_password" {
  description = "Admin account password"
  sensitive   = true
}

variable "registry_server" {
  description = "Registry server containing the container image"
  default     = "ghcr.io"
}