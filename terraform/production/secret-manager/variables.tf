variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  type        = string
  default     = "fast-api-jwt-app-12"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "recovery_window_in_days" {
  description = "Number of days to retain secret after deletion"
  type        = number
  default     = 7
}

variable "secret_key" {
  description = "Secret key for JWT encoding"
  type        = string
  sensitive   = true
  default     = "secret"
}

variable "algorithm" {
  description = "Algorithm for JWT encoding"
  type        = string
  default     = "HS256"
}

variable "user_name" {
  description = "Application username"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "password" {
  description = "Application password"
  type        = string
  sensitive   = true
  default     = "123456"
}

variable "url_base" {
  description = "Base URL for the application"
  type        = string
  default     = "http://localhost:8000"
}
