# Plan — E85

1. Preparar rootfs com `live-boot` (docker chroot se preciso)
2. `mksquashfs` + `grub-mkrescue` → ISO híbrida
3. Runner QEMU `-cdrom` + gate `verify-distro-iso`
4. Docs + Makefile
