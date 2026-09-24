# LifeFlow — Identidade Visual

Fonte da verdade visual, extraída do protótipo aprovado ([canvas de Design](https://claude.ai/artifact/91CTTARkVogrqQtJgBf71u)). Qualquer implementação (Flutter `core/theme/`, Tailwind `tailwind.config`) deve derivar destes tokens — não reinventar valores ad-hoc por tela.

## Personalidade

Herdada do Motora: moderna, confiável, automotiva, tecnológica, simples. Não deve parecer ERP, painel administrativo ou planilha. Hierarquia por espaço negativo e tipografia — evitar `card > card > card`.

## Tema

Três modos: `system` (padrão), `light`, `dark`. A troca manual vive na aba **Mais → Aparência**, nunca solta em headers de outras telas. A paleta não é uma inversão de opacidade — cada modo tem valores recalculados para contraste.

---

## Cores — modo escuro (padrão de marca)

| Token | Hex | Uso |
|---|---|---|
| `bg` | `#0D0F12` | Fundo de página |
| `surface` | `#171A1F` | Cards, sheets |
| `surface-2` | `#1E2229` | Elementos sobre superfície (chips internos, placeholders) |
| `nav-bg` | `#12141A` | Barra de navegação inferior / sidebar |
| `border-subtle` | `rgba(255,255,255,0.06–0.08)` | Divisores, contorno de nav |
| `text-primary` | `#F5F6F7` | Texto principal |
| `text-secondary` | `#9AA0A8` | Labels, legendas |
| `text-muted` | `#6B7280` | Headers de seção (ex: "HOJE", "SETEMBRO"), ícones inativos |
| `text-disabled` | `#3A4048` | Placeholders de imagem, ícones muito secundários |

## Cores — modo claro

| Token | Hex | Uso |
|---|---|---|
| `bg` | `#F6F6F4` | Fundo de página |
| `surface` | `#FFFFFF` | Cards, sheets (com `border: rgba(0,0,0,0.06)`) |
| `surface-2` | `#F0F0EE` | Elementos sobre superfície |
| `border-subtle` | `rgba(0,0,0,0.06–0.08)` | Divisores |
| `text-primary` | `#14171B` | Texto principal |
| `text-secondary` | `#5B6068` | Labels, legendas |
| `text-muted` | `#8A8F98` | Headers de seção, ícones inativos |
| `text-disabled` | `#B7BBC2` | Placeholders |

## Cores semânticas (accent + estados)

O verde é a cor de marca — usar com moderação (~5% da interface: ação principal, seleção, sucesso, elementos de marca). Âmbar e vermelho são só para estado, nunca decorativos.

| Estado | Escuro (fill/dot) | Escuro (tint bg) | Claro (texto/fill) | Claro (tint bg) | Significado |
|---|---|---|---|---|---|
| Accent / sucesso | `#61E786` | `rgba(97,231,134,0.08–0.14)` | `#1E9E56` | `rgba(30,158,86,0.09–0.12)` | Normal, em dia, receita, ação primária |
| Atenção | `#FFB547` | `rgba(255,181,71,0.10–0.14)` | `#B45309` | `rgba(180,83,9,0.10–0.12)` | Próximo do vencimento, orçamento 80–99% |
| Crítico | `#FF5D5D` | `rgba(255,93,93,0.10)` | `#DC2626` | `rgba(220,38,38,~0.10)` | Vencido, orçamento estourado, erro |

Regra: no modo escuro o accent pode ser usado como *fill* direto (dots, ícones, botão primário) porque tem contraste suficiente contra fundos escuros. No modo claro, o mesmo tom de marca (`#61E786`/`#FFB547`/`#FF5D5D`) só é usado como *fill* de botão sólido com texto branco por cima — quando a cor é o próprio texto ou ícone sobre fundo claro, usa-se a variante escurecida (`#1E9E56`/`#B45309`/`#DC2626`) para manter contraste ≥ 4.5:1.

Cores de **categoria financeira** continuam livres, definidas pelo usuário por categoria (herdado do GranaFlow) — não fazem parte da paleta fixa do sistema.

---

## Tipografia

Google Fonts: `Space Grotesk` (500/600/700) + `Manrope` (400/500/600/700). Evitar Inter/Roboto/Arial (genéricos demais).

- **Space Grotesk** — títulos, valores monetários em destaque, wordmark "LIFEFLOW" (uppercase, `letter-spacing: 0.14em`, peso 700).
- **Manrope** — todo o resto: corpo, labels, botões, navegação.

| Papel | Fonte | Peso | Tamanho |
|---|---|---|---|
| Valor hero (saldo) | Space Grotesk | 700 | 30–36px |
| Título de tela (H1) | Space Grotesk | 700 | 21–24px |
| Título de card | Manrope | 700 | 14–16px |
| Corpo / label | Manrope | 500–600 | 13–14.5px |
| Legenda / secundário | Manrope | 400–500 | 11–13px |
| Header de seção (uppercase) | Manrope | 700 | 11.5px, `letter-spacing: 0.06em` |
| Nav label | Manrope | 500–600 | 10.5px |

---

## Espaçamento, raio e forma

- Cards: `border-radius: 16–20px`, padding `16–24px`.
- Chips/pills de status: `border-radius: 999px` (full round), padding `4px 10px`.
- Botões de ícone / containers pequenos: `border-radius: 10–12px`.
- Chips de aba/filtro: `border-radius: 999px`, padding `8px 14px`.
- Gap padrão entre elementos de uma lista: `8–14px`.
- Barra de progresso (orçamento/meta): altura `6px`, `border-radius: 999px`.

## Ícones

SVG inline, stroke-only (`fill: none`), `stroke-width: 1.8–2.2`, `stroke-linecap/linejoin: round`, viewBox `24×24`, renderizado em `16–21px`. Nunca emoji, nunca ícone preenchido (exceção: o `+` do quick-add, que é sólido sobre fundo accent). Sem biblioteca de ícones externa definida ainda — manter consistência de estilo (traço fino, cantos arredondados) seja qual for a lib escolhida na implementação (ex: Lucide/Phosphor no Flutter e Web, que já seguem esse desenho).

---

## Navegação

**Mobile** — bottom nav fixa, 5 posições: Início, Finanças, **+** (quick-add, botão circular elevado `50×50px`, fundo accent, ícone escuro), Veículos, Mais. Item ativo em `accent`; inativos em `text-secondary`.

**Web** — sidebar fixa à esquerda (`~232px`), mesma hierarquia (Início, Finanças, Veículos, Notificações, Mais), item ativo com fundo `accent` tint + texto accent.

**Home combinada**: card de saldo + card do veículo em destaque + "próximo cuidado" + orçamentos do mês — nunca duplicar dashboards completos de cada módulo na home.

**Quick-add**: bottom sheet único, duas seções rotuladas ("Veículo" / "Finanças"), nunca uma tela intermediária antes das opções.

---

## Padrões de conteúdo

- Placeholder de imagem ausente: caixa neutra com ícone genérico + legenda entre colchetes, ex: `[FOTO DO VEÍCULO]` — nunca gradiente decorativo, nunca imagem inventada.
- Transação gerada automaticamente (vínculo veículo→finanças): subtítulo explícito "Veículo · gerada automaticamente", nunca silenciosa.
- Valores: receita com `+`, despesa com `-`; despesa comum usa `text-primary` (não vermelho — vermelho é reservado a estado crítico/vencido, não a "é um gasto").
- Empty/loading/error states obrigatórios em toda tela de listagem (herdado do Motora, ainda válido).

---

## Referência viva

Protótipo navegável: https://claude.ai/artifact/91CTTARkVogrqQtJgBf71u (privado — peça acesso ao dono antes de compartilhar). Telas: Início, Finanças, Veículo, Novo registro, Mais, Web — Início, Início (modo claro).
