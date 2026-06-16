# PlantUML Diagram Guide

Templates for each diagram type used in the wiki. All diagrams are embedded as
raw PlantUML source inside `<pre>@startuml ... @enduml</pre>` — no rendering.

---

## Sequence / Application Flow Diagram

Use for: showing how a RAP action, validation, or OData call flows through layers.

```plantuml
@startuml
skinparam sequenceArrowThickness 1.5
skinparam responseMessageBelowArrow true
skinparam sequenceParticipant underline

actor "User / UI" as UI
participant "OData Service\n(SRVB)" as SRV
participant "Projection View\n(C_Entity)" as PROJ
participant "Behavior Pool\n(BP_R_Entity)" as BP
participant "Legacy / Helper\nClass" as HELPER

UI -> SRV : POST /Entity
SRV -> PROJ : EML: MODIFY
PROJ -> BP : validateXxx()
BP -> HELPER : checkCondition()
HELPER --> BP : result
BP --> PROJ : messages
PROJ --> SRV : response
SRV --> UI : HTTP 200 / error
@enduml
```

---

## CDS View Hierarchy Diagram

Use for: showing the VDM layer structure (Basic → Composite → Consumption).

```plantuml
@startuml
skinparam classAttributeIconSize 0

package "Basic Layer" {
  class "ZI_EntityName\n(Interface View)" as BASIC
}

package "Composite Layer" {
  class "ZR_EntityName\n(Base View)" as COMP
}

package "Consumption Layer" {
  class "ZC_EntityName\n(Projection View)" as CONS
}

package "Extension" {
  class "ZX_EntityName\n(Metadata Extension)" as MDX
}

BASIC <|-- COMP : extends
COMP <|-- CONS : extends
CONS .. MDX : annotates
@enduml
```

---

## Database Table Entity Diagram

Use for: showing database table fields, keys, and FK relationships.

```plantuml
@startuml

entity "ZA_TABLE_NAME" as T1 {
  * client : mandt <<PK>>
  * key_field : type <<PK>>
  --
  field_1 : type
  field_2 : type
}

entity "ZA_OTHER_TABLE" as T2 {
  * client : mandt <<PK>>
  * key_field : type <<PK>>
  --
  description : text
}

T1 ||--o{ T2 : "FK: key_field"
@enduml
```

---

## Class Diagram

Use for: showing ABAP classes, interfaces, inheritance, and key methods.

```plantuml
@startuml
skinparam classAttributeIconSize 0

interface "ZIF_ENTITY_HANDLER" as INTF {
  + process( ) : result
  + validate( ) : messages
}

class "ZCL_ENTITY_HANDLER" as IMPL {
  - attribute : type
  + process( ) : result
  + validate( ) : messages
  - helper_method( ) : void
}

class "ZBP_R_ENTITY\n(Behavior Pool)" as BP {
  + on_modify( ) : void
  + on_validate( ) : messages
}

IMPL ..|> INTF : implements
BP --> IMPL : uses
@enduml
```

---

## PlantUML Tips

- Long participant names: use `\n` for line breaks inside labels
- Omit arrows for passive dependencies; use dashed `..>` for optional/event-driven flows
- For tables with many fields: show only key fields and 3-4 most important fields; add `-- (N more fields) --` comment
- Keep diagrams focused — one diagram per concern; do not combine all four into one mega-diagram
