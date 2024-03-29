########################################################################################

.DEFAULT_GOAL := help
.PHONY = get-shellcheck test help

########################################################################################

get-shellcheck: ## Download and install the latest version of shellcheck (requires sudo)
ifneq ($(shell id -u), 0)
	@echo -e "\e[31m▲ This target requires sudo\e[0m"
	@exit 1
endif

	@echo -e "\e[1;36;49m\nDownloading shellcheck…\n\e[0m"
	curl -#L -o shellcheck-latest.linux.x86_64.tar.xz https://github.com/koalaman/shellcheck/releases/download/latest/shellcheck-latest.linux.x86_64.tar.xz
	tar xf shellcheck-latest.linux.x86_64.tar.xz
	rm -f shellcheck-latest.linux.x86_64.tar.xz
	cp shellcheck-latest/shellcheck /usr/bin/shellcheck || :
	rm -rf shellcheck-latest

	@echo -e "\e[1;32;49m\nShellcheck successfully downloaded and installed!\n\e[0m"

test: ## Run shellcheck tests
	shellcheck *.sh

help: ## Show this info
	@echo -e '\nSupported targets:\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e ''

################################################################################
