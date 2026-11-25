# Experiment log — S905W Pumpkin Server

**Última situação comprovada:** F0 e F1 concluídas; F2 em andamento. O cartão de 64 GB foi gravado e verificado com sucesso, mas o HDMI da TX9 não funciona e o proprietário não consegue confirmar visualmente o boot. Varredura somente-leitura da rede local não encontrou host Armbian novo, e o reset não mudou o resultado (Registros 007–008). Por decisão do proprietário, o cartão de 64 GB foi formatado em exFAT para armazenamento de ROMs (Registro 009) e o próximo teste usará um microSD de 16 GB. Nenhuma alteração na eMMC/bootloader da TX9.

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

## Registro 005 — 2026-11-25 10:39 — F1: falsa gravação concluída; imagem escrita em arquivo dentro de /dev

- **Fase:** F1 — falha (diagnóstico de causa raiz).
- **Objetivo / hipótese:** verificar a gravação da v2; investigar por que `lsblk` não mostrava `FSTYPE` nas partições do cartão.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64; leitor USB GEMBIRD `1908:0226` em `usb 1-9`, SCSI `host8`. Comandos do operador com `sudo`; leituras do agente sem root. Nenhum comando executado na TX9.
- **Comandos executados (sem segredos):** `sudo bash /tmp/opencode/armbian/write-sd-v2.sh`; `sudo bash /tmp/opencode/armbian/verify-sd.sh`; `lsblk -f /dev/sdd`; `udevadm info --query=all --name=/dev/sdd1|2`; `stat /dev/disk/by-id/usb-Generic_Mass-Storage-0:0`; `df -h /dev`; `gzip -dc IMG | leitura Python dos primeiros bytes`; `journalctl -k --since '-40 min'`.
- **Resultado observado / evidência:**
  - A v2 reportou `Escrita em buffer concluida` e `3686793216 bytes (3,4 GiB) copied, 10,5975 s, 348 MB/s` — exatamente o tamanho esperado da imagem descomprimida. Depois abortou em `ABORTADO: particao FAT de boot nao encontrada`.
  - `lsblk -f /dev/sdd` mostrou `sdd1` e `sdd2` sem `FSTYPE`. `udevadm info` confirmou `ID_PART_ENTRY_TYPE=0xc`, offset 8192, tamanho 1046528 em `sdd1` e `ID_PART_ENTRY_TYPE=0x83`, offset 1056768, tamanho 6144000 em `sdd2` — ou seja, a tabela de partições da imagem estava presente, mas os sistemas de arquivos não.
  - A imagem local foi inspecionada diretamente: MBR com partição 1 `0x0c` @8192/1046528 e partição 2 `0x83` @1056768/6144000; boot com `FAT32   ` em `0x52` e rótulo `mkfs.fat`; rootfs com magic `53ef` em `0x38`. A imagem está íntegra.
  - `verify-sd.sh` abortou com `ABORTADO: /dev/disk/by-id/usb-Generic_Mass-Storage-0:0 nao e um bloco`.
  - `stat` revelou a causa: `/dev/disk/by-id/usb-Generic_Mass-Storage-0:0` é um **arquivo regular de 3.686.793.216 bytes**, e não um symlink. `df -h /dev` mostrou 3,5 GB usados em devtmpfs. Enquanto `*-part1` e `*-part2` continuam sendo symlinks para `sdd1`/`sdd2`, o link do disco inteiro foi substituído por arquivo.
  - `journalctl -k` explica o mecanismo: novas desconexões em 10:38:47 (device 30), 10:38:58 (device 31), 10:39:28 (device 32) e re-enumeração em 10:38:56, 10:38:59 e 10:39:31. Durante a re-enumeração o udev remove o symlink `by-id`; a primeira tentativa de `dd` com `oflag=direct` falhou, e a **repetição automática** abriu o caminho já sem symlink, criando um arquivo regular dentro de `/dev` e gravando a imagem nele (em RAM), não no cartão.
- **Falhas / limitações:** o retry automático da v2 transformou uma falha de hardware em uma falsa confirmação de sucesso. A contagem de bytes do `dd` sozinha não prova que o alvo era o disco. O leitor apresenta desconexões intermitentes mesmo fora de carga de escrita;trocar apenas a porta não resolveu. Hipótese atual: leitor/cabo/contato do adaptador com falha; testar outro leitor e outro cartão antes de qualquer nova tentativa.
- **Rollback e estado final:** nenhum dado da TX9 foi alterado. O cartão segue com apenas os ~17 MiB da primeira tentativa + tabela de partições: **inutilizável para boot**. Arquivo espúrio de 3,4 GB em `/dev/disk/by-id/usb-Generic_Mass-Storage-0:0` precisa ser removido pelo operador (comando em `/tmp/opencode/armbian/...`, sem root para o agente). Nenhum boot tentado.
- **Gate aprovado?** NÃO (F1).
- **Próximo experimento:** (1) remover o arquivo regular: `sudo rm -f -- /dev/disk/by-id/usb-Generic_Mass-Storage-0:0`; (2) usar outro leitor de cartão e outra porta USB direta, ou outro cartão (16/32 GB); (3) executar script v3, que grava em `/dev/sdd` (nunca em caminho `by-id`), não repete automaticamente após desconexão e exige `blkid` com `vfat`/`ext4` antes de considerar a gravação concluída.

## Registro 006 — 2026-11-25 11:05 -03 — F1: gravação concluída e verificada

- **Fase:** F1 — concluída (gate SIM).
- **Objetivo / hipótese:** gravar a imagem Armbian no microSD de forma confiável após trocar o leitor/porta e corrigir o script.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64; alvo `/dev/sdd` via `/dev/disk/by-id/usb-Generic_Mass-Storage-0:0`; comando executado pelo operador com `sudo`. Nenhum comando executado na TX9.
- **Comandos executados (sem segredos):** `sudo bash /tmp/opencode/armbian/write-sd-v3.sh`.
- **Versões / hashes:** imagem `Armbian_26.11.0_amlogic_s905w_noble_6.12.117_server_2026.11.14.img.gz`, SHA-256 `de7440731ca4bec802ab97dba20dd4464d56de5d6ae2796cdef2ea674d77fd7f` (conferida novamente pelo script); 3.686.793.216 bytes após descompactar.
- **Resultado observado / evidência:**
  - `dd` concluiu `3686793216 bytes (3,4 GiB) copied, 314,9 s, 11,7 MB/s` sem erro; leitura lenta, porém estável — sem novas desconexões.
  - `lsblk` pós-gravação: `sdd1` 511M `vfat` com label `BOOT`; `sdd2` 2,9G `ext4` com label `ROOTFS`.
  - `uEnv.txt`: `LINUX=/zImage`, `INITRD=/uInitrd`, `FDT=/dtb/amlogic/meson-gxl-s905w-tx3-mini.dtb`, `APPEND=root=UUID=dd113b2d-8662-491b-bc1e-04f849968eb2 … console=ttyAML0,115200n8 …`.
  - `dtb/amlogic/meson-gxl-s905w-tx3-mini.dtb` presente (42.147 bytes); `u-boot.ext` ausente, conforme esperado. Boot contém `s905_autoscript`, `aml_autoscript`, `u-boot.sd`, `zImage`, `uInitrd`.
- **Falhas / limitações:** nenhuma nesta tentativa. A v3 gravou em `/dev/sdd` (nunca no symlink), não repetiu automaticamente após desconexão e exigiu `blkid` `vfat`/`ext4` antes de montar o boot somente-leitura.
- **Rollback e estado final:** cartão pronto para boot externo; nenhum dado da TX9 alterado.
- **Gate aprovado?** SIM (F1).
- **Próximo experimento:** operador desligar a TX9, inserir o cartão, conectar Ethernet e ligar. Se o Android iniciar, desligar e repetir mantendo o botão de reset pressionado. Localizar o lease DHCP do Armbian, entrar por SSH (`root`/`1234`) e trocar a senha imediatamente. Depois executar `scripts/diagnostics.sh` e as verificações read-only do `PLAN.md` (F2). Nenhuma alteração de eMMC/bootloader antes do F2.

## Registro 007 — 2026-11-25 — F2: tentativa de identificar o boot sem HDMI

- **Fase:** F2 — em andamento.
- **Objetivo / hipótese:** determinar se a TX9 iniciou Armbian ou Android sem depender do HDMI (conhecido como não confiável em `docs/hardware.md`).
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64 na mesma rede local da TX9. Nenhum comando executado na TX9; nenhum login tentado em outros dispositivos.
- **Comandos executados (somente leitura):** `ip neigh show dev enp8s0`; varredura de porta 22 em `192.168.0.0/24` via `/dev/tcp` com timeout; leitura do banner SSH de cada host; varredura das portas 23/80/443/5555/8008/8009/8080/9090 nos hosts encontrados; `avahi-resolve -n armbian.local`; `avahi-browse -at`; `adb connect` + `getprop` nos hosts com porta 5555 aberta.
- **Resultado observado / evidência:**
  - `armbian.local` não resolve por mDNS; `avahi-browse` não anuncia nenhum host Armbian/SSH.
  - Porta 22 aberta apenas em: este host (`SSH-2.0-OpenSSH_10.6`), `192.168.0.101` e `192.168.0.250` (`SSH-2.0-OpenSSH_10.0p2 Debian-7+deb13u4`) e `192.168.0.206` (`SSH-2.0-OpenSSH_6.6.0`). Nenhum banner corresponde ao OpenSSH do Armbian Noble esperado.
  - `192.168.0.101` e `192.168.0.250` também têm porta 5555 (ADB) aberta, mas `adb connect` retornou `device offline` em ambos — não foi possível identificá-los como a TX9.
  - `192.168.0.206` responde HTTP (22/80/443), com banner SSH antigo — provável outro aparelho da rede, não o servidor recém-instalado.
  - O cartão não está mais no leitor USB do host (`/dev/sdd` desapareceu), indicando que foi removido para inserção na TX9.
- **Falhas / limitações:** HDMI inoperante impede confirmação visual; não há acesso à tabela de DHCP do roteador a partir deste host. A varredura de porta é passiva (sem autenticação), mas não consegue distinguir dispositivos sem banner reconhecível.
- **Rollback e estado final:** nenhuma alteração feita; nenhum login tentado. Nenhum host Armbian detectado até o momento.
- **Gate aprovado?** NÃO (F2).
- **Próximo experimento:** operador deve desligar a TX9, ligar mantendo o botão de reset pressionado (o botão pequeno próximo à silk `OTG` visto nas fotos) por ~10–20 s, e então avisar. O agente repete a varredura de rede. Se ainda não houver host Armbian, trocar para cartão de 16/32 GB (risco SDXC) ou, em último caso, retirar o cartão e montar o rootfs somente-leitura no host para procurar evidências de boot/resize.

## Registro 008 — 2026-11-25 11:45 -03 — F2: por que o Android continua vencendo o boot

- **Fase:** F2 — em andamento.
- **Objetivo / hipótese:** identificar uma causa acionável para o boot continuar caindo no Android apesar de o cartão estar gravado e verificado, sem acesso a HDMI. Hipótese trabalhada: o script de boot da imagem espera `u-boot.ext` em alguns modelos; o FAQ oficial da Armbian cita explicitamente o TX3 Mini/S905W como exemplo de placa que precisa copiar `u-boot-s905x-s912.bin` para `u-boot.ext`.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64 (somente leitura) e resultado do operador na TX9. Nenhum comando executado na TX9; nenhuma alteração em eMMC/bootloader.
- **Versões / URLs / SHA-256:**
  - Documentação upstream consultada: `https://raw.githubusercontent.com/ophub/amlogic-s9xxx-armbian/main/documents/README.md` (seções 12.4.1 e 12.6) e `https://forum.armbian.com/topic/33676-installation-instructions-for-tv-boxes-with-amlogic-cpus/`.
  - `u-boot.ext` extraído da partição FAT da própria imagem (offset 4.194.304): 646.455 bytes, SHA-256 `207cdbe16145bea4602d62cde4c5e1083f30c5742beef714bec259d15c94545c`, equivalente a `u-boot-s905x-s912.bin` da release.
- **Comandos executados (sem segredos):** `ip neigh show`; varredura de porta 5555 em `192.168.0.0/24`; `mdir -i armbian.img@@4194304 ::/`; `mtype -i armbian.img@@4194304 ::/s905_autoscript.cmd`; `mcopy -i armbian.img@@4194304 ::/u-boot-s905x-s912.bin u-boot.ext`; `sha256sum u-boot.ext`.
- **Resultado observado / evidência:**
  - O operador confirmou: **\"the box booted android even when i pressed the button\"** — o botão/reset não alterou o resultado.
  - `192.168.0.101` e `192.168.0.250` compartilham o mesmo MAC `74:e6:e2:d6:5b:94` (OUI Dell Inc.); são o mesmo dispositivo Dell da rede, **não** a TX9. Não há ADB de Android da TX9 acessível (nenhum outro host responde na porta 5555).
  - A documentação da release ophub descreve `adb shell reboot update` como forma de forçar boot por SD/USB, mas exige depuração USB ativada no Android — impossível sem tela funcional neste momento.
  - Inspeção da própria imagem: `s905_autoscript.cmd` contém `if fatload mmc 0 0x1000000 u-boot.ext; then go 0x1000000; fi;` seguido do fallback que carrega kernel/dtb diretamente com o U-Boot antigo. `aml_autoscript.cmd` varre `mmc 0`, USB e eMMC e grava `bootfromsd`. O FAQ oficial recomenda copiar `u-boot-s905x-s912.bin` para `u-boot.ext` em TX3 Mini/S905W.
  - A documentação ophub, por sua vez, restringe `u-boot.ext` ao contorno de memória (`UBOOT_OVERLOAD`) e diz para não copiar u-boot para outros fins; portanto esta é uma **hipótese de experimento**, não uma conclusão.
- **Falhas / limitações:** o mecanismo exato do botão nesta PCB `B00-MX3mini-REV1.7` continua não comprovado; `PLAN.md` já o classifica como candidato, não garantia. Sem HDMI e sem ADB, a única observação disponível é a rede e, em último caso, UART.
- **Rollback e estado final:** nenhuma alteração no cartão ou na TX9 neste registro. Arquivos preparados no host: `/tmp/opencode/armbian/armbian.img` (cópia descomprimida, 3,5 GB), `/tmp/opencode/armbian/u-boot.ext` e `/tmp/opencode/armbian/add-uboot-ext.sh` (syntax check OK).
- **Gate aprovado?** NÃO (F2).
- **Próximo experimento:** operador remove o cartão da TX9, recoloca no leitor USB e executa `sudo bash /tmp/opencode/armbian/add-uboot-ext.sh`; o script grava apenas `u-boot.ext` na partição FAT e confirma o SHA-256. Em seguida, reinserir na TX9, ligar mantendo o reset pressionado por mais tempo e repetir a varredura de rede. Se ainda bootar Android, trocar para microSD de 16/32 GB (risco SDXC documentado) antes de considerar UART.

## Registro 009 — 2026-11-25 11:54 -03 — Reaproveitamento do cartão de 64 GB

- **Fase:** preparação de mídia (fora das fases F0–F7 do servidor).
- **Objetivo / hipótese:** transformar o microSD de 64 GB que continha a imagem Armbian em armazenamento comum (ROMs de emulação), conforme decisão do proprietário, antes de testar um cartão de 16 GB no boot.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64; alvo `/dev/sdd` via leitor USB GEMBIRD; comando executado pelo operador com `sudo`. Nenhum comando executado na TX9.
- **Versões / hashes:** `exfatprogs 1.4.5 (2026-11-18)`. Alvo confirmado pelo script: 63.864.569.856 bytes, `removable=1`, com `sdd1` vfat `BOOT` e `sdd2` ext4 `ROOTFS` — ou seja, o cartão Armbian e não o de 16 GB.
- **Comandos executados (sem segredos):** `sudo bash /tmp/opencode/armbian/format-roms-sd.sh` (wipe das assinaturas, nova tabela MBR com uma partição tipo 0x7, `mkfs.exfat -n ROMS /dev/sdd1`).
- **Resultado observado / evidência:**
  - `mkfs.exfat` concluiu: `Creating exFAT filesystem(/dev/sdd1, cluster size=131072)`, `Filesystem UUID: EFB7-F6C1`, `exFAT format complete!`.
  - `lsblk -f`: `sdd1` `exfat` versão `1.0`, label `ROMS`, UUID `EFB7-F6C1`; `blkid`: `LABEL="ROMS" UUID="EFB7-F6C1" BLOCK_SIZE="512" TYPE="exfat" PARTUUID="db7c3101-01"`.
  - Montagem somente-leitura verificada: raiz vazia (apenas `.` e `..`).
- **Falhas / limitações:** nenhuma. A imagem Armbian deste cartão foi apagada intencionalmente; o cartão não deve mais ser usado para boot até nova gravação.
- **Rollback e estado final:** cartão pronto para ROMs; TX9 intacta. O próximo boot usará outro cartão.
- **Gate aprovado?** SIM para o objetivo deste registro (mídia de dados); F2 permanece NÃO.
- **Próximo experimento:** operador insere o microSD de 16 GB no leitor; agente identifica o dispositivo somente-leitura e o operador executa `sudo bash /tmp/opencode/armbian/write-sd-16g.sh`, que grava a mesma imagem com hashes e verificações rígidas (destino `/dev/sdd`, sem retry automático, `blkid` vfat/ext4 obrigatório).

## Registro 010 — 2026-11-25 12:02 -03 — F1 em cartão de 16 GB: falha antes da gravação

- **Fase:** F1 — em andamento (nova tentativa com microSD de 16 GB).
- **Objetivo / hipótese:** repetir a gravação verificada da imagem em um cartão menor, para isolar o risco de boot de cartões SDXC >32 GB. Hipótese alternativa: o próprio leitor USB está causando falhas, independentemente do cartão.
- **Equipamento / sistema onde o comando rodou:** host CachyOS x86-64; leitor GEMBIRD `1908:0226`; alvo `/dev/sdd` (15,2 GiB / 16.358.834.176 bytes, `removable=1`, três partições não reconhecidas); comando executado pelo operador com `sudo`.
- **Comandos executados (sem segredos):** `sudo bash /tmp/opencode/armbian/write-sd-16g.sh`; leitura posterior de `/tmp/opencode/armbian/write-16g-failure-klog.txt` e verificação somente-leitura dos guards.
- **Resultado observado / evidência:**
  - Saída visível: apenas `Falha (codigo 1). Log do kernel salvo em /tmp/opencode/armbian/write-16g-failure-klog.txt`.
  - **Nenhum arquivo `/tmp/opencode/armbian/dd-write-16g.log` foi criado** — portanto o script parou antes do `dd`; o cartão não foi modificado nesta tentativa.
  - O kernel log registra desconexões repetidas do leitor mesmo sem escrita: 11:54:37 (usb 1-3), 11:58:07 (1-3), 12:00:06 (capacidade caiu para 0), 12:00:15 (1-3), 12:02:00 (1-9) e 12:02:19 (1-9, `Read Capacity(10) failed`, 0 blocos), com reenumeração em 1-8 às 12:02:23.
  - Verificação somente-leitura feita depois: imagem íntegra (SHA-256 `de7440731c…d77fd7f`), `/dev/sdd` com 16.358.834.176 bytes, `removable=1`, `by-id` ainda é symlink correto, nenhuma partição montada e todos os guards passam agora.
  - Para comparação, a gravação v3 bem-sucedida no cartão de 64 GB ocorreu em `usb 1-8` sem desconexões entre ~11:00 e 11:05.
- **Falhas / limitações:** sem a linha `ABORTADO:` completa do operador não é possível dizer qual guard específico disparou; a evidência de desconexões contínuas no momento da execução é a causa mais provável. O leitor GEMBIRD já havia mostrado o mesmo comportamento na F1 (Registros 004 e 005).
- **Rollback e estado final:** nenhuma alteração no cartão de 16 GB nem na TX9. Nenhum dado perdido.
- **Gate aprovado?** NÃO (F1 com o cartão de 16 GB).
- **Próximo experimento:** operador deve trocar o leitor de cartão (ou usar porta USB diferente e estável, de preferência a `1-8` que funcionou na v3), reconectar e pedir nova identificação somente-leitura. Antes de reexecutar, informar a linha `ABORTADO:` completa, se houver. Não repetir a gravação enquanto o leitor continuar se desconectando a cada ~2 minutos.

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
