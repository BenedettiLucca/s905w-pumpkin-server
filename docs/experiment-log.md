# Experiment log — S905W Pumpkin Server

**Última situação comprovada:** F0 concluída; F1 em preparação. Imagem Armbian baixada e verificada; gravação do microSD pendente apenas da execução pelo operador (sudo).

Use uma seção para cada experimento. Logs com IPs, usernames, tokens e outros detalhes pessoais devem ser sanitizados antes do commit.

## Registro 001 — 2026-11-24 — Preparação do repositório

- **Fase:** F0 — planejada.
- **Objetivo:** preparar documentação e critérios antes do boot externo.
- **Hardware-alvo:** PCB `B00-MX3mini-REV1.7`, chip marcado S905W, eMMC 16 GB, RAM estimada 2 GiB.
- **Executado:** produção da estrutura de documentos, sem acesso ao hardware.
- **Não testado:** release Armbian exata, DTB/U-Boot, microSD, Ethernet, RAM reconhecida, instalação na eMMC, Pumpkin, visor.
- **Próximo passo:** agente verificar fontes upstream e propor F1 com checklist e identificação da mídia pelo operador.

## Registro 002 — 2026-11-25 — F0: verificação upstream e escolha da imagem

- **Fase:** F0 — concluída.
- **Objetivo / hipótese:** confirmar perfil, imagem e regras de boot antes de tocar em qualquer mídia.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64; leitura de fontes upstream via API/HTTP. Nenhum comando executado na TX9.
- **Versões / URLs / SHA-256:**
  - `ophub/amlogic-s9xxx-armbian`, `model_database.conf`: perfil `111` = `TX3-Mini,MeCool-m8s-pro-W`, `s905w`, `meson-gxl-s905w-tx3-mini.dtb`, `u-boot-s905x-s912.bin`, `uEnv.txt`, `2+8G,100Mb-Nic`, `BUILD=yes`. Perfil `108` (`TX9`) usa `s905x`/`meson-gxl-s905x-tx9.dtb` — **rejeitado** por família de SoC diferente.
  - Release `Armbian_noble_arm64_server_2026.11`: `Armbian_26.11.0_amlogic_s905w_noble_6.12.117_server_2026.11.14.img.gz`, 1.188.260.349 bytes, SHA-256 `de7440731ca4bec802ab97dba20dd4464d56de5d6ae2796cdef2ea674d77fd7f` (digest informado pelo ativo da API do GitHub).
  - Alternativa fallback na mesma release: `Armbian_26.11.0_amlogic_s905w_noble_6.18.63_server_2026.11.14.img.gz`, SHA-256 `30e7b4954a3a6f72eebab35f3b23f3d2b2c6d700fb44e6afd45a50c39d085147`.
  - Pumpkin `0.2.2+26.3-26.60` (2026-11-08) publica `pumpkin-ARM64-Linux`: viável a via systemd + binário nativo.
- **Regras de boot confirmadas:** placas exceto T95/T95Z-Plus/BesTV-R3300L usam somente `/boot/uEnv.txt` — **não** renomear `extlinux.conf.bak`. Alvo: `FDT=/dtb/amlogic/meson-gxl-s905w-tx3-mini.dtb`. Não criar `u-boot.ext` sem exigência explícita da release. Login inicial `root`/`1234`, porta 22.
- **Resultado observado / evidência:** existe build de família `amlogic_s905w`, então não é necessário build por dispositivo; o perfil 111 já está incluído.
- **Falhas / limitações:** nenhum arquivo de checksum separado publicado na release; a verificação usa o digest do próprio ativo.
- **Gate aprovado?** SIM (F0).
- **Próximo experimento:** identificar a mídia no host e gravar a imagem.

## Registro 003 — 2026-11-25 10:31 — F1: preparação e verificação do microSD

- **Fase:** F1 — em andamento.
- **Objetivo / hipótese:** identificar o cartão de 64 GB sem assumir nome de dispositivo e preparar a gravação da imagem.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64, leitor USB GEMBIRD `1908:0226` em `1-9` (SCSI `host8`).
- **Scan inicial:** `/dev/sdd` com 0 bytes e kernel `sd 8:0:0:0: [sdd] Media removed, stopped polling` — leitor enumerado, cartão nãodetectado. Após o operador reassentar o cartão: `sd 8:0:0:0: [sdd] 124735488 512-byte logical blocks (63.9 GB/59.5 GiB)` e `detected capacity change from 0 to 124735488`.
- **Alvo confirmado:** `/dev/sdd` via `/dev/disk/by-id/usb-Generic_Mass-Storage-0:0`; 63.864.569.856 bytes; `removable=1`; `TRAN=usb`; filesystem atual `ext4` em disco inteiro (sem tabela de partições); desmontado; único disco USB do sistema.
- **Comandos executados:** `lsblk`, `findmnt`, leitura de `/sys/block/sdd/*`, `curl -fL` da URL da release, `sha256sum` da imagem.
- **Resultado observado / evidência:** `sha256sum` local = `de7440731ca4bec802ab97dba20dd4464d56de5d6ae2796cdef2ea674d77fd7f`, idêntico ao valor informado pela API. Tamanho local = 1.188.260.349 bytes. Não foi criado filesystem no cartão: a imagem já contém tabela de partições, partição FAT de boot e rootfs ext4.
- **Falhas / limitações:** o host exige senha para `sudo`, então a gravação não pôde ser executada pelo agente; foi preparado o script com guardas em `/tmp/opencode/armbian/write-sd.sh` para execução pelo operador. Risco conhecido: alguns bootloaders Amlogic não iniciam com cartões SDXC >32 GB; se isso ocorrer, testar cartão de 16/32 GB antes de suspeitar do DTB.
- **Rollback e estado final:** nenhuma escrita realizada até aqui; cartão intacto.
- **Gate aprovado?** INDETERMINADO (F1 depende da gravação e da leitura do `uEnv.txt`).
- **Próximo experimento:** operador executar `sudo bash /tmp/opencode/armbian/write-sd.sh`; em seguida montar a partição FAT e conferir `uEnv.txt` e o DTB.

## Modelo para novos registros

### YYYY-MM-DD HH:MM TZ — título

- **Fase:**
- **Objetivo / hipótese:**
- **Equipamento / sistema onde o comando rodou:**
- **Versões / URLs / SHA-256:**
- **Comandos executados (sem segredos):**
- **Resultado observado / evidência:**
- **Temperatura / RAM / armazenamento / rede (quando aplicável):**
- **Falhas / limitações:**
- **Rollback e estado final:**
- **Gate aprovado?** SIM / NÃO / INDETERMINADO
- **Próximo experimento:**
