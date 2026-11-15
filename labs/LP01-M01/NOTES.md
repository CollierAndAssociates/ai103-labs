# LP01-M01: Plan and prepare to develop AI solutions on Azure

| | |
|---|---|
| Learning path | Develop generative AI apps in Azure |
| Module on Microsoft Learn | to be linked when started |
| Date completed | not started |
| Time taken | |
| Quiz score | |

## What this module is about

Not started. The module's hands-on exercise creates a Foundry project, deploys a model, tests it in a playground, and connects VS Code to the project.

## Plan for this lab

The exercise is done in the portal. Here it is done twice: once as written, to learn the portal flow, and once from `infra/provision.sh`, to prove the same environment can be created from the config.

| Lab step | Portal | Scripted equivalent |
|---|---|---|
| Create a Foundry project | New Foundry, create project | `provision.sh`: resource group, Foundry resource with project management, project |
| Deploy a model | Model catalog, Deploy | `deployments.items` in the config; `list-models.sh` to choose the version |
| Test in the playground | Portal | Portal (nothing to script) |
| Find the endpoints | Manage, and the project home page | `status.sh` |
| Connect VS Code | Foundry Toolkit extension | See `docs/environment.md`, step 7 |
| Clean up | Delete the resource group | `teardown.sh --execute` |

## Concepts to be able to explain

| Concept | In one sentence | Where it matters in practice |
|---|---|---|
| Foundry resource versus project | to be written from the lab | |
| Resource endpoint, project endpoint, Azure OpenAI endpoint | to be written from the lab | |
| Key authentication versus Entra ID | to be written from the lab | |
| Model deployment | to be written from the lab | |

## Where reality differed from the instructions

To be recorded during the lab.

## Cleanup

- [ ] `bash infra/teardown.sh --execute`
