#!/usr/bin/env bash
# Diagnóstico somente leitura para executar NA BOX após boot Linux.
# Saída pode incluir identificadores privados de rede/dispositivos: revisar antes de publicar.
set -u
export LC_ALL=C
section(){ printf '\n=== %s ===\n' "$1"; }
read_if_present(){
  local file="$1"
  if [[ -r "$file" ]]; then
    printf '%s: ' "$file"
    tr '\000' '\n' < "$file" | head -n 12
  fi
}
section 'Kernel e arquitetura'
uname -a
uname -m
section 'Device tree'
read_if_present /proc/device-tree/model
read_if_present /proc/device-tree/compatible
section 'Memoria'
free -h || true
section 'Armazenamento'
lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINTS || true
findmnt / || true
section 'Rede (nao publicar IP sem anonimizar)'
ip -br link || true
section 'Temperatura'
for f in /sys/class/thermal/thermal_zone*/temp; do
  [[ -e "$f" ]] || continue
  zone=${f%/temp}
  printf '%s: ' "${zone##*/}"
  [[ -r "$zone/type" ]] && tr '\000' '\n' < "$zone/type" | head -n 1 || true
  printf 'raw='; cat "$f" || true
done
section 'Concluido: nao houve escrita de dispositivos'
