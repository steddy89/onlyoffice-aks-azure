.PHONY: help init plan apply destroy fmt validate lint scan deploy-dev deploy-prod helm-lint helm-template kubeconfig clean

SHELL := /bin/bash
TERRAFORM_DIR := terraform
HELM_DIR := kubernetes/helm/onlyoffice-docserver
ENV ?= dev

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Terraform ──────────────────────────────────────────────
init: ## Initialize Terraform
	cd $(TERRAFORM_DIR) && terraform init

plan: ## Plan infrastructure changes (ENV=dev|prod)
	cd $(TERRAFORM_DIR) && terraform plan -var-file=environments/$(ENV).tfvars -out=tfplan

apply: ## Apply infrastructure changes
	cd $(TERRAFORM_DIR) && terraform apply tfplan

destroy: ## Destroy infrastructure (use with caution!)
	cd $(TERRAFORM_DIR) && terraform destroy -var-file=environments/$(ENV).tfvars

fmt: ## Format Terraform files
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

validate: ## Validate Terraform configuration
	cd $(TERRAFORM_DIR) && terraform validate

lint: ## Run TFLint
	cd $(TERRAFORM_DIR) && tflint --recursive

scan: ## Run Checkov security scan
	checkov -d $(TERRAFORM_DIR) --framework terraform --quiet

output: ## Show Terraform outputs
	cd $(TERRAFORM_DIR) && terraform output

# ─── Kubernetes / Helm ──────────────────────────────────────
kubeconfig: ## Get AKS credentials
	az aks get-credentials \
		--resource-group $$(cd $(TERRAFORM_DIR) && terraform output -raw resource_group_name) \
		--name $$(cd $(TERRAFORM_DIR) && terraform output -raw aks_cluster_name) \
		--overwrite-existing
	kubelogin convert-kubeconfig -l azurecli

helm-lint: ## Lint Helm chart
	helm lint $(HELM_DIR)

helm-template: ## Render Helm templates locally
	helm template onlyoffice $(HELM_DIR) --namespace onlyoffice

helm-upgrade: ## Deploy/upgrade ONLYOFFICE via Helm
	helm upgrade --install onlyoffice-docserver $(HELM_DIR) \
		--namespace onlyoffice \
		--create-namespace \
		--wait --timeout 10m

helm-status: ## Check Helm release status
	helm status onlyoffice-docserver -n onlyoffice

# ─── Operations ─────────────────────────────────────────────
status: ## Show cluster and pod status
	@echo "=== Nodes ==="
	kubectl get nodes -o wide
	@echo ""
	@echo "=== ONLYOFFICE Pods ==="
	kubectl get pods -n onlyoffice -o wide
	@echo ""
	@echo "=== HPA ==="
	kubectl get hpa -n onlyoffice
	@echo ""
	@echo "=== Ingress ==="
	kubectl get ingress -n onlyoffice

logs: ## Tail ONLYOFFICE logs
	kubectl logs -n onlyoffice -l app.kubernetes.io/name=onlyoffice-docserver --tail=100 -f

restart: ## Rolling restart of ONLYOFFICE pods
	kubectl rollout restart deployment/onlyoffice-docserver -n onlyoffice

healthcheck: ## Check ONLYOFFICE health endpoint
	@INGRESS_HOST=$$(kubectl get ingress -n onlyoffice -o jsonpath='{.items[0].spec.rules[0].host}'); \
	echo "Checking https://$$INGRESS_HOST/healthcheck"; \
	curl -sk "https://$$INGRESS_HOST/healthcheck" | head -20

# ─── CI Helpers ─────────────────────────────────────────────
ci-validate: fmt validate lint scan helm-lint ## Run all CI validations

# ─── Cleanup ────────────────────────────────────────────────
clean: ## Remove Terraform plan files
	rm -f $(TERRAFORM_DIR)/tfplan
	rm -rf $(TERRAFORM_DIR)/.terraform
