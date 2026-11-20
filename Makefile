# Projeto IA Livre — bootstrap do kernel (UEFI + QEMU)
.PHONY: build esp run clean help

export PATH := $(HOME)/.cargo/bin:$(PATH)
# Evita CARGO_TARGET_DIR herdado (ex.: cache de sandbox) fora do repo
export CARGO_TARGET_DIR := $(CURDIR)/target

TARGET       := x86_64-unknown-uefi
KERNEL_EFI   := $(CARGO_TARGET_DIR)/$(TARGET)/debug/ia-livre-kernel.efi
ESP_DIR      := build/esp
ESP_BOOT     := $(ESP_DIR)/EFI/BOOT/BOOTX64.EFI

# Firmware OVMF (override com OVMF_CODE=/caminho/OVMF_CODE*.fd)
OVMF_CODE ?= $(firstword \
	$(wildcard /usr/share/OVMF/OVMF_CODE_4M.fd) \
	$(wildcard /usr/share/OVMF/OVMF_CODE.fd) \
	$(wildcard /usr/share/ovmf/OVMF.fd) \
	$(wildcard /usr/share/qemu/OVMF.fd))

QEMU ?= qemu-system-x86_64

help:
	@echo "Alvos: build | esp | run | clean"
	@echo "Pré-requisitos: ver AGENTS.md → Como rodar"

build:
	rustup target add $(TARGET)
	cargo build -p ia-livre-kernel --target $(TARGET)

esp: build
	mkdir -p "$(ESP_DIR)/EFI/BOOT"
	cp "$(KERNEL_EFI)" "$(ESP_BOOT)"

run: esp
	@if [ -z "$(OVMF_CODE)" ] || [ ! -f "$(OVMF_CODE)" ]; then \
		echo "OVMF não encontrado. Instale: sudo apt install ovmf"; \
		echo "Ou defina OVMF_CODE=/caminho/para/OVMF_CODE*.fd"; \
		exit 1; \
	fi
	@command -v "$(QEMU)" >/dev/null || { echo "Instale QEMU: sudo apt install qemu-system-x86"; exit 1; }
	$(QEMU) \
		-machine q35 \
		-m 256M \
		-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
		-drive format=raw,file=fat:rw:$(ESP_DIR) \
		-serial stdio \
		-display none \
		-net none

clean:
	cargo clean
	rm -rf build/
