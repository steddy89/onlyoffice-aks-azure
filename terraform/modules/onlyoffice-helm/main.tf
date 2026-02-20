# ==============================================================================
# ONLYOFFICE Helm Deployment Module
# ==============================================================================

resource "kubernetes_namespace" "onlyoffice" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "onlyoffice"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# ---- Kubernetes Secrets ----
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "onlyoffice-db-credentials"
    namespace = kubernetes_namespace.onlyoffice.metadata[0].name
  }

  data = {
    DB_HOST     = var.postgresql_host
    DB_PORT     = "5432"
    DB_NAME     = var.postgresql_database
    DB_USER     = var.postgresql_user
    DB_PWD      = var.postgresql_password
    DB_TYPE     = "postgres"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "redis_credentials" {
  metadata {
    name      = "onlyoffice-redis-credentials"
    namespace = kubernetes_namespace.onlyoffice.metadata[0].name
  }

  data = {
    REDIS_SERVER_HOST     = var.redis_host
    REDIS_SERVER_PORT     = tostring(var.redis_port)
    REDIS_SERVER_PASS     = var.redis_password
    REDIS_SERVER_USE_TLS  = "true"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "jwt_secret" {
  metadata {
    name      = "onlyoffice-jwt"
    namespace = kubernetes_namespace.onlyoffice.metadata[0].name
  }

  data = {
    JWT_SECRET  = var.jwt_secret
    JWT_ENABLED = "true"
    JWT_HEADER  = "Authorization"
  }

  type = "Opaque"
}

# ---- Storage Class for Azure Files ----
resource "kubernetes_storage_class" "azure_files" {
  metadata {
    name = "azurefile-onlyoffice"
  }

  storage_provisioner = "file.csi.azure.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"

  parameters = {
    skuName        = "Premium_ZRS"
    storageAccount = var.storage_account_name
  }

  mount_options = ["dir_mode=0777", "file_mode=0777", "uid=101", "gid=101"]
}

# ---- Persistent Volume Claims ----
resource "kubernetes_persistent_volume_claim" "onlyoffice_data" {
  metadata {
    name      = "onlyoffice-data"
    namespace = kubernetes_namespace.onlyoffice.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.azure_files.metadata[0].name

    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "onlyoffice_logs" {
  metadata {
    name      = "onlyoffice-logs"
    namespace = kubernetes_namespace.onlyoffice.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.azure_files.metadata[0].name

    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}

# ---- Helm Release ----
resource "helm_release" "onlyoffice" {
  name       = "onlyoffice-docserver"
  namespace  = kubernetes_namespace.onlyoffice.metadata[0].name
  chart      = "${path.module}/../../../../kubernetes/helm/onlyoffice-docserver"

  timeout = 600
  wait    = true

  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      replica_count        = var.replica_count
      domain_name          = var.domain_name
      tls_secret_name      = var.tls_secret_name
      storage_account_name = var.storage_account_name
    })
  ]

  set_sensitive {
    name  = "env.JWT_SECRET"
    value = var.jwt_secret
  }
}
