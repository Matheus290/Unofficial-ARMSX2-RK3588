# Tutorial: ARMSX2 Nightly oficial + malisx2 no ROCKNIX

*[English version](TUTORIAL-ROCKNIX.md)*

Este guia instala a **versão nightly oficial do ARMSX2** junto com o driver Vulkan **malisx2**. Ao final, ela aparece como mais um emulador de PS2 no EmulationStation do ROCKNIX. Leva uns 10 minutos.

O ROCKNIX ainda vem com uma versão antiga do ARMSX2, que não tem suporte ao malisx2. Este instalador serve para usar a versão nova enquanto o ROCKNIX não a inclui oficialmente.

> O **instalador** é um script não oficial deste repositório. O **emulador** e o **malisx2** são baixados sem nenhuma modificação dos repositórios oficiais: [ARMSX2/ARMSX2](https://github.com/ARMSX2/ARMSX2/releases) e [bmdhacks/malisx2](https://github.com/bmdhacks/malisx2/releases).
>
> Testado **apenas** no ROCKNIX 20261001, numa Orange Pi 5 (RK3588, Mali-G610), com o driver de GPU **libmali**.

---

## O que você precisa

- Um aparelho com GPU **Mali** e **ROCKNIX** instalado. Foi testado só no RK3588; em outros chips, o instalador funciona, mas o malisx2 pode não ser compatível.
- O ROCKNIX usando o driver de GPU **libmali**, não o Panfrost (veja o Passo 1). O malisx2 roda sobre o driver de kernel da Arm, que só existe no modo libmali.
- O aparelho **conectado à internet**, na mesma rede que o seu computador.
- Um **computador** (Windows, macOS ou Linux) para acessar o aparelho pela rede.
- O **BIOS do PS2**, extraído do seu próprio console. Não incluímos o BIOS.
- Seus **jogos de PS2** (`.iso`, `.chd`, `.cso`…).

---

## Passo 1: conferir o driver de GPU do ROCKNIX

1. No EmulationStation, aperte **Start** → **SYSTEM SETTINGS**.
2. Procure a opção **GPU DRIVER** e deixe em **libmali**.
3. Se precisou trocar, a mudança só vale depois de reiniciar: **Start** → **QUIT** → **REBOOT**.

Para conferir por SSH (Passo 4), o arquivo `/dev/mali0` precisa existir: `ls /dev/mali0`.

---

## Passo 2: ligar o SSH e descobrir o IP

1. No EmulationStation, aperte **Start** → **NETWORK SETTINGS** e ligue **ENABLE SSH**. Em algumas versões, a opção fica em **SYSTEM SETTINGS → NETWORK SERVICES**.
2. Anote o **endereço IP** do aparelho, por exemplo `192.168.0.50`. Ele aparece nas configurações de rede ou em **INFORMATION**.

> Dica: muitas redes também aceitam o nome do aparelho em vez do IP, como `rocknix.local` ou `RK3588.local`.

---

## Passo 3: colocar o BIOS e os jogos

Se você já usa outro emulador de PS2 no ROCKNIX, isso provavelmente já está feito: pule para o Passo 4.

1. No menu de rede, ligue **ENABLE SAMBA**.
2. No computador, abra a pasta compartilhada:
   - **Windows:** no Explorador de Arquivos, digite `\\192.168.0.50` (troque pelo seu IP) na barra de endereço.
   - **macOS:** no Finder, menu *Ir → Conectar ao Servidor*, e digite `smb://192.168.0.50`.
   - **Linux:** no gerenciador de arquivos, digite `smb://192.168.0.50`.
   - Se pedir login, use usuário `root` e senha `rocknix`.
3. Copie os arquivos:
   - **BIOS do PS2** → `roms/bios/PS2/` (crie a pasta `PS2` se ela não existir)
   - **Jogos de PS2** → `roms/ps2/`

---

## Passo 4: entrar no aparelho por SSH

1. Abra um terminal no computador:
   - **Windows:** **PowerShell** (procure "PowerShell" no menu Iniciar).
   - **macOS:** o app **Terminal**.
   - **Linux:** o terminal da sua distribuição.
2. Digite o comando abaixo, trocando pelo seu IP, e aperte Enter:

   ```sh
   ssh root@192.168.0.50
   ```

3. Na primeira vez, ele pergunta se você confia no aparelho: digite `yes` e aperte Enter.
4. A senha é **`rocknix`**. Nada aparece na tela enquanto você digita a senha; isso é normal. Aperte Enter.

Quando aparecer algo como `RK3588:~ #`, você está dentro do aparelho.

---

## Passo 5: instalar

Copie e cole este comando no terminal e aperte Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/Matheus290/Unofficial-ARMSX2-RK3588/rk3588/nightly/install.sh | sh
```

O instalador:

- baixa a **nightly mais recente do ARMSX2** (a versão Qt para Linux arm64) e instala em `/storage/armsx2-nightly-qt`;
- baixa a **versão mais recente do malisx2**, confere o checksum e o deixa **selecionado** no ARMSX2. Esse driver aparece em *Settings → GPU Drivers*;
- adiciona o **armsx2-nightly** à lista de emuladores do PS2 no EmulationStation, **sem remover** os emuladores que você já tem;
- coloca **Start ARMSX2 Nightly** no menu **Tools**;
- na primeira instalação, já deixa tudo configurado:
  - BIOS em `roms/bios/PS2` e jogos em `roms/ps2`;
  - memory cards em `roms/saves/ps2`, compartilhados com os outros emuladores de PS2;
  - controle mapeado;
  - Vulkan com resolução 2x, widescreen e MTVU ligados.

No final, ele mostra **Done**. Pode fechar o terminal.

---

## Passo 6: reiniciar o EmulationStation

No aparelho, aperte **Start** → **QUIT** → **RESTART EMULATIONSTATION**. Reiniciar o aparelho também serve.

---

## Passo 7: escolher o ARMSX2 Nightly como emulador do PS2

**Para todos os jogos de PS2:**

1. Aperte **Start** → **GAME SETTINGS** → **PER SYSTEM ADVANCED CONFIGURATION** → **PlayStation 2**.
2. Em **EMULATOR**, escolha **armsx2-nightly**.

**Só para um jogo:**

1. Na lista de jogos do PS2, selecione o jogo e abra as opções dele (em geral com o botão **Select**). Vá em **ADVANCED GAME OPTIONS**.
2. Em **EMULATOR**, escolha **armsx2-nightly**.

Agora é só abrir o jogo pela lista, como qualquer outro.

---

## Passo 8 (recomendado): escanear os jogos pelo menu Tools

1. Abra **Tools → Start ARMSX2 Nightly**. O emulador abre na lista de jogos dele, sem iniciar nenhum jogo.
2. Em **Settings → Game List**, escolha **Scan For New Games**. Faça isso também sempre que adicionar jogos novos. Ali também dá para baixar as capas.
3. Para conferir o driver, entre em **Settings → GPU Drivers**: o **malisx2** deve estar selecionado.
4. Feche o emulador.

---

## Controles

O primeiro controle já vem mapeado.

| Ação | Botões |
|---|---|
| Abrir o menu do emulador | **L3 + R3** (aperte os dois analógicos) |
| Acelerar (segurar) | **L2 + R2** |
| Salvar estado | **Guide/Home + R1** |
| Carregar estado | **Guide/Home + L1** |

Para **sair do jogo**, abra o menu (L3 + R3) e escolha a opção de fechar o jogo. O atalho de sair do ROCKNIX (em geral **Select + Start**) também funciona.

---

## Atualizar

Rode o mesmo comando do Passo 5. Ele baixa a nightly e o malisx2 mais recentes, se houver versão nova. Suas configurações, memory cards e save states ficam como estão. Se você escolheu outro driver em *GPU Drivers*, o instalador respeita a sua escolha.

## Desinstalar

Por SSH:

```sh
sh /storage/armsx2-nightly-qt/uninstall.sh
```

Ele tira o emulador da lista do EmulationStation e o atalho do Tools. Antes de apagar suas configurações e save states, ele pergunta. Os memory cards em `roms/saves/ps2` não são tocados.

---

## Problemas comuns

**O instalador diz "malisx2 not installed"**
O ROCKNIX está no modo Panfrost. Volte ao Passo 1, troque para **libmali** e rode o instalador de novo. Sem o malisx2, o ARMSX2 usa o driver de vídeo do sistema. Essa combinação (nightly sem malisx2) não foi testada.

**"armsx2-nightly" não aparece na lista de emuladores**
Reinicie o EmulationStation (Passo 6). Se outro emulador de PS2 for instalado depois e trocar a configuração do PS2, rode o instalador de novo.

**O jogo não abre ou volta direto para a lista**
Confira se o BIOS está em `roms/bios/PS2`. Os logs ficam em `/storage/armsx2-nightly-qt/stdout.log` e `/storage/armsx2-nightly-qt/ARMSX2/logs/emulog.txt`.

**"Start ARMSX2 Nightly" não aparece no Tools**
Reinicie o EmulationStation. O ROCKNIX recria a pasta do Tools a cada boot, e um script (`/storage/.config/autostart/armsx2-nightly-tools.sh`) coloca o atalho de volta. Se esse arquivo sumiu, rode o instalador de novo.

**Achou um bug?**
- Problemas com o **instalador** ou com os atalhos do EmulationStation/Tools: abra uma [issue aqui](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/issues).
- O **emulador** e o **malisx2** são os oficiais, sem modificação. Os bugs deles são dos respectivos projetos. Siga as orientações de cada um e diga que instalou com este script.
