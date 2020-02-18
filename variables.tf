variable "project_name" {
  type    = string
  default = "stuff"
}

variable "elastic_ip_ids" {
  type    = list(string)
  default = [
    "eipalloc-d3e23fb6",
    "eipalloc-0fc0c128fc5c4b42f",
    "eipalloc-9c1c0afe"
  ]
}
