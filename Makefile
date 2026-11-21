# Projeto IA Livre — bootstrap do kernel (UEFI + QEMU)
.PHONY: build esp baremetal-esp run verify verify-runtime verify-runtime-gpu verify-runtime-contract verify-gpu-manager verify-gpu-shard-host verify-node verify-agent verify-harness verify-harness-comparable verify-harness-a-otimizada verify-baremetal verify-write-usb verify-docs-consistency clean help

export PATH := $(HOME)/.cargo/bin:$(PATH)
# Evita CARGO_TARGET_DIR herdado (ex.: cache de sandbox) fora do repo
export CARGO_TARGET_DIR := $(CURDIR)/target

TARGET       := x86_64-unknown-uefi
# Etapa 44: release opt-in — `make build PROFILE=release` ou IA_LIVRE_KERNEL_PROFILE=release
PROFILE      ?= $(or $(IA_LIVRE_KERNEL_PROFILE),debug)
KERNEL_EFI   := $(CARGO_TARGET_DIR)/$(TARGET)/$(PROFILE)/ia-livre-kernel.efi
ESP_DIR      := build/esp
ESP_BOOT     := $(ESP_DIR)/EFI/BOOT/BOOTX64.EFI
CARGO_PROFILE_FLAG := $(if $(filter release,$(PROFILE)),--release,)

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
# Etapa 27: RAM para GGUF ~638 MiB + overhead (documentado ADR 0009).
QEMU_MEM ?= 1536M
MODEL_GGUF ?= models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
# Cópia dedicada para QEMU BlockIO (evita lock com runtime host / fat16).
GGUF_QEMU_IMG ?= build/gguf-canon.gguf

help:
	@echo "Alvos: build | esp | baremetal-esp | run | verify | verify-baremetal | verify-write-usb | verify-runtime | … | clean"
	@echo "Pré-requisitos: ver AGENTS.md → Como rodar"

build:
	rustup target add $(TARGET)
	@echo "kernel PROFILE=$(PROFILE)"
	cargo build -p ia-livre-kernel --target $(TARGET) $(CARGO_PROFILE_FLAG)

esp: build
	mkdir -p "$(ESP_DIR)/EFI/BOOT"
	cp "$(KERNEL_EFI)" "$(ESP_BOOT)"
	./scripts/esp-stage-gguf-prefix.sh
	@test -f "$(MODEL_GGUF)" || { echo "Modelo ausente: $(MODEL_GGUF)"; exit 1; }
	@mkdir -p build
	@if [ ! -f "$(GGUF_QEMU_IMG)" ] || [ "$$(wc -c <"$(GGUF_QEMU_IMG)")" != "$$(wc -c <"$(MODEL_GGUF)")" ]; then \
		echo "esp: staging $(GGUF_QEMU_IMG) for QEMU BlockIO…"; \
		cp -f "$(MODEL_GGUF)" "$(GGUF_QEMU_IMG)"; \
	fi

run: esp
	@command -v "$(QEMU)" >/dev/null || { echo "Instale QEMU: sudo apt install qemu-system-x86"; exit 1; }
	@if [ -n "$(OVMF_BIOS)" ] && [ -f "$(OVMF_BIOS)" ]; then \
		test -f "$(GGUF_QEMU_IMG)" || { echo "Ausente $(GGUF_QEMU_IMG) — make esp"; exit 1; }; \
		$(QEMU) \
			-machine q35 \
			-m $(QEMU_MEM) \
			-bios "$(OVMF_BIOS)" \
			-drive format=raw,file=fat:rw:$(ESP_DIR) \
			-blockdev driver=file,node-name=gguf-file,filename="$(GGUF_QEMU_IMG)",locking=off \
			-blockdev driver=raw,node-name=gguf0,file=gguf-file \
			-device ide-hd,drive=gguf0,bus=ide.1 \
			-serial stdio \
			-display none \
			-net none; \
	elif [ -n "$(OVMF_CODE)" ] && [ -f "$(OVMF_CODE)" ] && [ -n "$(OVMF_VARS_TEMPLATE)" ] && [ -f "$(OVMF_VARS_TEMPLATE)" ]; then \
		mkdir -p build && cp "$(OVMF_VARS_TEMPLATE)" "$(OVMF_VARS)"; \
		test -f "$(GGUF_QEMU_IMG)" || { echo "Ausente $(GGUF_QEMU_IMG) — make esp"; exit 1; }; \
		$(QEMU) \
			-machine q35 \
			-m $(QEMU_MEM) \
			-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
			-drive if=pflash,format=raw,file="$(OVMF_VARS)" \
			-drive format=raw,file=fat:rw:$(ESP_DIR) \
			-blockdev driver=file,node-name=gguf-file,filename="$(GGUF_QEMU_IMG)",locking=off \
			-blockdev driver=raw,node-name=gguf0,file=gguf-file \
			-device ide-hd,drive=gguf0,bus=ide.1 \
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

verify-gpu-manager:
	./scripts/verify-gpu-manager.sh

verify-gpu-shard-host:
	./scripts/verify-gpu-shard-host.sh

verify-node:
	./scripts/verify-node.sh

verify-agent:
	./scripts/verify-agent.sh

verify-harness:
	./scripts/verify-harness.sh

verify-harness-comparable:
	./scripts/verify-harness-comparable.sh

verify-harness-a-otimizada:
	./scripts/verify-harness-a-otimizada.sh

baremetal-esp: build
	./scripts/make-baremetal-esp.sh

verify-baremetal:
	./scripts/verify-baremetal.sh

verify-write-usb:
	./scripts/verify-write-usb.sh

verify-docs-consistency:
	./scripts/verify-docs-consistency.sh

clean:
	cargo clean
	rm -rf build/
