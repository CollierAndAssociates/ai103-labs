# ai103-labs

Scripted Azure infrastructure, lab notes and reusable patterns from working through the Microsoft AI-103 learning paths (Azure AI apps and agents with Microsoft Foundry).

| | |
|---|---|
| Author | Andy Collier |
| Started | 2026-11-15 |
| Runs on | Linux or WSL2, bash, Azure CLI, Python 3.13 |
| Status | **In progress. Learning path 1: the LP01-M03 lab was completed on 2026-11-22; LP01-M04 is next. No certification is claimed.** Progress is tracked in `docs/curriculum.md` |

## Why this repository exists

The official labs are done by clicking through a portal and then deleting everything. That teaches the product, but it leaves nothing behind and nothing repeatable. This repository does the same labs a different way:

- **Infrastructure is scripted.** One command creates the lab environment from a config file; one command deletes it. A lab can be rebuilt in minutes, so nothing has to be left running.
- **Identity over keys.** Scripts and code authenticate with the signed-in Microsoft Entra identity. No key is printed, stored or committed.
- **Every lab leaves notes.** What the lab covers, what actually happened, what differed from the instructions, and what is worth remembering.
- **Decisions are recorded.** `docs/decisions/` explains each engineering choice, so the reasoning can be reviewed, not just the result.

## Progress

| Module | Lab | State |
|---|---|---|
| LP01-M03 | Develop a generative AI chat app with Microsoft Foundry | Lab completed 2026-11-22. Code in `labs/LP01-M03/chat-app/`; `NOTES.md` still to be written |
| LP01-M04 | Develop generative AI apps that use tools | Starting 2026-11-23 |

What the LP01-M03 code shows, in the order it was built:

| Stage | API | What it adds |
|---|---|---|
| 1 | ChatCompletions | A single-turn chat call. No conversation memory |
| 2 | Responses | Conversation context held by the service, chained with `previous_response_id` |
| 3 | Responses, streaming | Output printed as it arrives (`chat-app.py`) |
| Async | Responses with `AsyncOpenAI` | The same chat loop on the asynchronous client (`chat-async.py`) |

Both apps authenticate with the signed-in Entra identity through a bearer token provider, and read the endpoint and deployment name from `.env` (see `.env.example`). Neither contains a key or an endpoint.

## Quick start

```bash
git clone <this repository> && cd ai103-labs
cp labs-config.example.json labs-config.json      # then replace every REPLACE value
bash infra/check-config.sh                         # validates the config and your az sign-in
bash infra/list-models.sh gpt-5                    # find a model version available in your region
bash infra/provision.sh                            # PLAN: shows what would be created
bash infra/provision.sh --execute                  # creates it
bash infra/status.sh                               # what exists, and the endpoint
bash infra/teardown.sh --execute                   # delete everything when the session ends
```

Setup details, including the Azure CLI and the Python environment, are in `docs/environment.md`.

## Configuration

Every Azure name, region, model and capacity lives in `labs-config.json`. No script contains one.

| To change… | Edit this key |
|---|---|
| Subscription, region, resource group, tags | `azure.*` |
| The Foundry resource and project names | `foundry.resourceName`, `foundry.projectName` |
| Which models are deployed, and their version, type and capacity | `deployments.items` |
| The Python version and environment name | `python.*` |

`labs-config.json` is git-ignored because it names your subscription. Only `labs-config.example.json` is committed. The config is found at `LABS_CONFIG` if that environment variable is set, otherwise in the repository root.

## Contents

| Path | What it is | Changes anything? |
|---|---|---|
| `labs-config.example.json` | Template for your config | n/a |
| `lib/config.sh` | Loads and validates the config; refuses values still marked REPLACE | No |
| `infra/check-config.sh` | Shows every resolved value and the Azure sign-in state | No |
| `infra/list-models.sh` | Lists versions and deployment types available for a model in your region | No |
| `infra/provision.sh` | Creates resource group, Foundry resource, project and model deployments. Plan by default | Only with `--execute` |
| `infra/status.sh` | Lists what exists and the endpoint. Prints no keys | No |
| `infra/teardown.sh` | Deletes the resource group. Plan by default; asks you to type the name | Only with `--execute` |
| `environment.yml` | Conda environment for lab code | n/a |
| `docs/curriculum.md` | The four learning paths and thirty modules, with progress | n/a |
| `docs/environment.md` | One-time setup and cost control | n/a |
| `docs/decisions/` | Why things are done this way | n/a |
| `labs/` | One folder per module: notes and code | n/a |
| `labs/LP01-M03/chat-app/` | Chat app on the OpenAI SDK against a Foundry model deployment: synchronous with streaming, and asynchronous | Calls the deployed model |

## Cost control

The resources bill while they exist, whether or not they are used.

1. `bash infra/status.sh` shows exactly what is being billed.
2. `bash infra/teardown.sh --execute` at the end of every session.
3. Set a budget alert on the subscription before the first `--execute`.
4. Use only synthetic or public data. Never put real or client data in a lab environment.

## Validation status

A blank row means written and reviewed, not yet run against Azure.

| Script | First successful run | Notes |
|---|---|---|
| `infra/check-config.sh` | | Exercised against a stand-in for the Azure CLI on 2026-11-15 |
| `infra/provision.sh` (plan) | | Same |
| `infra/provision.sh --execute` | | Not yet run against Azure |
| `infra/list-models.sh` | | Not yet run; the output shape of the model list should be confirmed |
| `infra/status.sh` | | Not yet run |
| `infra/teardown.sh` | | Plan path exercised; delete path not yet run |

## Known gaps

| Gap | Closes when |
|---|---|
| The `infra/` scripts have no recorded run against a real subscription | The first provision, status and teardown cycle is recorded above |
| The example model version is a placeholder | `list-models.sh` confirms what the region offers |
| Working client code exists only inside the LP01-M03 lab folder | The client setup (token provider, endpoint and deployment from config) is extracted into shared code |
| Lab notes for the modules worked so far are not written | Each module's `NOTES.md` is completed and its row in `docs/curriculum.md` is updated |
| No automated checks | A workflow lints the shell scripts and the Python code on every push |
| Infrastructure is Azure CLI only | A Bicep version is added when the learning path reaches infrastructure as code |
| No license file, and no copy of the MIT notice for the Microsoft starter files | A license is chosen for the original work and the MIT notice is added beside the starter-derived files |

## About the lab content

The learning paths, module titles and lab instructions are Microsoft's and are published on Microsoft Learn. This repository links to them and does not reproduce them.

Lab code starts from Microsoft's starter files where a lab provides them. The files in `labs/LP01-M03/chat-app/` began as the starter files from `MicrosoftLearning/mslearn-ai-studio` (MIT license, commit `b702dc2`) and were then completed stage by stage; the git history shows each change. The infrastructure scripts, notes and decision records are original work.

## History

| Date | Change |
|---|---|
| 2026-11-15 | Repository created: config, scripted provision/status/teardown, curriculum tracker, environment guide, first two decision records |
| 2026-11-20 | LP01-M03 starter files added |
| 2026-11-22 | LP01-M03 lab completed: ChatCompletions, then the Responses API with conversation context, streaming, and an asynchronous client |
| 2026-11-23 | README brought up to date; LP01-M04 started |
