.PHONY: setup
setup: ## Install system packages (requires sudo)
	@echo "🚀 Installing system-level dependencies..."
	sudo apt-get update
	sudo apt-get install -y python3-picamera2 python3-opencv

.PHONY: install
install: ## Install the virtual environment and install the pre-commit hooks
	@echo "🚀 Creating virtual environment using uv"
	@uv venv --system-site-packages
	@uv sync
	@uv run pre-commit install

.PHONY: check
check: ## Run code quality tools.
	@echo "🚀 Checking lock file consistency with 'pyproject.toml'"
	@uv lock --locked
	@echo "🚀 Linting code: Running pre-commit"
	@uv run pre-commit run -a
	@echo "🚀 Static type checking: Running mypy"
	@uv run mypy

.PHONY: test
test: ## Test the code with pytest
	@echo "🚀 Testing code: Running pytest"
	@uv run python -m pytest --doctest-modules

.PHONY: build
build: clean-build ## Build wheel file
	@echo "🚀 Creating wheel file"
	@uvx --from build pyproject-build --installer uv

.PHONY: clean-build
clean-build: ## Clean build artifacts
	@echo "🚀 Removing build artifacts"
	@uv run python -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

.PHONY: run
run: ## Run the taubenturret application and save the process ID
	@[ -d .venv ] || uv venv --system-site-packages
	@bash -c 'uv run taubenturret > .taubenturret.log 2>&1 & echo $$! > .taubenturret.pid'
	@echo "Started taubenturret (PID saved in .taubenturret.pid)"

.PHONY: stop
stop: ## Stop the taubenturret application using the saved PID
	@if [ -f .taubenturret.pid ]; then \
		kill "$(cat .taubenturret.pid)" || true; \
		rm -f .taubenturret.pid; \
		echo "Stopped taubenturret"; \
	else \
		echo "No PID file found"; \
	fi

.PHONY: status
status: ## Check whether taubenturret is running
	@if [ -f .taubenturret.pid ] && kill -0 "$$(cat .taubenturret.pid)" 2>/dev/null; then \
		echo "taubenturret is running (PID $$(cat .taubenturret.pid))"; \
	else \
		echo "taubenturret is not running"; \
	fi

.PHONY: help
help:
	@uv run python -c "import re; \
	[[print(f'\033[36m{m[0]:<20}\033[0m {m[1]}') for m in re.findall(r'^([a-zA-Z_-]+):.*?## (.*)$$', open(makefile).read(), re.M)] for makefile in ('$(MAKEFILE_LIST)').strip().split()]"

.DEFAULT_GOAL := help
