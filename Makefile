# Projeto IA Livre — bootstrap do kernel (UEFI + QEMU)
.PHONY: build esp run verify verify-runtime verify-runtime-gpu verify-runtime-contract verify-node verify-agent verify-harness verify-harness-comparable clean help

export PATH := $(HOME)/.cargo/bin:$(PATH)
# Evita CARGO_TARGET_DIR herdado (ex.: cache de sandbox) fora do repo
export CARGO_TARGET_DIR := $(CURDIR)/target

TARGET       := x86_64-unknown-uefi
KERNEL_EFI   := $(CARGO_TARGET_DIR)/$(TARGET)/debug/ia-livre-kernel.efi
ESP_DIR      := build/esp
ESP_BOOT     := $(ESP_DIR)/EFI/BOOT/BOOTX64.EFI

# Preferir imagem OVMF combinada; senão CODE_4M + VARS copiado para build/
OVMF_BIOS ?= $(firstword \
	$(wildcard /usr/share/ovmf/OVMF.fd) \
	$(wildcard /usr/share/qemu/OVMF.fd))

OVMF_CODE ?= $(firstword \
	$(wildcard /usr/share/OVMF/OVMF_CODE_4M.fd) \
	$(wildcard /usr/share/OVMF/OVMF_CODE.fd))

OVMF_VARS_TEMPLATE ?= $(firstword \
	$(wildcard /usr/share/OVMF/OVMF_VARS_4M.fd) \
	$(wildcard /usr/share/OVMF/OVMF_VARS.fd))

OVMF_VARS := $(CURDIR)/build/OVMF_VARS.fd

QEMU ?= qemu-system-x86_64

help:
	@echo "Alvos: build | esp | run | verify | verify-runtime | verify-runtime-gpu | verify-runtime-contract | verify-node | verify-agent | verify-harness | verify-harness-comparable | clean"
	@echo "Pré-requisitos: ver AGENTS.md → Como rodar"

build:
	rustup target add $(TARGET)
	cargo build -p ia-livre-kernel --target $(TARGET)

esp: build
	mkdir -p "$(ESP_DIR)/EFI/BOOT"
	cp "$(KERNEL_EFI)" "$(ESP_BOOT)"

run: esp
	@command -v "$(QEMU)" >/dev/null || { echo "Instale QEMU: sudo apt install qemu-system-x86"; exit 1; }
	@if [ -n "$(OVMF_BIOS)" ] && [ -f "$(OVMF_BIOS)" ]; then \
		$(QEMU) \
			-machine q35 \
			-m 256M \
			-bios "$(OVMF_BIOS)" \
			-drive format=raw,file=fat:rw:$(ESP_DIR) \
			-serial stdio \
			-display none \
			-net none; \
	elif [ -n "$(OVMF_CODE)" ] && [ -f "$(OVMF_CODE)" ] && [ -n "$(OVMF_VARS_TEMPLATE)" ] && [ -f "$(OVMF_VARS_TEMPLATE)" ]; then \
		mkdir -p build && cp "$(OVMF_VARS_TEMPLATE)" "$(OVMF_VARS)"; \
		$(QEMU) \
			-machine q35 \
			-m 256M \
			-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
			-drive if=pflash,format=raw,file="$(OVMF_VARS)" \
			-drive format=raw,file=fat:rw:$(ESP_DIR) \
			-serial stdio \
			-display none \
			-net none; \
	else \
		echo "OVMF não encontrado. Instale: sudo apt install ovmf"; \
		echo "Ou defina OVMF_BIOS=... ou OVMF_CODE=... + OVMF_VARS_TEMPLATE=..."; \
		exit 1; \
	fi

verify:
	./scripts/verify-boot.sh

verify-runtime:
	./scripts/verify-runtime.sh

verify-runtime-gpu:
	./scripts/verify-runtime-gpu.sh

verify-runtime-contract:
	./scripts/verify-runtime-contract.sh

verify-node:
	./scripts/verify-node.sh

verify-agent:
	./scripts/verify-agent.sh

verify-harness:
	./scripts/verify-harness.sh

verify-harness-comparable:
	./scripts/verify-harness-comparable.sh

clean:
	cargo clean
	rm -rf build/
