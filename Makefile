.PHONY: build
build: ## Build debug target for development.
	swift build --arch arm64 --arch x86_64

.PHONY: help
help: ## Print help information.
	@awk 'BEGIN { \
		FS = ":.*?## " \
	} /^[a-zA-Z_-]+:.*?## / { \
		printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 \
	}' $(MAKEFILE_LIST)

.PHONY: archive
archive: ## Build optimized target for release.
	./script/archive

.PHONY: install
install: ## Install to /usr/local/bin directory.
	cp ./archive/zero /usr/local/bin/zero

.PHONY: uninstall
uninstall: ## Uninstall from /usr/local/bin directory.
	rm -f /usr/local/bin/zero

.PHONY: clean
clean: ## Clean SPM directory.
	swift package clean
