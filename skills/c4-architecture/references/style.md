# Diagram visual style (required)

Use this for all C4-content diagrams rendered as flowcharts unless the user overrides.

## Goals

- Square / orthogonal arrows (`stepAfter`)
- Solid fills only — no hatching, no cylinder stripe look
- Font: Arial
- Thick edge strokes
- Informative edge labels; short node text
- Prefer layered layout to avoid crossings; reverse edges from top externals into the app if needed so ranks stay correct

## INIT_BLOCK

Copy into every mermaid fence as the first line after ` ```mermaid `:

```text
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Arial','fontSize':'22px','primaryTextColor':'#1a1a1a','lineColor':'#2f363d','edgeLabelBackground':'#ffffff','clusterBkg':'#f7f8fa','clusterBorder':'#8a93a0'},'flowchart':{'defaultRenderer':'elk','curve':'stepAfter','htmlLabels':true,'nodeSpacing':42,'rankSpacing':60,'padding':28,'arrowMarkerAbsolute':false},'themeCSS':'foreignObject,foreignObject div,foreignObject span,foreignObject p,foreignObject b,.nodeLabel,.nodeLabel span,.cluster-label,.cluster-label span,.label,.label span{font-size:22px!important;font-family:Arial,sans-serif!important;line-height:1.15!important;}.edgeLabel,.edgeLabel span{font-size:18px!important;font-family:Arial,sans-serif!important;}.node rect,.node round,.node polygon,.node path,.node circle{fill-opacity:1!important;stroke-width:2.5px!important;}.cluster rect{fill:#f7f8fa!important;fill-opacity:1!important;stroke:#8a93a0!important;stroke-width:2px!important;}.edgePath path.path,.flowchart-link{stroke:#2f363d!important;stroke-width:3.5px!important;fill:none!important;}.marker,.marker path,defs marker path{stroke:#2f363d!important;fill:#2f363d!important;stroke-width:1px!important;}'}}%%
```

## classDef palette

```mermaid
classDef person fill:#DCEAF8,stroke:#2F5F8F,stroke-width:2px,color:#1a1a1a
classDef ui fill:#E8ECF1,stroke:#4A5560,stroke-width:2px,color:#1a1a1a
classDef app fill:#D8F0E4,stroke:#1F6B45,stroke-width:2px,color:#1a1a1a
classDef queue fill:#EADFF3,stroke:#6B3F8F,stroke-width:2px,color:#1a1a1a
classDef db fill:#D9ECF8,stroke:#1F5F8C,stroke-width:2px,color:#1a1a1a
classDef cache fill:#F8DADA,stroke:#9A3A3A,stroke-width:2px,color:#1a1a1a
classDef obs fill:#EDE4F7,stroke:#5C3D8A,stroke-width:2px,color:#1a1a1a
classDef ext fill:#FFE8C8,stroke:#9A6A1F,stroke-width:2px,color:#1a1a1a
classDef decision fill:#FFF3C4,stroke:#A88412,stroke-width:2px,color:#1a1a1a
```

Mapping:

| C4 idea | class |
|---------|--------|
| Person | `person` |
| UI / SPA | `ui` |
| Our app / container / component | `app` |
| Kafka / queue | `queue` |
| Database | `db` |
| Redis / cache | `cache` |
| Vault, Jaeger, Pyroscope, Prometheus, Grafana | `obs` |
| External business system | `ext` |

## Node shapes

- Prefer rectangles `["Label"]` for everything including DBs (cylinders often look hatched).
- People can use `(["Label"])` stadium if desired — still solid fill via classDef.
- Queues: rectangle is enough; optional `[["Label"]]` only if fill stays solid.

## Layout tips

1. Put clients, data sources, and platform (Vault/Jaeger/…) in a top `subgraph` with `direction LR`.
2. Point edges **from** top externals **into** the system (`vault -->|"секреты"| cfg`) so Mermaid keeps them above.
3. Split API / receiver / jobs into separate horizontal paths to avoid crossings.
4. No dashed edges unless the user asks.
