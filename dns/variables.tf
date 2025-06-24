variable "source_image" {
  type        = string
  default     = "/home/q/libvirt_pool/jammy-server-cloudimg-amd64.img"
}

variable "default_ttl" {
  description = "(Optional) The default TTL (Time to Live) in seconds that will be used for all records that support the ttl parameter. Will be overwritten by the records ttl parameter if set."
  type        = string
  default     = 3600
}

variable "volume_count" {
  description = "number of vm"
  default = 4
}
