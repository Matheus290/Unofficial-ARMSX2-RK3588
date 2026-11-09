# Tutorial: instalando a versão não oficial do ARMSX2 RK3588 no ROCKNIX

*[English version](TUTORIAL-ROCKNIX.md)*

Este guia leva você do zero até jogar PS2 pelo EmulationStation do ROCKNIX, com o ARMSX2 otimizado para RK3588 como mais um emulador na lista do PS2. Leva uns 10 minutos.

> Tudo aqui foi testado **apenas no ROCKNIX**. No Batocera ou em outro Linux os passos são diferentes e não foram testados: se for por esse caminho e travar em algum ponto, peça ajuda a alguém que conheça o seu sistema, ou a um assistente de IA.

> Esta é uma versão **experimental e não oficial**, sem vínculo com o projeto ARMSX2 e não endossada por ele. Se algo der errado, **não** reporte ao ARMSX2: abra uma [issue neste fork](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/issues).

---

## O que você precisa

- Um aparelho **RK3588** com **ROCKNIX** instalado e funcionando (Orange Pi 5, Orange Pi 5 Plus, Rock 5B, portáteis RK3588…).
- O aparelho **conectado à rede** (Wi-Fi ou cabo), na mesma rede que o seu computador.
- Um **computador** (Windows, macOS ou Linux) para acessar o aparelho pela rede.
- O **BIOS do PS2**, extraído do seu próprio console (arquivos `.bin`, às vezes com `.mec`/`.nvm`). Não incluímos o BIOS.
- Seus **jogos de PS2** (`.iso`, `.chd`, `.cso`…).

---

## Passo 1: ligar o SSH e descobrir o IP

O SSH deixa você digitar comandos no aparelho a partir do computador.

1. No EmulationStation, aperte **Start** para abrir o menu principal.
2. Entre em **NETWORK SETTINGS** e ligue **ENABLE SSH**. Em algumas versões, a opção fica em **SYSTEM SETTINGS → NETWORK SERVICES**.
3. Ainda nas configurações de rede (ou em **INFORMATION**), anote o **endereço IP** do aparelho, por exemplo `192.168.0.50`.

> Dica: muitas redes também aceitam o nome do aparelho em vez do IP, como `rocknix.local` ou `RK3588.local`.

---

## Passo 2: colocar o BIOS e os jogos

Se você já usa outro emulador de PS2 no ROCKNIX, provavelmente isso já está feito: pule para o Passo 3.

1. No mesmo menu de rede, ligue **ENABLE SAMBA**. Assim as pastas do aparelho aparecem na rede.
2. No computador, abra a pasta compartilhada:
   - **Windows:** no Explorador de Arquivos, digite `\\192.168.0.50` (troque pelo seu IP) na barra de endereço.
   - **macOS:** no Finder, menu *Ir → Conectar ao Servidor*, e digite `smb://192.168.0.50`.
   - **Linux:** no gerenciador de arquivos, digite `smb://192.168.0.50`.
   - Se pedir login, use usuário `root` e senha `rocknix`.
3. Copie os arquivos:
   - **BIOS do PS2** → `roms/bios/PS2/` (crie a pasta `PS2` se ela não existir)
   - **Jogos de PS2** → `roms/ps2/`

---

## Passo 3: entrar no aparelho por SSH

1. Abra um terminal no computador:
   - **Windows:** abra o **PowerShell** (procure "PowerShell" no menu Iniciar).
   - **macOS:** abra o app **Terminal**.
   - **Linux:** abra o terminal da sua distribuição.
2. Digite (trocando pelo seu IP) e aperte Enter:

   ```sh
   ssh root@192.168.0.50
   ```

3. Na primeira vez, ele pergunta se você confia no aparelho: digite `yes` e aperte Enter.
4. A senha é **`rocknix`**. Ao digitar a senha, nada aparece na tela; isso é normal. Aperte Enter.

Quando aparecer algo como `RK3588:~ #`, você está dentro do aparelho.

---

## Passo 4: instalar

Copie e cole este comando no terminal e aperte Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/Matheus290/Unofficial-ARMSX2-RK3588/rk3588/rk3588/install.sh | sh
```

O instalador:

- baixa a versão mais recente e instala em `/storage/armsx2-rk3588`;
- adiciona o **armsx2-rk3588** à lista de emuladores do PS2 no EmulationStation, **sem remover** os emuladores que você já tem;
- na primeira instalação, já deixa tudo configurado:
  - BIOS em `roms/bios/PS2` e jogos em `roms/ps2`;
  - memory cards em `roms/saves/ps2`, compartilhados com os outros emuladores de PS2;
  - controle mapeado;
  - Vulkan com resolução 2x, filtro suave, widescreen, MTVU e IOP thread ligados.

No final, ele mostra **Done.** Pode fechar o terminal.

> Sem acesso à internet no aparelho? Baixe o arquivo `armsx2-rk3588-*-linux-arm64.tar.xz` em [Releases](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/releases), copie para a pasta compartilhada (por exemplo `roms/`) e, por SSH, rode:
> ```sh
> cd /storage/roms && tar -xJf armsx2-rk3588-*-linux-arm64.tar.xz && ./armsx2-rk3588/install.sh
> ```

---

## Passo 5: reiniciar o EmulationStation

No aparelho, aperte **Start** → **QUIT** → **RESTART EMULATIONSTATION**. Reiniciar o aparelho também serve.

---

## Passo 6: escolher o ARMSX2 RK3588 como emulador do PS2

Você pode escolher para **todos os jogos de PS2** ou **só para alguns**.

**Para todos os jogos de PS2:**

1. Aperte **Start** → **GAME SETTINGS** → **PER SYSTEM ADVANCED CONFIGURATION** → **PlayStation 2**.
2. Em **EMULATOR**, escolha **armsx2-rk3588**.

**Só para um jogo:**

1. Na lista de jogos do PS2, selecione o jogo e abra as opções dele (em geral com o botão **Select**). Vá em **ADVANCED GAME OPTIONS**.
2. Em **EMULATOR**, escolha **armsx2-rk3588**.

Agora é só abrir o jogo pela lista, como qualquer outro.

---

## Passo 7 (recomendado): escanear os jogos pelo menu Tools

O instalador também coloca **Start ARMSX2 RK3588** no menu **Tools** do EmulationStation. Essa opção abre o emulador na lista de jogos dele, sem iniciar nenhum jogo.

1. Abra **Tools → Start ARMSX2 RK3588**.
2. Vá em **Settings → Game List** e escolha **Scan For New Games** (faça isso também sempre que adicionar jogos novos). Ali também dá para baixar as capas.
3. Feche o emulador.

Depois disso, os jogos abertos pelo EmulationStation mostram a capa no menu do emulador, e o **Game Properties** mostra os detalhes e os patches de cada jogo (por exemplo, a remoção do bloom do Burnout Revenge).

---

## Controles

O primeiro controle já vem mapeado (Xbox, PlayStation ou o controle embutido do portátil).

| Ação | Botões |
|---|---|
| Abrir o menu do emulador | **L3 + R3** (aperte os dois analógicos) |
| Acelerar (segurar) | **L2 + R2** |
| Salvar estado | **Guide/Home + R1** |
| Carregar estado | **Guide/Home + L1** |

Para **sair do jogo** e voltar ao EmulationStation, abra o menu (L3 + R3) e escolha a opção de fechar o jogo. O atalho de sair do ROCKNIX (em geral **Select + Start**) também funciona.

Tudo pode ser remapeado no menu do emulador, em *Settings → Controllers* e *Hotkeys*.

---

## Atualizar

Rode o mesmo comando do Passo 4. Ele troca só o programa: suas configurações, memory cards e save states ficam como estão.

## Desinstalar

Por SSH:

```sh
/storage/armsx2-rk3588/uninstall.sh
```

Ele tira o emulador da lista do EmulationStation e devolve tudo como era. Antes de apagar suas configurações e save states, ele pergunta. Os memory cards em `roms/saves/ps2` não são tocados.

---

## Problemas comuns

**"armsx2-rk3588" não aparece na lista de emuladores**
Reinicie o EmulationStation (Passo 5). Se outro emulador de PS2 for instalado depois e trocar a configuração do PS2, rode o instalador de novo.

**O jogo não abre ou volta direto para a lista**
Confira se o BIOS está em `roms/bios/PS2`. O log fica em `/storage/armsx2-rk3588/logs/emulog.txt`; anexe esse arquivo se for abrir uma issue.

**O Game Properties diz "Cannot show details for games which were not scanned", ou a capa não aparece**
O emulador ainda não escaneou esse jogo: faça o Passo 7.

**"Start ARMSX2 RK3588" não aparece no Tools**
Reinicie o EmulationStation. A opção é recolocada a cada boot por `/storage/.config/autostart/armsx2-rk3588-tools.sh`; se esse arquivo sumiu, rode o instalador de novo.

**Lento ou com imagem estranha**
No ROCKNIX, o driver de vídeo pode ser o da Arm (*libmali*) ou o *Panfrost*. Esta versão roda melhor com o **libmali**: algumas cenas pesadas ficam bem mais lentas no Panfrost. Alguns jogos também ficam mais leves em 1x: abra o menu (L3 + R3) → *Settings → Graphics* e reduza a resolução interna.

**Achou um bug?**
Abra uma [issue aqui](https://github.com/Matheus290/Unofficial-ARMSX2-RK3588/issues). Diga qual aparelho e qual jogo, descreva o que aconteceu e anexe o `emulog.txt`. Por favor, **não** reporte ao projeto ARMSX2 original.
