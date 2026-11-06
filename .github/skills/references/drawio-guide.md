# Draw.io Diagram Guide

Quick reference for creating Navigator-compliant diagrams using draw.io. For comprehensive diagram creation with Azure architecture icons, icon lookup, and adaptive user interview, use the **draw-io** plugin.

## Diagram Principles

1. **Simplicity** - Convey complex things simply
2. **Accuracy** - Aligned objects, even spacing
3. **Reusability** - Standard shapes, consistent style
4. **Purpose** - Every element serves the message

## Sopra Steria Color Palette

Use only these colors:

| Color | Hex | Use |
|-------|-----|-----|
| Red (Logo) | #CF022B | Highlights, warnings |
| Red Dark | #960000 | Emphasis |
| Red Light | #E14B0F | Accents |
| Orange (Logo) | #F07D00 | Primary accent |
| Orange Light | #FAAA0A | Secondary accent |
| Black | #000000 | Text, borders |
| Grey Dark | #232323 | Dark elements |
| Grey | #A6A6A6 | Neutral elements |
| Light Grey | #F2F2F2 | Backgrounds |
| Burgundy | #8C2350 | Accent |
| Teal | #41738C | Accent |
| Green | #2DAA64 | Success, positive |

## Standard Shapes

### Conceptual Level
- **Rectangle**: Systems, services, components
- **Rounded Rectangle**: Processes, activities
- **Circle/Ellipse**: Users, actors
- **Diamond**: Decision points
- **Arrows**: Data flow, relationships

### Logical Level
- Same shapes as conceptual
- Add: Cylinders for databases
- Add: Clouds for external services

### Detailed Level
- Tables preferred over diagrams
- If diagrams needed: specific icons acceptable

## Numbering Convention

For repeated objects, use italic `n` notation:

```
n1, n2, n3, ... (for sequential objects)
n1+1, n1+2 (for related objects)
```

## Draw.io XML Templates

### Basic Rectangle

```xml
<mxCell id="2" value="Component Name" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#F2F2F2;strokeColor=#000000;fontFamily=Calibri;fontSize=14;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
</mxCell>
```

### Arrow (Connection)

```xml
<mxCell id="3" value="" style="endArrow=classic;html=1;strokeColor=#000000;strokeWidth=1.5;" edge="1" parent="1">
  <mxGeometry relative="1" as="geometry">
    <mxPoint x="220" y="130" as="sourcePoint"/>
    <mxPoint x="300" y="130" as="targetPoint"/>
  </mxGeometry>
</mxCell>
```

### Complete Diagram Template

```xml
<mxfile host="app.diagrams.net">
  <diagram name="Page-1" id="navigator-diagram">
    <mxGraphModel dx="1422" dy="794" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="827" pageHeight="1169" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <!-- Add your shapes here -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## Style Guidelines

| Property | Value |
|----------|-------|
| Font | Calibri, 14pt (shapes), 12pt (labels) |
| Line thickness | 1.5pt standard, 2pt emphasis, 1pt light |
| Spacing | 20px min between objects, 10px grid |
| Text color | #000000 |

## Export Settings

For use in Word documents:
- Format: PNG or EMF (EMF preferred)
- Resolution: 150-300 DPI
- Background: White or Transparent
- Border: None

## Naming Convention

Save diagram files with the document name:
- Document: `Navigator - Design - Network.docx`
- Diagram: `Navigator - Design - Network.drawio`
