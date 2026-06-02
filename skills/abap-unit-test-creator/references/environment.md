# Environment Detection for ABAP Unit Test Authoring

Use this reference when the target ABAP environment is unclear or when ABAP Cloud,
S/4HANA Cloud, released API restrictions, test seams, or legacy/on-premise
patterns may affect test design.

## Environment Categories

Before choosing patterns, determine the target environment as accurately as
possible:

- ABAP Cloud;
- SAP BTP ABAP Environment;
- S/4HANA Cloud Public Edition;
- S/4HANA Cloud Private Edition;
- S/4HANA on-premise;
- classic NetWeaver ABAP.

If the environment cannot be determined, generate conservative ABAP Unit code and
state the assumption.

## ABAP Cloud and Public Cloud Rules

If the environment is ABAP Cloud, SAP BTP ABAP Environment, or S/4HANA Cloud
Public Edition:

- use only released APIs;
- avoid unreleased frameworks;
- avoid legacy test seams unless explicitly allowed;
- prefer interface-based dependency seams;
- prefer local fakes or released test double strategies;
- avoid patterns that require direct access to unreleased runtime internals;
- be strict about DB-free and side-effect-free tests.

## S/4HANA Private Cloud, On-Premise, and Classic ABAP Rules

If the environment is S/4HANA Cloud Private Edition, S/4HANA on-premise, or
classic NetWeaver ABAP:

- project conventions may allow broader patterns;
- local friends, test seams, or legacy helper frameworks may be available;
- still prefer isolated, DB-free, deterministic tests;
- do not use broader legacy patterns unless they are already present or approved
  by the project profile.

## Environment Signals

Use these signals when available:

- repository metadata;
- package type and cloud-readiness restrictions;
- syntax errors from unreleased APIs;
- existing local test classes;
- project profile;
- usage of RAP, behavior definitions, and released APIs;
- naming and package conventions;
- user-provided environment information.

## Project Profile Overrides

A project profile may override generic decisions about:

- approved test frameworks;
- allowed use of `cl_abap_testdouble`;
- allowed use of `cl_osql_test_environment` or `cl_cds_test_environment`;
- local-friends patterns;
- test seam usage;
- naming conventions;
- setup/teardown rules;
- RAP draft testing conventions;
- helper or builder classes.

Apply project profile rules only when they are present and relevant.
