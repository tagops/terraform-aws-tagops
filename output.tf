output "tags" {
  description = "Map of tags returned by the TagOps API for each resource"
  value       = jsondecode(data.http.tagops.response_body)
}

output "status_code" {
  description = "HTTP status code from the TagOps API"
  value       = data.http.tagops.status_code
}
