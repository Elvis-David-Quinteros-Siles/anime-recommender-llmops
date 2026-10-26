# Política de solo lectura para anime-recommender
path "secret/data/anime-recommender/*" {
  capabilities = ["read"]
}

path "secret/metadata/anime-recommender/*" {
  capabilities = ["read", "list"]
}
