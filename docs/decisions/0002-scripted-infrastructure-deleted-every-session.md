# 0002. Lab infrastructure is scripted, and deleted at the end of every session

| | |
|---|---|
| Date | 2026-11-15 |
| Status | Accepted |

## Context

The labs create resources by clicking through the portal and end with "delete the resource group". That destroys the evidence of the work and makes it tempting to leave resources running so the next lab starts faster.

## Options considered

| Option | For | Against |
|---|---|---|
| Portal, as the labs describe | Matches the instructions exactly | Not repeatable; nothing is kept; easy to leave running |
| Scripted with the Azure CLI, from a config file | Repeatable in minutes; the script is the record; safe to delete after every session | The portal steps must still be understood for the exam |
| Bicep or Terraform from the start | Closer to production practice | More to learn before the first lab produces anything |

## Decision

Resources are created by `infra/provision.sh` from `labs-config.json` and deleted by `infra/teardown.sh` at the end of every session. Both scripts show a plan and do nothing unless `--execute` is given.

## Reasoning

If rebuilding takes two minutes, there is never a reason to leave anything running, and cost control stops depending on memory. The script is also a precise record of what a lab environment consists of, which the portal never gives. The Azure CLI was chosen over Bicep to start with because it maps one-to-one to the portal steps the exam asks about; Bicep is added when the material reaches it.

## Consequences

- Each lab is done twice in effect: once to understand the portal flow, once as code. That is deliberate.
- A model version must be chosen explicitly in the config, because "latest" is not reproducible.
- A deleted Foundry resource is soft-deleted; reusing its name immediately needs `teardown.sh --execute --purge`.

## How to reverse it

Nothing to reverse; the portal remains available for any step.
