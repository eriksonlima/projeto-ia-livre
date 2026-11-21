# IA Livre — PATH e hints (first-boot / login TTY)
export PATH="/opt/ia-livre/bin:/usr/local/bin:${PATH}"

if [[ -z "${IA_LIVRE_PROFILE_SHOWN:-}" ]]; then
  export IA_LIVRE_PROFILE_SHOWN=1
  echo "IA Livre: ia-livre model list | ia-livre infer | ia-livre-native-tune"
  echo "Modelo: copie um .gguf para /var/lib/ia-livre/models/ (veja /etc/ia-livre/FIRST_BOOT.md)"
fi
