# Pós-MVP — visor frontal da box S905W

> Ideia de aprimoramento **não implementada**. Só trabalhar após o sistema Linux na eMMC e o Pumpkin estarem estáveis.

## Objetivo

Reaproveitar o visor frontal de dígitos/ícones (horário, status de rede e outros) para status local do servidor, sem HDMI: relógio, temperatura de CPU, Pumpkin online/offline, jogadores conectados, uptime ou TPS se a informação estiver disponível e o formato do display permitir.

## Hipóteses de compatibilidade

- A comunidade Armbian / amlogic-s9xxx-armbian possui perfis de display para modelos da família TX3 Mini S905W, com integração de OpenVFD. Isso **não** garante que `B00-MX3mini-REV1.7` use o mesmo controlador, pinagem e device tree.
- Referência upstream: <https://github.com/arthur-liberman/linux_openvfd>.
- Verificar se a imagem usada realmente fornece `armbian-openvfd` e se o perfil 18 corresponde ao hardware; **não executar cegamente**.

## Plano experimental futuro

1. Inspecionar dispositivo driver, kernel logs, DTB, sysfs e barramento do painel com comandos somente leitura.
2. Testar apenas relógio/temperatura com driver específico e rollback documentado, sem comprometer boot/SSH/Pumpkin.
3. Descobrir as limitações dos dígitos e ícones (não presumir que letras, ícones ou decimais possam ser exibidos).
4. Integrar coleta mínima de Pumpkin: processo/systemd, jogadores online por API/query realmente suportada na release; TPS somente se houver métrica comprovada.
5. Criar um daemon opcional, com watchdog/fallback de horário e baixa frequência de atualização. Testar CPU/RAM e erros antes de habilitar no boot.

**Gate:** recursos de display nunca são pré-requisito do MVP; se falharem, servidor permanece funcionando sem display.
