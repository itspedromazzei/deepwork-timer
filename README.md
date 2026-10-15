# Deepwork Timer

Timer de deep work minimalista para macOS, feito para rodar na segunda tela.
Um anel que se desfaz conforme o tempo passa, sino ao terminar, pausas configuráveis,
atividade escolhida antes de começar, contagem 3-2-1 com som de foco sintetizado e
histórico de horas focadas por dia e por atividade.

Swift nativo (SwiftUI + AppKit), sem dependências, compila só com as Command Line Tools.
Binário de ~1,3 MB, ~20 MB de memória, 0 % de CPU em repouso.

## Compilar e rodar

```bash
Scripts/build-app.sh --open
```

Gera `build/Deepwork Timer.app` (release, assinado ad-hoc) e abre. Para iterar na UI sem
notificações nem ícone no Dock: `swift run`.

Testes do núcleo (Swift Testing):

```bash
Scripts/test.sh
```

Ícone (já gerado em `Resources/AppIcon.icns`; refaça se mudar o desenho):

```bash
Scripts/make-icns.sh
```

## Uso

- **Espaço** inicia ou pausa. **Esc** fecha um painel ou sai do modo tela cheia.
- **⌘⇧F** alterna entre janela flutuante e tela cheia no monitor secundário.
- **⌘.** para, **⌘⇧.** pula a pausa, **⌘,** configurações, **⌘Y** histórico, **⌘E** atividades.
- O item na barra de menus mostra o tempo restante e tem as mesmas ações.
- Em tela cheia, os controles somem após 3 s sem mouse e voltam ao mexer.

## Som de foco

Tudo gerado em tempo real, sem arquivos de áudio: ruído branco, rosa (filtro de Kellet),
marrom (integrador com vazamento), binaural beta (14–30 Hz, padrão 18 Hz) e binaural gama
(40 Hz). Binaural usa portadora de 200 Hz; use fones de ouvido. O sino é síntese aditiva
com seis parciais decaindo.

## Dados

`~/Library/Application Support/DeepworkTimer/`

- `sessions.json` — sessões de foco e pausa (só as com 60 s ou mais).
- `settings.json` — preferências, atividades, modo e posição da janela.

Arquivo corrompido é renomeado para `*.corrupt-<timestamp>` e o app começa limpo.

## Estrutura

- `Sources/DeepworkCore` — modelos, máquina de estados do timer, DSP, persistência, agregação. Só Foundation; testável.
- `Sources/DeepworkTimer` — AppKit/SwiftUI: janela, menu, status item, engine de áudio, notificações, views.
- `Tests/DeepworkCoreTests` — 25 testes com relógio manual e análise dos sinais gerados.
- `Scripts/` — build do `.app`, testes, ícone.
