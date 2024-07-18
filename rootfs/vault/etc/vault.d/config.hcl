ui = true
disable_mlock = true

storage "raft" {
  path = "/data/vault"
  node_id = "one"
}

# HTTPS listener
listener "tcp" {
  address       = "127.0.0.1:8200"
  tls_cert_file = "/etc/tls/vault-combined.crt"
  tls_key_file  = "/etc/tls/vault.key"
}

cluster_name = "dc1"
max_lease_ttl = "768h"
default_lease_ttl = "768h"

disable_clustering = "False"
cluster_addr = "https://127.0.0.1:8201"
api_addr = "https://127.0.0.1:8200"
