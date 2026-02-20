replicaCount: ${replica_count}

image:
  repository: onlyoffice/documentserver
  tag: "8.1"
  pullPolicy: IfNotPresent

ingress:
  enabled: true
  className: "azure-application-gateway"
  annotations:
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
    appgw.ingress.kubernetes.io/use-private-ip: "false"
    appgw.ingress.kubernetes.io/backend-protocol: "http"
    appgw.ingress.kubernetes.io/health-probe-path: "/healthcheck"
    appgw.ingress.kubernetes.io/request-timeout: "300"
    appgw.ingress.kubernetes.io/connection-draining: "true"
    appgw.ingress.kubernetes.io/connection-draining-timeout: "30"
    appgw.ingress.kubernetes.io/waf-policy-for-path: ""
  hosts:
    - host: "${domain_name}"
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: "${tls_secret_name}"
      hosts:
        - "${domain_name}"
