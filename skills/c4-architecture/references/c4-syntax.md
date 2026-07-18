# Mermaid C4 syntax (native)

Use only when the user explicitly wants `C4Context` / `C4Container` syntax.
For styled diagrams, prefer flowchart + [style.md](style.md).

## People and systems

```
Person(alias, "Label", "Description")
Person_Ext(alias, "Label", "Description")
System(alias, "Label", "Description")
System_Ext(alias, "Label", "Description")
SystemDb(alias, "Label", "Description")
SystemQueue(alias, "Label", "Description")
SystemQueue_Ext(alias, "Label", "Description")
```

## Containers

```
Container(alias, "Label", "Technology", "Description")
Container_Ext(alias, "Label", "Technology", "Description")
ContainerDb(alias, "Label", "Technology", "Description")
ContainerQueue(alias, "Label", "Technology", "Description")
```

## Components

```
Component(alias, "Label", "Technology", "Description")
Component_Ext(alias, "Label", "Technology", "Description")
ComponentDb(alias, "Label", "Technology", "Description")
```

## Boundaries

```
Enterprise_Boundary(alias, "Label") { ... }
System_Boundary(alias, "Label") { ... }
Container_Boundary(alias, "Label") { ... }
Boundary(alias, "Label", "type") { ... }
```

## Relationships

```
Rel(from, to, "Label")
Rel(from, to, "Label", "Technology")
BiRel(from, to, "Label")   # avoid — prefer unidirectional
Rel_U / Rel_D / Rel_L / Rel_R(from, to, "Label")
```

## Deployment

```
Deployment_Node(alias, "Label", "Type", "Description") { ... }
Node(alias, "Label", "Type", "Description") { ... }
```

## Layout / style helpers

```
UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
UpdateElementStyle(alias, $fontColor="...", $bgColor="...", $borderColor="...")
UpdateRelStyle(from, to, $textColor="...", $lineColor="...", $offsetX="5", $offsetY="-10")
```

Native C4 styling is limited; it will not give square `stepAfter` arrows or reliable solid fills.
