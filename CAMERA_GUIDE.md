# Como usar o MushCam

Este guia usa as cameras que o manager ja cria: `main`, `player2` e `minimap`.
O historico de implementacao e os detalhes dos parametros ficam em [CAMERA_PLAN.md](CAMERA_PLAN.md).

## Antes de integrar

Manter uma instancia de `obj_camera_manager` na room. Ela cria os objetos de camera,
os handles nativos, as viewports e o painel de testes. Nao colocar `obj_camera`
manualmente na room: ele precisa do handle que o manager fornece na criacao.

Usar os comandos depois que o Create do manager terminar. Para iniciar o
acompanhamento de um jogador ja colocado na room, o evento Room Start do jogador
e um local apropriado. Se criar o jogador durante o jogo, chamar depois que ambos
ja existirem. `CM` e a macro do projeto para `obj_camera_manager`.

Os nomes identificam cameras; os numeros identificam viewports:

| Camera inicial | Viewport | Uso no projeto |
| --- | --- | --- |
| `main` | 0 | Tela principal |
| `player2` | 1 | Segunda tela do split |
| `minimap` | 2 | Overlay do minimapa |

Cada camera calcula seu enquadramento no End Step. As chamadas de controle podem
ser feitas no Create, Room Start ou Step conforme o comportamento desejado, desde
que o manager e os alvos ja existam. Configuracoes permanentes sao aplicadas uma vez;
deslocamento manual e comandos acionados por eventos sao chamados quando necessarios.

## Seguir um jogador

No Room Start de `obj_player`:

```gml
CM.camera_follow("main", id, true)
```

`id` e esta instancia do jogador. `true` centraliza imediatamente; `false` usa a
suavizacao a partir da posicao atual. O foco usa o `x/y` da instancia. Para mirar
no centro visual, a origem do sprite do alvo deve estar nesse centro.

Para o segundo jogador, no Room Start de `obj_player2`:

```gml
CM.camera_follow("player2", id, true)
```

Se o alvo for destruido, a camera para na posicao atual. Ao criar outro jogador,
chamar `camera_follow` com o novo ID.

## Plataforma e topdown

Exemplo de configuracao para plataforma, no Room Start do jogador:

```gml
CM.camera_set_offset("main", 0, -60)
CM.camera_set_smoothing("main", .1, .08, .05)
CM.camera_set_dead_zone("main", 120, 80)
CM.camera_set_look_ahead("main", .25, 0, 80, 0)
CM.camera_follow("main", id, true)
```

O offset negativo no Y desloca o foco para cima e deixa o jogador mais abaixo na
tela. Look ahead com tempo e amplitude Y zerados antecipa somente no eixo X.
Os valores acima sao um exemplo editavel, nao um preset automatico do sistema.

Para uma camera topdown centralizada:

```gml
CM.camera_set_offset("main", 0, 0)
CM.camera_set_dead_zone_enabled("main", false)
CM.camera_set_look_ahead_enabled("main", false)
CM.camera_follow("main", id, true)
```

As velocidades de suavizacao ficam entre 0 e 1: 0 congela a interpolacao, 1 acompanha
imediatamente. Os calculos consideram o tempo do frame. Dead zone e offset usam pixels
do mundo; seu tamanho aparente na tela muda com o zoom.

## Area e zoom

Usar a area inteira da room como limite:

```gml
CM.camera_use_room_bounds("main")
```

Ou limitar a uma regiao especifica:

```gml
CM.camera_set_bounds("main", 100, 50, 800, 600)
```

Os dois comandos habilitam os limites. Para permitir sair da area:

```gml
CM.camera_set_limits_enabled("main", false)
```

O zoom manual recebe -1 a 1: positivo aproxima, negativo afasta e 0 usa o tamanho
base. A amplitude depende de `zoom_range`.

```gml
CM.camera_set_zoom_settings("main", .5)
CM.camera_set_zoom("main", .3)
```

Para aumentar gradualmente o zoom por uma entrada mantida no Step, usar uma quantidade
por segundo multiplicada pelo tempo do frame:

```gml
CM.camera_adjust_zoom("main", .5 * delta_time / 1000000)
```

Executar essa chamada somente enquanto a entrada desejada estiver ativa. Se a vista
for maior que a area permitida, a camera centraliza nesse eixo; o limite nao altera
automaticamente o zoom.

## Focar em mais de um alvo

Chamar uma vez quando os dois jogadores ja existirem:

```gml
var _player1 = instance_find(obj_player, 0)
var _player2 = instance_find(obj_player2, 0)

if  (_player1 != noone && _player2 != noone)  {
  CM.camera_set_group_framing("main", 32, 32, .5, 0)
  CM.camera_follow_group("main", [{instance: _player1}, {instance: _player2}], true)
}
```

A camera mira no centro da regiao que contem os alvos. O enquadramento automatico
afasta quando necessario e aproxima suavemente quando ha espaco. O zoom manual pode
afastar mais; aproximar respeita o enquadramento automatico.

As margens de 32 sao por lado, em pixels do mundo. `.5` e a escala minima em relacao
a altura base; o ultimo `0` significa sem limite maximo de afastamento.

Tambem e possivel misturar um alvo com um ponto fixo:

```gml
CM.camera_follow_group("main", [{instance: id}, new Vec2(600, 300)], true)
```

Usar `{instance: id}` para uma instancia e `new Vec2(x, y)` para um ponto fixo.
`camera_set_group_point` move um ponto pelo indice, que comeca em 0. Alvos destruidos
sao ignorados; quando nao sobra nenhum ponto valido, a camera fica fixa.

Os limites da area e um limite maximo de afastamento podem impedir que todos caibam.
O painel mostra `group_fits` e `group_max_reached` para identificar esses casos.

## Mover e parar independentemente de um alvo

```gml
// Ir suavemente ate um ponto, considerando o offset
CM.camera_move_to("main", 600, 300)

// Interromper o movimento ou acompanhamento
CM.camera_stop("main")

// Definir o centro diretamente, sem aplicar o offset
CM.camera_set_position("main", 600, 300)

// Deslocar diretamente em pixels do mundo
CM.camera_move("main", 16, 0)

// Retomar o acompanhamento
CM.camera_follow("main", id)
```

Estas sao alternativas, nao uma sequencia para executar de uma vez. `move_to` termina
em FIXED ao chegar; `camera_move` usa MANUAL. A volta ao acompanhamento e explicita.
Para movimento manual mantido no Step, multiplicar a velocidade em pixels por segundo
por `delta_time / 1000000`.

## Screenshake

Chamar no evento que deve provocar o efeito:

```gml
CM.camera_shake("main", 8, 4, .35)
```

X/Y sao amplitudes em pixels do mundo e `.35` e a duracao em segundos. A chamada
seguinte substitui o efeito anterior. O shake desloca a camera nativa, preservando
a posicao base e a viewport. Os limites podem reduzir o tremor nas bordas.

```gml
CM.camera_stop_shake("main")
```

## Cutscene com retorno automatico

Preparar uma vez, depois que o manager existir:

```gml
CM.create_camera("cutscene", new Vec2(640, 380))
CM.camera_set_position("cutscene", 600, 300)
CM.viewport_add_camera(0, "cutscene", 20, false)
```

No inicio da cutscene:

```gml
CM.viewport_set_camera_enabled(0, "cutscene", true)
```

No fim:

```gml
CM.viewport_set_camera_enabled(0, "cutscene", false)
```

A `main` continua registrada com prioridade 0, entao volta automaticamente se for a
maior prioridade habilitada restante. A cutscene troca somente a camera da viewport 0.
A troca entre cameras e imediata; a animacao de split trata do tamanho das viewports.

`set_viewport_camera` e `camera_activate` substituem a lista por uma unica camera.
Usar essas associacoes exclusivas quando nao for necessario retornar automaticamente.
Para comportamento temporario, registrar/habilitar candidatas como no exemplo acima.

## Layouts

```gml
CM.set_layout(LAYOUT.SINGLE)
CM.set_layout(LAYOUT.SPLIT_VERTICAL)
CM.set_layout(LAYOUT.SPLIT_HORIZONTAL)
CM.set_layout(LAYOUT.GRID)
```

Escolher uma dessas chamadas no evento de troca. SINGLE e split vertical/horizontal
possuem transicao ao abrir/fechar o split; grid e mudanca entre os eixos sao imediatos.
Overlays, como o minimapa, conservam sua posicao/tamanho fora da distribuicao do layout.

Cada camera deve ter uma viewport propria se as telas precisarem de proporcoes
diferentes. Quando a mesma camera e compartilhada, a primeira viewport visivel
define sua proporcao; as outras exibem a mesma vista.

## Conferir o resultado

Os comandos normalmente retornam `true` ou `false`. `create_camera` retorna os dados
da camera criada ou `false`; `get_camera` retorna os dados ou `undefined`. Nome de
camera ausente, alvo invalido e candidata nao registrada podem fazer uma chamada falhar.

No painel, `Ultima chamada` e `Sucesso` ajudam a conferir os comandos. Campos de
edicao sao parametros: clicar no botao de aplicar. Usar Carregar camera ou Carregar
candidata selecionada para copiar os valores reais antes de editar.

O teste rapido de prioridade cria sua propria camera e preserva as candidatas
existentes. Nenhum nome, ponto ou prioridade precisa ser preenchido nesse teste.

Para desativar o painel, definir `debug_enabled = false` no inicio do Create do manager.
Os comandos de camera continuam funcionando. O Step dos jogadores e do manager contem
atalhos de demonstracao; revisar esses atalhos ao integrar os controles do seu jogo.

## Responsabilidades

| Parte | Responsabilidade |
| --- | --- |
| `obj_camera_manager` | Criar/destruir cameras, organizar viewports/layouts e delegar comandos |
| `obj_camera` | Alvos, estados, offset, suavizacao, zona morta, antecipacao, zoom, limites e escrita nativa |
| `CameraFocusGroup` | Fontes de foco e regiao do grupo |
| `CameraShake` | Deslocamento temporario do efeito |
| `CameraSelector` | Lista de candidatas e escolha por prioridade |
| `CameraDebug` | Controles, indicadores e recursos temporarios de teste |

Evitar escrever diretamente na posicao/tamanho da camera nativa de fora de obj_camera.
Para alterar o comportamento, usar os comandos publicos do manager.
