.PHONY: install uninstall update lock

install:
	bash scripts/install.sh

uninstall:
	bash scripts/uninstall.sh

update:
	nvim --headless "+Lazy! sync" "+TSUpdate" "+qa" || true

lock:
	nvim --headless "+Lazy! sync" "+Lazy lock" "+qa" || true
