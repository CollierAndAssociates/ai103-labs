# Environment setup

One-time setup on Linux or WSL2 (Ubuntu). Each step ends with a check.

## 1. Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az version
```

## 2. Sign in

```bash
az login --use-device-code
az account list --query '[].{name:name, id:id, isDefault:isDefault}' -o table
```

Use a subscription reserved for study if you can. It keeps lab spending and lab mistakes away from anything that matters.

## 3. jq

```bash
sudo apt-get install -y jq && jq --version
```

## 4. Config

```bash
cp labs-config.example.json labs-config.json
# edit labs-config.json: replace every REPLACE value
bash infra/check-config.sh
```

`foundry.resourceName` must be globally unique: it becomes the subdomain of the endpoint.

## 5. Budget alert

Before the first `provision.sh --execute`, create a budget with an alert on the subscription (Azure portal, Cost Management, Budgets). A forgotten deployment is the usual cause of an unexpected bill.

## 6. Python

The labs were tested by Microsoft on Python 3.13; some dependencies were not yet built for 3.14 at the time of writing.

```bash
conda env create -f environment.yml
conda activate ai103
python --version
```

Packages are added to `environment.yml` as the labs need them, so the file always describes a working environment.

## 7. Editor

Open the repository from the Linux side (`code .` from the repository folder in WSL) so the terminal, interpreter and git all run in Linux.

The Foundry Toolkit extension for VS Code is used in the first lab. If it misbehaves in a WSL-connected window, open a second, local VS Code window for the Toolkit's playground and keep the code in WSL.

## How authentication works here

`az login` signs you in. Scripts use that session. Lab code uses `DefaultAzureCredential`, which finds the same session. No key is read, printed or stored. See `docs/decisions/0001`.

## A session, start to finish

```bash
bash infra/provision.sh              # read the plan
bash infra/provision.sh --execute
bash infra/status.sh
#   ... do the lab; write labs/<module>/NOTES.md ...
bash infra/teardown.sh --execute
```
