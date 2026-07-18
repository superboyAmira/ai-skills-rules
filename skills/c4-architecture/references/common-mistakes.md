# Common C4 mistakes

## Containers vs components

- **Container** = separately deployable / runnable process or data store (api, receiver, Postgres).
- **Component** = package/module inside a container (handlers, service, repository).
- Do not model shared libraries as containers.

## Kafka

- Do not draw one box "Kafka" for everything.
- Prefer named topics or team streams as queues when they matter.

## Relationships

- Avoid bidirectional arrows.
- Do not leave edges unlabeled.
- Do not invent "subcomponent" levels outside C4.

## Scope

- Do not put 30+ nodes on one diagram.
- Do not mix Context and Component detail on one canvas.
- Do not remove type meaning to "simplify" (person vs system vs DB).

## Style (this skill)

- Do not ship native C4 Mermaid when the user asked for square arrows / no hatching / Arial — use flowchart + style.md.
- Do not use cylinder DB shapes if they render with stripes; use rectangles + `db` class.
- Do not use dashed edges for primary flows.
