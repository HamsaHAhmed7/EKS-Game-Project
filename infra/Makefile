.PHONY: help install-tools fmt validate lint security scan clean

help:
	@echo "Available targets:"
	@echo "  install-tools  - Install linting and security tools"
	@echo "  fmt           - Format Terraform code"
	@echo "  validate      - Validate Terraform configuration"
	@echo "  lint          - Run TFLint"
	@echo "  security      - Run security scans (Checkov + tfsec)"
	@echo "  scan          - Run all checks"
	@echo "  clean         - Clean Terraform files"

install-tools:
	@echo "Installing tools..."
	pip install checkov detect-secrets --break-system-packages
	curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
	curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
	@echo "✓ Tools installed"

fmt:
	@echo "Formatting Terraform code..."
	terraform fmt -recursive
	@echo "✓ Formatting complete"

validate:
	@echo "Validating Terraform..."
	terraform validate
	@echo "✓ Validation complete"

lint:
	@echo "Running TFLint..."
	tflint --recursive || true
	@echo "✓ Linting complete"

security:
	@echo "Running Checkov..."
	checkov -d . --framework terraform --compact --quiet || true
	@echo "Running tfsec..."
	tfsec . --concise-output || true
	@echo "✓ Security scans complete"

secrets:
	@echo "Scanning for secrets..."
	detect-secrets scan || true
	@echo "✓ Secret scan complete"

scan: fmt validate lint security secrets
	@echo ""
	@echo "✓ All scans complete!"

clean:
	@echo "Cleaning..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Cleanup complete"
