variable "source_image" {
  type        = string
  #default     = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
  default     = "/home/rod/Qemu/debian-12-generic-amd64.qcow2"
}

variable "default_ttl" {
  description = "(Optional) The default TTL (Time to Live) in seconds that will be used for all records that support the ttl parameter. Will be overwritten by the records ttl parameter if set."
  type        = string
  default     = 3600
}
