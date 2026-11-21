# Systemd — unidades opcionais

Unidades em `/etc/systemd/system/` (**não** habilitadas por default):

| Unit | Papel |
|------|--------|
| `ia-livre-node.service` | Nó Rede P2P (longa duração) |
| `ia-livre-agent.service` | Exemplo oneshot do agente |

Runtime de inferência é CLI (`ia-livre infer`) — sem unit obrigatória.

## Enable / disable

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ia-livre-node.service   # só se quiser
sudo systemctl disable --now ia-livre-node.service
sudo systemctl enable ia-livre-agent.service        # oneshot sob demanda: start
```

Edite `/etc/ia-livre/ia-livre.conf` e flags em `ExecStart` antes de habilitar.
