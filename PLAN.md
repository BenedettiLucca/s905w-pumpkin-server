# Experimento TX9 → Linux na eMMC → Minecraft Pumpkin

> **Status:** PLANEJADO — nenhuma etapa deste documento implica que o hardware foi modificado ou que os testes passaram.
> **Data-base:** 24/11/2026  
> **Executor previsto:** agente de programação no OpenCode (modelo Tencent Hy4-flash) + operador humano para ações físicas  
> **Projeto sugerido:** `BenedettiLucca/s905w-pumpkin-server` (nome proposto; publicação no GitHub pendente)

## 0. Instruções para o agente executor

Você é o agente responsável por conduzir um experimento **reproduzível, incremental e baseado em evidências** para transformar uma TV box TX9 em servidor Minecraft doméstico permanente.

1. **Leia este documento inteiro** antes de agir. Comece inventariando o que está confirmado e o que é hipótese. Não apresente etapas planejadas como realizadas.
2. **Verifique as instruções upstream atuais** antes de escolher downloads, arquivos de boot, flags ou configurações. Documentação e releases podem mudar. Registre URLs, nome da imagem, SHA-256, versão do kernel e commit/release.
3. **Não presuma que TX9 = perfil TX9.** O SoC informado é S905W; no banco de modelos do ophub, `111 = TX3-Mini / S905W`, enquanto `108 = TX9 / S905X`. O perfil 111 é **candidato**, não validação da revisão da placa.
4. Ações físicas (inserir cartão, pressionar botão, trocar cabo, alimentar placa) são executadas pelo operador; o agente deve fornecer passos concretos e aguardar resultados. **Nunca finja ter executado comandos no dispositivo** sem logs reais.
5. **O proprietário autorizou substituir integralmente o Android na eMMC**; não precisa preservar o Android nem consertar o HDMI. Mesmo assim, só grave o armazenamento interno **depois de um boot Linux funcional por microSD e inspeção dos dispositivos** — isso evita apagar discos errados e erros de seleção do bootloader.
6. Antes de qualquer operação destrutiva, apresente **o dispositivo de destino, a evidência que o identifica, o comando específico e seu efeito** para o operador autorizar. Não use `dd` na eMMC, não force flash de U-Boot genérico e não execute scripts remotos sem revisão.
7. Se uma fase falhar, capture evidências, apresente causa provável e próximos testes reversíveis. **Não avance automaticamente** para a fase seguinte.
8. Priorize **MVP funcional** antes de otimização, cluster, dashboards ou customizações. Só incorpore extras após o servidor Minecraft funcionar e sobreviver a reinicializações.
9. Trabalhe preferencialmente em português; commits e nomes de arquivos podem ser em inglês.
10. Documente observações de execução em `docs/experiment-log.md`, usando timestamps, resultados, versões, logs sanitizados e decisões.

## 1. Objetivo e hipótese

**Objetivo principal:** transformar definitivamente a TX9 em servidor Linux headless para **Minecraft Java via Pumpkin**, instalado na **eMMC interna**, inicializado automaticamente após ligar e administrado exclusivamente pela rede local/SSH.

**Hipótese H1:** a placa identificada como `B00-MX3mini-REV1.7`, com Amlogic da família S905W e 16 GB de eMMC, consegue executar uma imagem Linux ARM64 usando um DTB/bootloader compatível com TX3 Mini S905W, e depois fazer boot sem cartão SD.

**Hipótese H2:** um build Linux AArch64 do Pumpkin consegue iniciar, aceitar conexões Minecraft Java e operar de modo minimamente jogável com 1 jogador; 2–3 jogadores são objetivo exploratório, **não promessa de desempenho**.

**Entrega MVP (definition of done):** boot pela eMMC sem microSD + SSH + serviço Pumpkin iniciado automaticamente + cliente Minecraft Java conectando na LAN + logs de desempenho e reinicialização + instruções de reprodução.

### Fora do escopo inicial

- Reparar HDMI ou restaurar Android.
- Habilitar USB OTG soldando conectores; a serigrafia `OTG` representa apenas contato na placa, não uma porta existente.
- Kubernetes, cluster entre TV boxes, Minecraft Bedrock, plugins WASM, mods, overclock, configuração pública de internet, hosting multiusuário ou produção 24/7 sem avaliação.
- Compilar kernel ou U-Boot customizado **antes** de demonstrar necessidade.

## 2. Inventário — fatos, hipóteses e restrições

| Item | Situação | Evidência / comentário |
|---|---|---|
| Aparelho comercial | TX9 | Informado pelo proprietário |
| Revisão PCB | `B00-MX3mini-REV1.7` | Serigrafia visível nas duas faces da placa |
| SoC | Amlogic marcado `S905W` | Inscrição física; confirmar identificador real por boot/logs quando possível |
| CPU | 4× Cortex-A53, ISA ARMv8-A | Esperado para S905W; validar execução AArch64 |
| GPU | Mali-450 (família S905W) | Irrelevante para servidor headless |
| RAM | **2 GiB estimados** | Quatro chips Micron DDR3L (2 por face); quantidade utilizável pelo bootloader **não confirmada** |
| Armazenamento | SanDisk `SDINADF4-16G`, **16 GB eMMC** | Inscrição física no chip; identificar bloco real no Linux |
| HDMI | Conector com mau contato mecânico; imagem só em posição específica | Não consertar; opcionalmente aproveitar imagem temporária para debug, jamais obrigatório |
| USB OTG externo | **Inexistente** | Apenas pad/serigrafia OTG, não caminho operacional |
| ADB por rede | Não oferecido nas configurações Android | Não depender de ADB |
| microSD | Slot físico presente | Principal caminho inicial de boot e instalação |
| Ethernet | Conector presente | Funcionalidade com Linux ainda não validada |
| Recovery/reset | Pequeno botão tátil na placa | Função de recovery/multiboot ainda não comprovada |
| UART | Possíveis pads `GND/TX/RX/VCC` | Pinagem elétrica exata não confirmada; rota de diagnóstico opcional |
| Sistema alvo | Linux ARM64 Server (preferência Debian/Armbian comunitário) | Usar imagem específica de família S905W, verificar compatibilidade |
| Software alvo | Pumpkin, servidor Minecraft em Rust | Build ARM64 oficial existe; Docker experimental |

**Nota importante:** a inscrição `S905W` não garante por si só que a variante interna seja exatamente essa; há placas genéricas com revisões discrepantes. Se uma evidência posterior contradizer o inventário, **revisar a escolha de DTB e bootloader** antes de escrever na eMMC.

## 3. Dependências e preparação

### Hardware

- Desktop CachyOS para preparar mídia, identificar cartões e acessar SSH.
- Leitor de microSD e **microSD confiável de 16 GB ou mais**, preferencialmente 32 GB.
- Cabo Ethernet e fonte original da TX9 em condições estáveis.
- Acesso à lista DHCP do roteador ou scanner de LAN.
- Recomendado, se o boot falhar sem imagem: adaptador USB–UART de **lógica 3,3 V**, com níveis/pinagem validados antes de ligar. **Não conectar VCC**.
- Opcional após MVP: Talos (Debian) como destino de backups.

### Software/recursos

- Firmware comunitário: https://github.com/ophub/amlogic-s9xxx-armbian
- Releases: https://github.com/ophub/amlogic-s9xxx-armbian/releases
- Banco de placas: https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/build-armbian/armbian-files/common-files/etc/model_database.conf
- Pumpkin: https://github.com/Pumpkin-MC/Pumpkin
- Quick Start: https://docs.pumpkinmc.org/
- Configuração Pumpkin: https://docs.pumpkinmc.org/config/basic
- Administração/recursos: https://docs.pumpkinmc.org/admin/server-hosters

**Reprodução:** registrar em `docs/experiment-log.md` a URL exata e o checksum do artefato baixado. **Não fixar links/tag de release presumidos**; confirmar o arquivo real disponível antes do download.

## 4. Estrutura sugerida do repositório

```text
s905w-pumpkin-server/
├── README.md                    # Status real e links para o plano
├── AGENTS.md                    # Regras operacionais do agente OpenCode
├── PLAN.md                      # Este protocolo experimental
├── docs/
│   ├── hardware.md              # Fotos próprias, chip markings, RAM/eMMC, board revision
│   ├── experiment-log.md        # Histórico de tentativas, logs, versões, evidências
│   ├── boot-and-emmc.md         # Imagem, DTB, bootloader, instalação e recovery
│   ├── performance.md           # TPS, memória, CPU, temperatura, jogadores
│   ├── troubleshooting.md       # Falhas e testes reproduzíveis
│   └── front-panel.md           # Futuro visor LED/VFD após MVP
├── config/
│   └── pumpkin.toml.example     # Template SEM senhas ou dados privados
├── deploy/
│   ├── compose.yaml             # Criar apenas após validar Docker ARM64
│   └── pumpkin.service          # Alternativa systemd/native, se necessária
├── scripts/
│   ├── diagnostics.sh           # Somente leitura
│   ├── benchmark.sh             # Somente leitura e métricas
│   └── backup-world.sh          # Criar/testar após MVP
├── .gitignore
└── LICENSE                      # Escolher licença só para código e documentação autorais
```

**Sugestão:** começar com `README.md`, `AGENTS.md`, `PLAN.md`, `docs/experiment-log.md` e `scripts/diagnostics.sh`. Criar o restante sob demanda, não como obrigação burocrática.

## 5. Plano por fases e gates

### Fase 0 — Pesquisa, reprodução e identificação (sem escrever no hardware)

**Tarefas**

1. Consultar upstream e validar imagem ARM64 para S905W; confirmar se o arquivo contém um ambiente Server sem GUI.
2. Ler `model_database.conf`: comparar perfil `111 / TX3-Mini / s905w / meson-gxl-s905w-tx3-mini.dtb` e perfil `108 / TX9 / s905x`, documentando o motivo da escolha.
3. Ler documentação da imagem selecionada e confirmar o boot config **real** (`uEnv.txt`, `FDT=`) e se é necessário configurar `u-boot.ext` a partir de `u-boot-s905x-s912.bin`. Não assumir que todas as releases tenham layout idêntico.
4. Preparar `docs/experiment-log.md` com campos: data, imagem, checksum, DTB, método de multiboot, resultado, IP SSH, kernel, RAM, eMMC, Ethernet, temperaturas.

**Gate F0:** o agente identifica **qual imagem exata** gravar, qual DTB usar, como efetuar o boot externo e evidencia as fontes. Não executar instalação interna ainda.

### Fase 1 — Gravação do microSD (ação destrutiva apenas no cartão)

No CachyOS, listar dispositivos **antes e depois** de inserir o cartão:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS
sha256sum NOME_DA_IMAGEM.img.gz   # comparar com checksum oficial, se publicado
```

Gravar pelo Balena Etcher (preferível pela verificação) ou, após **confirmar explicitamente o dispositivo**, usar:

```bash
# Exemplo: /dev/sdX é placeholder, não executar sem identificar o cartão.
gzip -dc NOME_DA_IMAGEM.img.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Ajustar arquivos do boot **somente conforme a release escolhida**. O primeiro DTB candidato, caso presente, é:

```ini
FDT=/dtb/amlogic/meson-gxl-s905w-tx3-mini.dtb
```

Para imagens do ophub que requeiram um U-Boot auxiliar, consultar a instrução da **mesma release** antes de copiar `u-boot-s905x-s912.bin` para `u-boot.ext`. Registrar se a cópia foi necessária.

**Gate F1:** o cartão foi gravado no dispositivo correto, a partição de boot é legível, os arquivos selecionados existem, e o conteúdo gravado está documentado.

### Fase 2 — Boot externo e acesso headless

1. Desenergizar TX9, inserir microSD, conectar Ethernet.
2. Testar botão físico de reset/recovery **somente depois de verificar sua função** (método conhecido como *toothpick* é candidato, não garantia). Aplicar alimentação e observar a rede.
3. Inspecionar DHCP no roteador e/ou usar `ip neigh` / `nmap -sn SUBREDE/24` no desktop; não presumir IP.
4. Se o firmware do ophub usar as credenciais iniciais documentadas `root / 1234`, alterar senha no primeiro login.
5. Coletar comandos de somente leitura:

```bash
uname -a
uname -m
cat /proc/device-tree/model 2>/dev/null | tr -d '\000'; echo
free -h
lsblk -o NAME,SIZE,TYPE,MODEL,FSTYPE,MOUNTPOINTS
findmnt /
ip -br addr
ip route
dmesg | grep -Ei 'mmc|emmc|meson|eth|thermal|error|fail' | tail -n 100
for f in /sys/class/thermal/thermal_zone*/temp; do echo "$f: $(cat "$f")"; done
```

**Gate F2 (obrigatório antes da eMMC):** acesso SSH estável por Ethernet, `uname -m` igual a `aarch64`, raiz do Linux identificada como microSD, memória detectada e eMMC interna identificada de forma inequívoca. O sistema deve permanecer ligado por pelo menos 30 minutos sem travar. **Não exigir exatamente 2 GiB para seguir:** se só ~1 GiB aparecer, documentar e avaliar viabilidade/DTB antes de decidir.

**Se falhar:** capturar sintoma. Verificar bootloader/multiboot, DTB e rede. UART é última rota de observabilidade; **não realizar gravação às cegas**.

### Fase 3 — Instalação **definitiva** na eMMC (Android descartável)

**Pré-condições:** F2 aprovado + operador confirmou que o armazenamento identificado é a SanDisk eMMC interna de ~16 GB, e não o microSD nem outro disco.

1. Registrar `lsblk`, `findmnt /`, `blkid` e `dmesg` relevantes antes da mudança.
2. Confirmar que o instalador da imagem é **o do ophub** (`command -v armbian-install`) e revisar a ajuda/versão atual.
3. Entrar no instalador em sessão SSH:

```bash
sudo armbian-install
```

4. Caso apareça seleção de modelo, **perfil candidato: `111` TX3-Mini (S905W)**, não `108` TX9 (S905X). Conferir a tabela da versão **instalada** do `model_database.conf` — o número pode mudar entre releases.
5. Preferir o comportamento padrão documentado do instalador (`-m no`, `-a yes`), **sem forçar U-Boot mainline** ou outros modos experimentais sem justificativa e evidência.
6. Capturar log da instalação e códigos de erro; não tentar reparticionar ou sobrescrever setores manualmente se o script falhar.
7. Quando terminar com sucesso:

```bash
sync
sudo poweroff
```

8. Retirar o microSD com o aparelho desligado; ligar somente pela alimentação e Ethernet.
9. Reconectar por SSH; comprovar que o `/` agora está montado em partição da eMMC, com `findmnt /`, `lsblk -f`, `mount`.
10. Repetir o teste de reboot/desligar-ligar pelo menos duas vezes.

**Gate F3:** TX9 inicia **pela eMMC sem microSD**, responde por SSH e tem Ethernet e armazenamento persistentes. O Android não é exigido como opção de recuperação.

**Riscos aceitos:** possível falha de boot após flash, possível necessidade de UART/gravador externo, desgaste/perda de dados na eMMC. **Riscos não aceitos:** gravar dispositivo não identificado ou alterar bootloader arbitrariamente por tentativa e erro.

### Fase 4 — SO enxuto e segurança mínima

1. Criar usuário administrativo próprio; habilitar chave SSH e verificar login antes de restringir autenticação por senha.
2. Configurar hostname simples, horário correto (NTP), atualizações Debian/Armbian e IP previsível via reserva DHCP no roteador.
3. Desativar serviços desnecessários **somente após medir**; não remover serviços críticos de boot, Ethernet ou SSH.
4. Usar Ethernet, não Wi-Fi. Não expor SSH/porta 25565 ao público nesta fase.
5. Monitorar estabilidade com `journalctl -b`, `dmesg`, `free`, `df -h` e temperaturas.

**Gate F4:** SSH com chave e usuário não-root funcionando, persistência após reboot e LAN acessível. Guardar um registro do estado do sistema.

### Fase 5 — Pumpkin (prioridade: binário nativo ARM64; Docker como alternativa)

**Justificativa:** o Pumpkin publica binários oficiais Linux `aarch64`; isso elimina a necessidade de portar o aplicativo a ARMv7. Docker é opcional e o próprio projeto o classifica como experimental. Em hardware de ~2 GB, começar pelo **binário nativo com systemd** reduz uma variável de depuração. Se a disponibilização do binário falhar, comparar com Docker ARM64.

**Trilha A, preferida — binário nativo:**

1. Conferir em `https://pumpkinmc.org/download/` a release Linux ARM64/AArch64 e sua integridade.
2. Copiar para diretório isolado (ex.: `/opt/pumpkin` para binário, `/var/lib/pumpkin` para mundo/config); usar usuário de sistema dedicado, sem privilégios.
3. Executar uma primeira vez no terminal para gerar/configurar `pumpkin.toml`. Verificar diretório de trabalho e permissões.
4. Configurar o processo com **systemd**, dependência de rede, reinício em falhas e diretório de dados persistente. Manter unidade versionada no repositório; não inventar flags CLI sem consultar `--help`.

**Trilha B — Docker experimental:** verificar suporte `linux/arm64` no manifesto antes de baixar:

```bash
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo docker manifest inspect ghcr.io/pumpkin-mc/pumpkin:master
```

Se a imagem fornecer `linux/arm64`, testar com bind mount persistente conforme a documentação oficial:

```bash
sudo mkdir -p /srv/pumpkin
sudo docker run --name pumpkin --rm -it \
  -p 25565:25565/tcp \
  -v /srv/pumpkin:/pumpkin \
  ghcr.io/pumpkin-mc/pumpkin:master
```

**Não habilitar reinício automático ou abrir firewall externo antes de confirmar que a instância inicia e que seus dados persistem.** Depois transformar em Compose versionado ou systemd com imagem/digest pinados. Validar usuário/permissões no volume e consumo de memória; se houver OOM, comparar com a trilha nativa.

**Configuração experimental do `pumpkin.toml`:** confirmar esquema na versão instalada. A documentação atual define campos em `[networking.java]`:

```toml
[networking.java]
enabled = true
address = "0.0.0.0:25565"
max_players = 2
view_distance = 4
simulation_distance = 3
online_mode = true

[networking.bedrock]
enabled = false

[plugins]
enabled = false
```

> Este bloco **não é necessariamente um arquivo TOML completo**: editar as seções correspondentes no arquivo gerado pelo Pumpkin, preservando outras configurações válidas. Desativar Bedrock e plugins no MVP. Manter autenticação online; não usar `online_mode = false` para contornar falhas.

**Gate F5:** Pumpkin sobe sem erro, aceita `Minecraft Java → IP_DA_TX9:25565` na LAN, permite entrar no mundo, reinicia via serviço e persiste dados após reboot.

### Fase 6 — Experimento de desempenho (não otimizar antes da linha de base)

**Variáveis controladas:** mesma release/kernel, seed/mundo, configurações, região/itinerário, modalidade de teste, número de jogadores; registrar temperatura ambiente quando disponível. Testar com **mundo novo** e, separadamente, **chunks já gerados**; não confundir geração de mundo com operação em idle.

| Cenário | Duração sugerida | O que medir |
|---|---|---|
| S0 — Linux sem Pumpkin | 10 min | RAM, CPU em idle, temperatura, consumo opcional |
| S1 — Pumpkin sem jogadores | 15 min | RAM RSS, CPU, logs, tempo até ficar pronto |
| S2 — 1 jogador parado em região pré-gerada | 15 min | TPS/MSPT, RSS, CPU, temperatura |
| S3 — 1 jogador explorando novos chunks | 15 min | quedas de TPS, latência, I/O, estabilidade |
| S4 — 2 jogadores, região pré-gerada | 15 min | TPS/MSPT e jogabilidade, OOM/throttling |
| S5 — 2 jogadores explorando (opcional) | 15 min | pior caso com geração de chunks |
| S6 — endurance | 12–24 h | reinícios inesperados, erros I/O, memória, temperaturas |

> Se os comandos `tps`/`tick query` mudarem, buscar o método equivalente na versão real. **Nunca inventar medições de TPS** a partir apenas de CPU/RAM.

**Critérios para MVP (alvos experimentais, não garantias):**

- Servidor operacional com **1 jogador**, conexões estáveis, sem corrupção do mundo, OOM killer ou kernel panic.
- Ideal: próximo de 20 TPS na maior parte do S2; resultado abaixo disso deve ser registrado, não mascarado.
- Sem throttling severo contínuo ou temperatura fora da faixa segura do SoC.
- Dados persistentes após pelo menos 2 reinicializações; serviço auto-start funcional.
- Teste S4 serve para definir capacidade real; **2–3 jogadores não são requisito de aprovação**.

**Instrumentação mínima:** `top`/`htop`, `free -m`, `vmstat 1`, `iostat` (sysstat), `journalctl`, `dmesg`, arquivos `/sys/class/thermal/.../temp`, métricas do Pumpkin e `time` quando aplicável. Informar se a leitura térmica está em miligraus Celsius e converter corretamente.

**Otimização somente após S0–S4:** variar **uma coisa por vez**: view distance, simulation distance, pré-geração de chunks se suportada, memória limite, serviços em segundo plano, governor e cooling. Antes de qualquer alteração de kernel/clock, salvar baseline e reversão.

### Fase 7 — Operação mínima e backups

1. Fixar versão/digest do Pumpkin usado no MVP; não depender indefinidamente de `:master` e atualização automática.
2. Definir método de **shutdown limpo do Pumpkin** antes de backup; não copiar mundo durante gravações sem mecanismo consistente de snapshot/flush.
3. Guardar backups fora da eMMC da TX9 — preferência Talos via SSH/rsync/restic — e testar uma restauração num diretório de teste.
4. Reservar IP no DHCP e registrar endereço de LAN sem publicar informações sensíveis no GitHub público.
5. Proteger acesso do Minecraft (whitelist de jogadores conhecidos) e restringir exposição à LAN/Tailscale. Port forwarding público fica para uma futura decisão, após avaliar CGNAT, autenticação e manutenção.
6. Definir rotina de reboot e recuperação para perda de energia.

**Gate F7:** servidor religa sozinho, mundo recuperável de backup verificado e manual de operação documentado.

## 6. Árvore de decisão para falhas

```text
Imagem gravada no SD
  ├─ Não aparece na rede
  │   ├─ Verificar fonte, Ethernet, DHCP, botão recovery e multiboot
  │   ├─ Verificar DTB/FDT e u-boot.ext conforme release
  │   └─ Se ainda falhar, coletar console UART (sem VCC) antes de ações destrutivas
  └─ SSH funciona
      ├─ Não é AArch64 → interromper Pumpkin ARM64 e revisar boot/SoC
      ├─ eMMC não aparece → investigar kernel/DTB, NÃO rodar instalador
      └─ eMMC presente, Ethernet OK → instalar com armbian-install
          ├─ Falha durante instalação → guardar logs, não usar dd cegamente
          └─ Sucesso
              ├─ Não boota sem SD → analisar U-Boot / UART / versão do instalador
              └─ Boot por eMMC + SSH OK → iniciar Pumpkin
                  ├─ Binário não inicia → arquitetura, libc, permissões, logs
                  ├─ Docker falha → testar binário nativo
                  └─ Servidor entra → benchmark → operação
```

## 7. Critérios de conclusão e entregáveis

### Obrigatórios para encerrar o experimento como **SUCESSO**

- [ ] Hardware identificado e diferenças da placa registradas.
- [ ] Versão/artefato/checksum do Armbian anotados.
- [ ] DTB/bootloader escolhidos e fonte da decisão registrados.
- [ ] Boot provisório por microSD validado com Ethernet e SSH.
- [ ] Instalação e boot **sem microSD** pela eMMC demonstrados.
- [ ] Pumpkin ARM64 inicia automaticamente e aceita conexão de cliente Minecraft Java.
- [ ] Teste com 1 jogador e medição básica de TPS/RAM/CPU/temperatura realizados.
- [ ] Logs, instruções, limitações e restauração de backup documentados.
- [ ] README atualizado com status **real** e problemas remanescentes.

### Entregáveis técnicos no GitHub

1. `README.md`: propósito, hardware, estado real, limitações, instruções de reprodução e troubleshooting.
2. `PLAN.md`: protocolo versionado.
3. `docs/experiment-log.md`: evidências e histórico de tentativas.
4. `docs/boot-and-emmc.md`: comandos efetivamente aplicados e resultado do flash.
5. `docs/performance.md`: metodologia e medições reais, incluindo cenários sem sucesso.
6. Configuração mínima e automatização de inicialização (systemd ou Docker), somente após validação.

## 8. Princípios de colaboração no OpenCode

- **Uma fase = um conjunto pequeno de commits.** Não avançar se o gate falhou.
- **Evidência acima de conjectura:** anexar saída de comandos e indicar origem dos números.
- **Automatizar somente o que é reproduzível e seguro**; scripts de diagnóstico, logs e configuração são preferíveis a flasher próprio.
- **Não criar infraestrutura extra** (K8s, UI, painel web) para provar o conceito.
- Se houver conflito entre documentação antiga e repositório upstream atual, registrar o conflito e justificar a solução.
- Abrir issues futuras para melhorias, sem desviar do MVP.
- Nunca commitar senhas, chaves SSH privadas, mundo com dados pessoais, identificadores privados de rede ou dumps do Android sem revisão.

### Primeira ação solicitada ao agente

> Leia `PLAN.md`. Faça **apenas a Fase 0**: verifique as fontes upstream atuais, escolha e justifique a imagem Armbian S905W ARM64 Server, identifique o DTB e o mecanismo de `u-boot.ext`/multiboot apropriados à PCB `B00-MX3mini-REV1.7`, registre as hipóteses e prepare os arquivos `README.md` e `docs/experiment-log.md`. Traga um checklist exato para gravar **somente o microSD**. **Não execute ações na eMMC, não tente instalar Pumpkin e não presuma que SSH já funciona.** Continue para F1 apenas após o operador confirmar o dispositivo de cartão identificado.

## 9. Fontes primárias / pontos de verificação

- `ophub/amlogic-s9xxx-armbian` (instalação eMMC, argumentos e plataforma): https://github.com/ophub/amlogic-s9xxx-armbian
- Lista de suporte/modelos (perfil 111 TX3-Mini S905W vs 108 TX9 S905X): https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/build-armbian/armbian-files/common-files/etc/model_database.conf
- Releases Armbian: https://github.com/ophub/amlogic-s9xxx-armbian/releases
- Documentação Pumpkin (Docker experimental): https://docs.pumpkinmc.org/
- Administração Pumpkin (ARM64, limites de memória, sem RCON legado): https://docs.pumpkinmc.org/admin/server-hosters
- Configuração Pumpkin TOML (`[networking.java]`): https://docs.pumpkinmc.org/config/basic
- Releases Pumpkin: https://github.com/Pumpkin-MC/Pumpkin/releases

**Plano-base:** 24/11/2026. Nome do repositório adaptado para `s905w-pumpkin-server`. Revalidar comandos e links antes de executar.
