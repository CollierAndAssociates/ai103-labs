# 0001. Authenticate with Entra ID, never with keys

| | |
|---|---|
| Date | 2026-11-15 |
| Status | Accepted |

## Context

The first lab has the learner copy an API key from the portal. The same lab notes that production systems should use Microsoft Entra ID. Keys are the fastest path in a lab and the most common path to a leaked credential in a public repository.

## Options considered

| Option | For | Against |
|---|---|---|
| Keys in a `.env` file | Matches the lab text; works everywhere | One accidental commit publishes a credential; keys do not identify who acted; rotation is manual |
| Entra ID through `az login` and `DefaultAzureCredential` | Nothing to leak; the same code works locally and with a managed identity in Azure | Needs a role assignment; slightly more to understand |

## Decision

All scripts and lab code authenticate with the signed-in identity. No script prints a key, and no key is stored in this repository or its config.

## Reasoning

This repository is public. The only reliable way to never publish a key is to never have one in the working folder. It is also the pattern a client's security review will expect, so practising it in the labs builds the habit that matters.

## Consequences

- The signed-in identity needs an appropriate role on the Foundry resource.
- Where a lab step truly requires a key, that step is done in the portal and noted in the lab's `NOTES.md`, not scripted.

## How to reverse it

Add key retrieval to `status.sh`. Not recommended for a public repository.
