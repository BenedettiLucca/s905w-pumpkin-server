# Inventário de hardware — placa S905W

> Atualizar somente com evidências. A inscrição TX9 é nome comercial, não identifica com segurança o SoC.

| Item | Informação | Grau de confirmação |
|---|---|---|
| PCB | `B00-MX3mini-REV1.7` | silk visível nas fotos de 2026-11-25 |
| Data de fabricação | silk `2250.` | hipótese: 2022, semana 50; não confirmado |
| SoC | marcado `S905W` | marcação física confirmada em foto; ID em boot pendente |
| CPU | 4× Cortex-A53 / AArch64 | esperado para S905W, não testado |
| RAM | ~2 GiB em quatro pacotes (dois por face) | estimativa física; marcação parcialmente legível (`D9PQL`); atribuição anterior a "Micron" não confirmada — ver `free -h` |
| eMMC | SanDisk `SDINAD(P/F)4-16G`, 16 GB | marcação física; letra intermediária ambígua na foto, capacidade `-16G` legível; identificar com `lsblk` |
| microSD | slot presente | boot não testado |
| Ethernet | porta RJ45 presente, na borda oposta às USB | driver/IP no Linux não testado |
| HDMI | mau contato mecânico | funcionamento intermitente relatado |
| OTG | silk `OTG` e pads sem conector populado | coerente com a nota do proprietário |
| Recovery/serial | botão redondo pequeno na face inferior, próximo ao silk `OTG`; fileira de pads não populados na borda | função/pinagem pendentes; não conectar VCC |
| Wi-Fi | antenna em PCB e conector U.FL com cabo | funcionalidade não testada |
| Display frontal | dígitos, relógio, ícones | controlador ainda não identificado |

## Dados a coletar após boot externo

- `uname -m`, `uname -a`, `/proc/device-tree/model` e `compatible`.
- `free -h`, `lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINTS`, `findmnt /`.
- Ethernet funcional/SSH e endereços (guardar detalhes sensíveis apenas localmente).
- Logs UART se necessário, sem conectar VCC e após validação de níveis de tensão.
- Temperatura CPU e leitura do sensor disponível.

Nunca escolher o destino de instalação por um nome de dispositivo assumido. Registrar evidência em `docs/experiment-log.md`.

## Fotos do proprietário — 2026-11-25

Duas fotos da placa (face dos componentes e face inferior) foram analisadas. **Elas não são versionadas**: a etiqueta da face inferior contém um endereço MAC, que é identificador de rede privado e não deve entrar em um repositório público. Somente as observações acima foram transcritas.

Na face dos componentes: S905W, eMMC SanDisk, capacitores e indutores ao redor do SoC, e as duas portas USB-A na borda inferior. Na face inferior: RJ45, uma segunda porta menor (alimentação/AV, não identificada), as duas portas USB-A, o botão redondo, o cabo de antenna U.FL, e quatro pacotes de memória (dois visíveis em cada face). A fileira de pads na borda direita pode ser UART, mas a pinagem não foi medida — não conectar VCC antes de validar níveis.
