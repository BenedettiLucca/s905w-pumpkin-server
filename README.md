# S905W Pumpkin Server

**Reaproveitando uma TV box Amlogic S905W como servidor Minecraft Java headless, com Linux ARM64 na eMMC e Pumpkin.**

> **Estado: planejamento.** Nenhum boot Linux, instalação na eMMC, disponibilidade de SSH ou execução de Pumpkin foi validado por este repositório inicial. O nome comercial do aparelho é **TX9**, mas o projeto é nomeado pelo **chipset**, pois o mesmo nome comercial é usado em diferentes placas.

## Hardware-alvo

| Componente | Estado conhecido |
|---|---|
| Placa | `B00-MX3mini-REV1.7`, baseada em revisão de hardware observada |
| SoC | chip marcado Amlogic S905W — confirmar em Linux/bootloader |
| CPU | esperado 4× Cortex-A53 ARM64; AArch64 ainda não testado |
| RAM | 2 GiB **estimados** por chips físicos; capacidade efetiva a confirmar |
| Armazenamento | eMMC SanDisk 16 GB; nó de bloco e boot ainda não testados |
| Conectividade | Ethernet, microSD; funcionamento com Linux ainda não testado |
| Vídeo/USB | HDMI com mau contato; **sem porta USB OTG física** para acesso de depuração |
| Display frontal | relógio/ícones; controlador não identificado (roadmap pós-MVP) |

## Objetivo do MVP

Boot sem microSD a partir da eMMC (Android substituído), acesso SSH via Ethernet, Pumpkin ARM64 iniciado automaticamente, conexão Minecraft Java na rede local, mundo persistente, benchmarks e backups recuperáveis. Sem consertar HDMI, instalar cluster ou publicar portas na Internet.

## Como começar

1. **Agentes de programação**: seguir as convenções permanentes de [`AGENTS.md`](AGENTS.md) e consultar as seções pertinentes de [`PLAN.md`](PLAN.md) ao trabalhar na instalação ou no experimento.
2. **Operador**: ler o protocolo detalhado em [`PLAN.md`](PLAN.md). Começar **somente pela Fase 0** (verificação de fontes e seleção de imagem/DTB).
3. Registrar todos os experimentos e decisões em [`docs/experiment-log.md`](docs/experiment-log.md), distinguindo fatos de hipóteses.
4. Avaliar hardware e riscos em [`docs/hardware.md`](docs/hardware.md); preservar os gates antes da escrita na eMMC.

**Fluxo pretendido:** pesquisa → microSD → boot Linux+SSH → eMMC → boot sem microSD → Pumpkin → benchmark → backup → [visor frontal](docs/front-panel.md) (opcional, depois).

## Fontes técnicas

- [ophub / amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian) e [releases](https://github.com/ophub/amlogic-s9xxx-armbian/releases)
- [Pumpkin](https://github.com/Pumpkin-MC/Pumpkin) e [documentação](https://docs.pumpkinmc.org/)
- [Linux OpenVFD](https://github.com/arthur-liberman/linux_openvfd) — pesquisa futura de visor

O perfil de instalação mais próximo relatado para S905W é **TX3 Mini / ID 111**, e não o **TX9 / ID 108 (S905X)**. Compatibilidade da nossa placa **não está provada**; revisar dados upstream antes de instalar.

## Publicação via GitHub CLI

O conector GitHub que originou este scaffold não oferecia criação de repositório. Após instalar/autenticar o `gh`, execute na pasta extraída:

```bash
cd s905w-pumpkin-server
git init -b main
git add .
git commit -m "chore: initialize S905W Pumpkin experiment"
gh repo create BenedettiLucca/s905w-pumpkin-server --public --source=. --remote=origin --push
```

Se desejar repositório privado, troque `--public` por `--private`. Este comando **não foi executado**; ele deve ser executado em uma máquina autenticada na conta desejada.
