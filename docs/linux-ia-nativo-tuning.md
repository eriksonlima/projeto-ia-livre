# Tuning avançado — Linux IA Livre

Além de `ia-livre-native-tune` (governor/sysctl/threads):

| Mecanismo | Como |
|-----------|------|
| **isolcpus** | Hint impresso pelo tune; aplicar no cmdline GRUB (`isolcpus=2-N`) e reboot |
| **hugepages** | Root: tune tenta `vm.nr_hugepages`; ou confira `sysctl.d/99-ia-livre-native.conf` |
| **cgroups** | Isolar inferência em slice systemd (`CPUAffinity=`) — ver SYSTEMD.md |

Gate: `make verify-distro-tune-advanced`. Sem root: SKIP honesto nos applies.
