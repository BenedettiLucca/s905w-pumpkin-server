# Experiment log — S905W Pumpkin Server

**Última situação comprovada:** F0 concluída; F1 em andamento. Imagem Armbian baixada e verificada; primeira gravação do microSD falhou por desconexão USB do leitor (aprox. 18 MB gravados). Nova tentativa pendente de troca de porta/leitor e do script endurecido.

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
- **Rollback e estado final:** a escrita foi iniciada pelo operador e abortada por erro de E/S (ver Registro 004); cartão parcialmente regravado, inutilizável até uma nova gravação completa.
- **Gate aprovado?** NÃO (F1 depende da gravação e da leitura do `uEnv.txt`).
- **Próximo experimento:** ver Registro 004.

## Registro 004 — 2026-11-25 10:35 — F1: falha de gravação por desconexão USB

- **Fase:** F1 — falha.
- **Objetivo / hipótese:** gravar a imagem Armbian no microSD; investigar o `Input/output error` antes de repetir a escrita.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64; leitor USB GEMBIRD `1908:0226` em `usb 1-9`, SCSI `host8`, alvo `/dev/sdd` via `/dev/disk/by-id/usb-Generic_Mass-Storage-0:0`. Comando executado pelo operador com `sudo` na própria sessão. Nenhum comando executado na TX9.
- **Comandos executados (sem segredos):** `sudo bash /tmp/opencode/armbian/write-sd.sh`; em seguida leitura somente-leitura de `lsblk`, `journalctl -k` e `/sys/block/sdd/*`.
- **Resultado observado / evidência:**
  - O script passou por todas as guardas: `Alvo confirmado: /dev/sdd (63864569856 bytes), imagem verificada.` Portanto alvo e SHA-256 estavam corretos.
  - `dd` copiou apenas `17891328 bytes (17 MiB)` em `0,201357 s` e terminou com `Input/output error` e `fsync failed`.
  - `journalctl -k` mostra, no mesmo segundo (10:35:15): `usb 1-9: USB disconnect, device number 29`, seguido de `device offline error, dev sdd, sector 4560 op 0x1:(WRITE)` (e setores 4800–6544) e `Buffer I/O error ... logical block 570..579, lost async page write`. Depois, `usb 1-9: new high-speed USB device number 30` e, às 10:35:17, `sd 8:0:0:0: [sdd] 124735488 512-byte logical blocks`, `Write Protect is off`, `sdd: sdd1 sdd2`.
  - Após a falha, `lsblk` mostra `sdd1` 511M e `sdd2` 2,9G: a tabela de partições da imagem chegou a ser gravada. Isso confirma que o dispositivo é gravável e que a falha foi de conexão, não de *write-protect* nem de imagem corrompida.
  - O mesmo leitor já havia apresentado desconexão e re-enumeração (device 28 → 29) em 10:19:15–16, antes da gravação. Padrão de desconexão física intermitente.
- **Falhas / limitações:** hipótese mais provável = leitor, cabo ou porta USB instável sob carga de escrita (desconexão real no barramento). Não há evidência de falha da imagem, do DTB ou do alvo. O script original usava `bs=4M` com cache de página; a versão seguinte usa blocos de 1 MiB, uma única repetição em modo buffer, verificação da contagem total de bytes e salva o log do kernel em caso de falha. Como o script abortou no `dd`, a leitura do `uEnv.txt` não chegou a acontecer.
- **Rollback e estado final:** cartão com imagem parcial (cerca de 17 MiB do início e tabela de partições reescrita). **Não tentar boot nem considerar F1 concluído**: é necessária uma regravação completa. Nenhum dado do host ou da TX9 foi alterado.
- **Gate aprovado?** NÃO (F1).
- **Próximo experimento:** operador reassentar o cartão e trocar o leitor/porta USB (de preferência outra porta direta, sem hub); então executar `sudo bash /tmp/opencode/armbian/write-sd-v2.sh`. Se a desconexão se repetir, trocar o cartão e/ou o leitor antes de formular qualquer outra hipótese.

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
