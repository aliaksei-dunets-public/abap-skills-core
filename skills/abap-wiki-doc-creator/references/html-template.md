# HTML Wiki Template

Self-contained HTML shell for the ABAP wiki page. No external dependencies — pure HTML + inline CSS.

---

## HTML Shell

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><!-- PAGE TITLE --></title>
  <style>
    body { max-width: 1200px; margin: 24px 48px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: 14px; color: #172b4d; line-height: 1.6; }
    h2   { font-size: 20px; font-weight: 700; border-bottom: 2px solid #dfe1e6; padding-bottom: 6px; margin-top: 36px; }
    h3   { font-size: 16px; font-weight: 700; margin-top: 28px; }
    h4   { font-size: 14px; font-weight: 700; margin-top: 20px; }
    h5   { font-size: 13px; font-weight: 600; margin-top: 14px; }
    hr   { border: none; border-top: 1px solid #dfe1e6; margin: 28px 0; }
    .blue { color: #09326c; }
    .sn  { color: #006644; font-weight: 600; }
    .sr  { color: #ff8b00; font-weight: 600; }
    .sf  { color: #bf2600; font-weight: 600; }
    .sb  { color: #0052cc; font-weight: 600; }
    .info { background: #deebff; border: 1px solid #4c9aff; border-radius: 4px; padding: 10px 16px; margin: 12px 0; }
    .toc  { background: #f4f5f7; border: 1px solid #dfe1e6; border-radius: 4px; padding: 14px 24px; display: inline-block; margin-bottom: 28px; min-width: 300px; }
    .toc a { color: #0052cc; text-decoration: none; }
    pre  { background: #f4f5f7; border: 1px solid #dfe1e6; border-radius: 4px; padding: 16px; font-family: "Courier New", monospace; font-size: 12px; white-space: pre; overflow-x: auto; }
    code { background: #f4f5f7; padding: 1px 5px; border-radius: 3px; font-family: "Courier New", monospace; font-size: 12px; }
    table { border-collapse: collapse; width: 100%; margin: 12px 0; }
    th, td { border: 1px solid #dfe1e6; padding: 8px 12px; text-align: left; vertical-align: top; }
    th { background: #f4f5f7; font-weight: 600; }
    tr:nth-child(even) td { background: #fafbfc; }
  </style>
</head>
<body>
  <!-- TOC, sections go here -->
  <p>&nbsp;</p>
</body>
</html>
```

---

## Section Structure

Place sections in this order inside `<body>`:

1. `<div class="toc">` — Table of Contents (nested `<ul>`, `href="#id"` anchors)
2. Business Context
3. Technical Context (with sub-sections)
4. Process Flow
5. `<p>&nbsp;</p>` — last line before `</body>`

Separate major sections with `<hr>`.
Separate HTML blocks with `<!-- ================================================================ -->`.

---

## Heading Formats

**h2 (section heading):**
```html
<h2 id="..."><strong><u><span class="blue">Text</span></u></strong></h2>
```

**h5 (building block heading):**
```html
<h5><u><strong>Text</strong></u></h5>
```

---

## Sections

### 1. TOC

```html
<div class="toc">
  <strong>Contents</strong>
  <ul>
    <li><a href="#business-context">Business Context</a></li>
    <li><a href="#technical-context">Technical Context</a>
      <ul>
        <li><a href="#hld">High-Level Design</a></li>
        <li><a href="#sequence">Application Flow Diagram</a></li>
        <li><a href="#data-model">Data Model</a></li>
        <li><a href="#class-diagram">Class Diagram</a></li>
        <li><a href="#tech-details">Technical Details</a></li>
      </ul>
    </li>
    <li><a href="#process-flow">Process Flow</a></li>
  </ul>
</div>
```

### 2. Business Context `id="business-context"`

- Functional purpose of the feature
- Business problem it solves
- Key developer notes inside `<div class="info">`
- Source: user's additional instructions + annotations from Phase 2

### 3. Technical Context `id="technical-context"`

#### High-Level Design `id="hld"`
- Architectural overview, building blocks as `h5` headings
- RAP hierarchy if applicable (BO → Service → UI)
- Source: object type analysis + user instructions

#### Application Flow Diagram `id="sequence"`
- PlantUML sequence or activity diagram
- Use: `skinparam sequenceArrowThickness 1.5` and `skinparam responseMessageBelowArrow true`
- Source: Behavior Definition operations + Class method analysis
- Raw PlantUML: `<pre>@startuml ... @enduml</pre>` — no rendering, no wrappers

#### Data Model `id="data-model"`

**Sub-section A — CDS View Hierarchy:**
- PlantUML diagram: Basic → Composite → Consumption layer dependencies
- Source: CDS `DEFINE VIEW EXTENDING` / association analysis

**Sub-section B — Database Table Model:**
- PlantUML entity diagram: table fields, key fields, field types, FK relations
- Relations inferred from: FK definitions in DDIC + JOIN analysis in CDS views
- Source: TABL objects via abap-vs-reader

#### Class Diagram `id="class-diagram"`
- PlantUML class diagram: interfaces, classes, inheritance, key methods
- Use: `skinparam classAttributeIconSize 0`
- Source: Interface and Class source code

#### Technical Details `id="tech-details"`

Tables to include:

*Development Details* — Package, Transport, Namespace, System

*CDS Views* — name, type (Basic/Composite/Consumption/Extension), purpose

*Development Artifacts (Full List)* — three columns:
`Application Node Name` | `Type` | `Description`
Objects with ⚠ source unavailable are listed but marked.

*Behavior Definition Operations Summary* — CRUD ops, actions, validations, determinations per entity (only if BDEF present)

*Message Class* — message IDs, text, usage context (only if MSAG present)

### 4. Process Flow `id="process-flow"`
- Source reference (TR / git commit / package)
- Step-by-step `<ol>` instructions (how to use or extend the component)
- Integration points with other components
- Source: user additional instructions + TR/commit metadata

---

## Formatting Conventions

- SAP object names: `<code>` tags
- Special HTML chars: `&mdash;` (—), `&ndash;` (–), `&rarr;` (→), `&amp;` (&), `&nbsp;`
- Status classes: `.sn` = success/green, `.sr` = warning/orange, `.sf` = failure/red, `.sb` = info/blue
- PlantUML: raw source inside `<pre>@startuml ... @enduml</pre>` — no rendering, no wrappers
