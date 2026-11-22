#!/usr/bin/env python3
"""Driver serial QEMU para teste de uso live IA Livre."""
from __future__ import annotations

import re
import select
import subprocess
import sys
import time

(
    boot_file,
    boot_src,
    ovmf,
    vars_fd,
    gguf_disk,
    gguf_name,
    log_path,
    report_path,
    mem,
    timeout_s,
) = sys.argv[1:]
mem = int(mem)
timeout_s = int(timeout_s)


def report(line: str) -> None:
    print(line, flush=True)
    with open(report_path, "a", encoding="utf-8") as f:
        f.write(line + "\n")


qemu = [
    "qemu-system-x86_64",
    "-machine",
    "q35",
    # max: cobre AVX residual; build stage deve ser portátil (GGML_NATIVE=OFF)
    "-cpu",
    "max",
    "-m",
    str(mem),
    "-smp",
    "2",
    "-nographic",
    "-no-reboot",
    "-drive",
    f"if=pflash,format=raw,readonly=on,file={ovmf}",
    "-drive",
    f"if=pflash,format=raw,file={vars_fd}",
    "-netdev",
    "user,id=n0",
    "-device",
    "virtio-net-pci,netdev=n0",
    "-drive",
    f"file={gguf_disk},format=raw,if=virtio,readonly=on",
    "-cdrom",
    boot_file,
    "-boot",
    "order=d",
]

logf = open(log_path, "wb")
proc = subprocess.Popen(
    qemu,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    bufsize=0,
)

buf = b""
matched_upto = 0
deadline = time.time() + timeout_s
results: dict[str, bool] = {}


def read_more(wait: float = 0.4) -> None:
    global buf
    end = time.time() + wait
    while time.time() < end:
        if proc.poll() is not None:
            chunk = proc.stdout.read() or b""
            if chunk:
                buf += chunk
                logf.write(chunk)
                logf.flush()
            return
        r, _, _ = select.select([proc.stdout], [], [], 0.2)
        if r:
            chunk = proc.stdout.read(8192) or b""
            if chunk:
                buf += chunk
                logf.write(chunk)
                logf.flush()


def text() -> str:
    return buf.decode("utf-8", "replace")


def new_text() -> str:
    return buf[matched_upto:].decode("utf-8", "replace")


def wait_for(patterns: list[str], max_s: float, label: str = "") -> bool:
    global matched_upto
    end = time.time() + max_s
    pats = [re.compile(p, re.I | re.M) for p in patterns]
    while time.time() < end and time.time() < deadline:
        read_more(0.35)
        chunk = new_text()
        for p in pats:
            m = p.search(chunk)
            if m:
                # advance past match so next wait doesn't reuse it
                matched_upto += m.end()
                return True
        if proc.poll() is not None:
            report(f"IA_LIVRE_USB_USAGE_FAIL=qemu_exit_{proc.returncode}_{label}")
            return False
    report(f"IA_LIVRE_USB_USAGE_TIMEOUT={label}")
    return False


def send(cmd: str) -> None:
    assert proc.stdin is not None
    proc.stdin.write((cmd + "\n").encode())
    proc.stdin.flush()
    time.sleep(0.05)


def mark(name: str, ok: bool, detail: str = "") -> None:
    results[name] = ok
    status = "PASS" if ok else "FAIL"
    report(f"TEST_{name}={status}" + (f" {detail}" if detail else ""))


def wait_shell(max_s: float = 40) -> bool:
    return wait_for([r"ialivre@[^$#\n]*[#$]"], max_s, "shell")


def run_step(name: str, commands: list[str], expect: list[str], max_s: float = 90) -> bool:
    global matched_upto
    start = len(buf)
    matched_upto = start
    n = max(1, len(commands))
    for i, c in enumerate(commands):
        send(c)
        # último comando leva o orçamento cheio (infer/agent longos)
        wait = max_s if i == n - 1 else min(90, max_s)
        if not wait_shell(wait):
            # ainda pode ter emitido marcadores; não aborta o step
            report(f"IA_LIVRE_USB_USAGE_NOTE={name}_shell_wait_partial")
    send(f"echo __DONE_{name}__")
    ok_done = wait_for([rf"__DONE_{name}__"], 90, name)
    wait_shell(30)
    chunk = buf[start:].decode("utf-8", "replace")
    missing = [p for p in expect if not re.search(p, chunk, re.I | re.M)]
    ok_exp = not missing
    if missing:
        report(f"DEBUG_{name}_MISSING={missing}")
        report(f"DEBUG_{name}_TAIL={chunk[-700:]!r}")
    mark(name, bool(ok_done and ok_exp))
    return bool(ok_done and ok_exp)


# boot
if not wait_for(
    [r"ialivre@[^$#\n]*[#$]", r"login:\s*ialivre \(automatic login\)", r"Debian GNU/Linux"],
    240,
    "boot",
):
    report("IA_LIVRE_USB_USAGE_FAIL=no_boot")
    proc.kill()
    sys.exit(1)

if not re.search(r"ialivre@[^$#\n]*[#$]", text()[-6000:]):
    if re.search(r"login:", text()[-3000:]):
        send("ialivre")
        wait_for([r"[Pp]assword:"], 20, "pw")
        send("ialivre")
    wait_shell(90)

mark("boot_login", bool(re.search(r"ialivre@[^$#\n]*[#$]", text()[-8000:])))
send("")
wait_shell(15)

run_step(
    "hostname",
    ["hostname", "grep -E 'ialivre' /etc/hostname && echo HOSTNAME_FILE_OK"],
    [r"^ialivre\s*$|HOSTNAME_FILE_OK", r"HOSTNAME_FILE_OK"],
)

run_step(
    "sudo_nopasswd",
    ["sudo -n id", "sudo -n true && echo SUDO_OK"],
    [r"uid=0\(root\)", r"SUDO_OK"],
)

run_step(
    "docs",
    [
        "test -f /etc/ia-livre/FIRST_BOOT.md && echo FIRST_BOOT_PRESENT",
        "test -f /etc/ia-livre/models-catalog.tsv && echo CATALOG_PRESENT",
        "command -v nano >/dev/null && echo NANO_OK",
        "command -v ia-livre-wifi >/dev/null && echo WIFI_HELPER_OK",
    ],
    [r"FIRST_BOOT_PRESENT", r"CATALOG_PRESENT", r"NANO_OK", r"WIFI_HELPER_OK"],
)

run_step(
    "help_conf",
    ["ia-livre help | head -35", "ia-livre conf"],
    [r"model catalog|MODEL=", r"CONF=/etc/ia-livre|MODEL="],
)

run_step(
    "model_catalog",
    ["ia-livre model catalog"],
    [r"IA_LIVRE_MODEL_CATALOG_OK", r"tinyllama"],
)

run_step(
    "model_list",
    ["ia-livre model list"],
    [r"IA_LIVRE_MODEL_LIST_OK"],
)

# GGUF via virtio disk (vda typically)
run_step(
    "mount_gguf_disk",
    [
        "sudo mkdir -p /mnt/gguf",
        "sudo mount -o ro /dev/vda /mnt/gguf 2>/tmp/mntgguf.err || sudo mount -o ro /dev/vdb /mnt/gguf 2>>/tmp/mntgguf.err",
        f"ls -lh /mnt/gguf/{gguf_name} && echo HOST_GGUF_OK || (cat /tmp/mntgguf.err; ls /dev/vd*; echo HOST_GGUF_FAIL)",
    ],
    [r"HOST_GGUF_OK"],
    max_s=90,
)

if results.get("mount_gguf_disk"):
    run_step(
        "model_set",
        [
            "sudo mkdir -p /var/lib/ia-livre/models",
            f"sudo cp -f /mnt/gguf/{gguf_name} /var/lib/ia-livre/models/{gguf_name} && echo COPY_GGUF_OK",
            f"sudo chown ialivre:ialivre /var/lib/ia-livre/models/{gguf_name}",
            f"ia-livre model set /var/lib/ia-livre/models/{gguf_name}",
            "ia-livre model show",
        ],
        [r"COPY_GGUF_OK", r"IA_LIVRE_MODEL_(SET|OK)"],
        max_s=300,
    )
else:
    run_step(
        "model_fetch_smollm",
        ["ia-livre model fetch smollm2-360"],
        [r"IA_LIVRE_MODEL_FETCH_OK|IA_LIVRE_MODEL_OK"],
        max_s=600,
    )

run_step(
    "infer",
    ["ia-livre infer --n-predict 8"],
    [r"IA_LIVRE_INFER_OK"],
    max_s=480,
)

run_step(
    "agent",
    [
        "mkdir -p ~/agent/fixtures && cd ~",
        "echo prova-read-local-ia-livre > agent/fixtures/read-local-smoke.txt",
        "ia-livre agent --n-predict 8 --prompt 'Digite OK'",
    ],
    [r"IA_LIVRE_AGENT_OK"],
    max_s=600,
)

run_step(
    "node",
    ["timeout 10 ia-livre-node --tcp-port 7400 --node-id usb-usage-test || true"],
    [r"IA_LIVRE_PROTO=v1"],
    max_s=40,
)

run_step(
    "native_tune",
    ["sudo ia-livre-native-tune"],
    [r"IA_LIVRE_NATIVE_TUNE_OK"],
    max_s=60,
)

failed = [k for k, v in results.items() if not v]
passed = [k for k, v in results.items() if v]
report(f"IA_LIVRE_USB_USAGE_PASSED={len(passed)}")
report(f"IA_LIVRE_USB_USAGE_FAILED={len(failed)}")
report("PASSED_LIST=" + ",".join(passed))
report("FAILED_LIST=" + (",".join(failed) if failed else ""))
code = 0
if not failed:
    report("IA_LIVRE_USB_USAGE_OK")
else:
    report("IA_LIVRE_USB_USAGE_FAIL")
    code = 1

send("sudo poweroff -f || true")
time.sleep(2)
try:
    proc.kill()
except Exception:
    pass
logf.close()
sys.exit(code)
