variable "db_password" {
  type      = string
  sensitive = true
  default   = "postgres123"
}

variable "db_name" {
  type    = string
  default = "tasks"
}

variable "db_user" {
  type    = string
  default = "dbuser"
}

variable "domain_name" {
  type    = string
  default = "app.k8s.local"
}

variable "app_replicas" {
  type    = number
  default = 2
}

variable "app_image" {
  type    = string
  default = "lednew245/k8s-task-app:latest"
}