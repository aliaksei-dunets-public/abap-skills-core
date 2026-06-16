# Environment Detection

Use when the target ABAP environment is unclear or when ABAP Cloud, S/4HANA
Cloud, released-API restrictions, test seams, or legacy patterns may affect
test design.

## Categories and rules

| Environment | Rules |
|---|---|
| ABAP Cloud · SAP BTP ABAP · S/4HANA Cloud Public | Released APIs only. No unreleased frameworks or runtime internals. No legacy seams unless the project profile allows. Prefer interface-based seams, local fakes, or released test doubles. Strict DB-free, side-effect-free. |
| S/4HANA Cloud Private · S/4HANA on-premise · classic NetWeaver | Project conventions may allow local friends, test seams, or legacy helpers. Still prefer isolated, DB-free, deterministic tests. Do not use legacy patterns unless they are already present in the codebase or approved by the project profile. |

If the environment cannot be determined, generate conservative ABAP Unit code
and state the assumption.

## Signals to use when available

Repository metadata; package type / cloud-readiness; syntax errors from
unreleased APIs; existing local test classes; project profile; presence of
RAP/BDEF/released APIs; naming and package conventions; user-provided info.

## Project profile may override

Approved frameworks; `cl_abap_testdouble` policy; OSQL/CDS test environment
policy; local-friends pattern; test seam usage; naming; setup/teardown rules;
RAP draft conventions; helper or builder classes.

Apply project profile rules only when present and relevant.
