# LP01-M04: Tools app (file_search + web_search)

| Item | Value |
|---|---|
| Date run | 2026-11-24 |
| Microsoft lab file | Instructions/Exercises/04a-use-own-data.md |
| Reference commit | b702dc2 (2026-08-19) |
| Deployment used | gpt-5.4-mini |
| openai package version | |
| Files in vector store | |
| Start-up time | |

## 1. What this lab does

You build a chat app that gives the model two tools. `file_search` answers from six Margie's Travel brochures that the app uploads into a vector store. `web_search` answers from the live web. The app uses the Responses API and keyless sign-in, the same as Lab 03.

| Item | Value |
|---|---|
| Microsoft lab file | `Instructions/Exercises/04a-use-own-data.md` |
| Starter files | `labfiles/tools/python/tools-app` in `mslearn-ai-studio` |
| Your working folder | `~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app` |
| Conda environment | `ai103` (Python 3.13.18) |
| Foundry resource | `andy-2723-resource` in `rg-andy-6218` |
| Deployment | `gpt-5.4-mini` (the lab says `gpt-5.2`; you don't have that one) |
| Endpoint type | Azure OpenAI endpoint, not the project endpoint |

## 2. What I checked and what I did not

| Check | Result |
|---|---|
| Starter files read from Microsoft's repository at commit `b702dc2` | Done. `tools-app.py`, `.env`, `requirements.txt`, six PDFs in `brochures/` |
| Finished `tools-app.py` in this note compiles | Done |
| Finished file differs from the starter only where blank lines were replaced by lab code | Done |
| The SDK methods the lab calls exist (`vector_stores.create`, `file_batches.upload_and_poll`, `responses.create`) | Done, against `openai` 3.59.0 |
| The app run against your Azure resource | **Not done.** I can't reach your subscription. Section 9 is where you prove it |
| `gpt-5.4-mini` accepts both tools on your subscription tier | **Not known.** Section 11 has the fallback |
| The clean-up script run against Azure | **Not done.** It compiles and its SDK calls exist. Run it in plan mode first |

## 3. Differences from Microsoft's instructions

| Microsoft says | You do | Why |
|---|---|---|
| Clone the repository from VS Code | Skip. Copy the starter folder from your existing clone | The clone is already at `~/AI_DEV/pro/projects/mslearn-ai-studio` |
| Work inside `/labfiles/tools/python/tools-app` | Work in `labs/LP01-M04/tools-app` | Your work stays in your repository; Microsoft's clone stays untouched |
| Create a `.venv` | Use Conda `ai103` | One environment for all labs |
| Deployment `gpt-5.2` | `gpt-5.4-mini` | It is what you have deployed |
| `az login` | Check first; sign in only if the check fails, with `--use-device-code` | You are usually still signed in |
| Clean up: delete the resource group | **Do not.** Run the vector store clean-up in section 10 | You need the resource for the next labs |

## 4. Progress

- [ ] Section 5: Sign-in and deployment confirmed
- [ ] Section 6: Playground part done in the portal
- [ ] Section 7: Lab folder, `.env`, packages ready
- [ ] Stage 1: Imports added
- [ ] Stage 2: Client added
- [ ] Stage 3: Vector store code added
- [ ] Stage 4: Response with tools added
- [ ] Section 9: Both test questions answered
- [ ] Section 10: Vector stores cleaned up
- [ ] Section 12: Committed and pushed

## 5. Confirm sign-in and deployment

Open a new Ubuntu terminal. Do not activate Conda yet.

```bash
az account show --query name -o tsv
```

| Output | Meaning | Action |
|---|---|---|
| `Azure subscription 1` | Signed in | Continue |
| An error about `az login` | Token expired | Run the next command |

```bash
az login --use-device-code
```

Now confirm the resource and deployment still exist. The last lab failed because `.env` pointed at a resource that was gone.

```bash
az cognitiveservices account deployment list \
  --resource-group rg-andy-6218 \
  --name andy-2723-resource \
  --query "[].{deployment:name, model:properties.model.name, sku:sku.name, capacity:sku.capacity}" \
  -o table
```

Expected: a row for `gpt-5.4-mini` and a row for `gpt-5.4`.

If the command reports that the resource is not found, list what exists and send me the output before going further:

```bash
az cognitiveservices account list \
  --query "[].{name:name, resourceGroup:resourceGroup, location:location}" \
  -o table
```

## 6. Portal part: tools in the playground

This is the first half of Microsoft's lab. It takes five minutes and shows what the code will do.

| Step | Action |
|---|---|
| 1 | Open `https://ai.azure.com`. Confirm **New Foundry** is on |
| 2 | **Build** > **Deployments** > select `gpt-5.4-mini`. The playground opens |
| 3 | In **Instructions**, enter: `You are a travel assistant that provides information on travel services available from Margie's Travel.` |
| 4 | In chat, enter: `What are some recommended tourist activities in New York next month?` |
| 5 | Note the answer. It should be generic, with nothing specific to next month |
| 6 | Under **Tools**, select **Add** and add **web_search** |
| 7 | Ask the same question again. The answer should now cite current events |

If **web_search** is missing from the tool list or the second answer returns an error, write down the exact message. That tells us before any code runs whether your subscription allows the tool.

## 7. Set up the lab folder

### 7.1 Copy the starter files

```bash
cd ~/AI_DEV/pro/projects/ai103-labs
mkdir -p labs/LP01-M04
cp -r ~/AI_DEV/pro/projects/mslearn-ai-studio/labfiles/tools/python/tools-app labs/LP01-M04/
ls -la labs/LP01-M04/tools-app
ls labs/LP01-M04/tools-app/brochures | wc -l
```

Expected: `.env`, `requirements.txt`, `tools-app.py`, a `brochures` folder, and the number `6`.

### 7.2 Keep Microsoft's brochures out of your repository

The six PDFs are Microsoft's content and total 2.5 MB. This repository is the one you plan to make public, so they stay out of it. The copy command in 7.1 reproduces them whenever needed.

```bash
cd ~/AI_DEV/pro/projects/ai103-labs
printf '\n# Microsoft lab content, copied from mslearn-ai-studio\nlabs/LP01-M04/tools-app/brochures/\n' >> .gitignore
grep -c '^\.vscode/' .gitignore
```

If the last command prints `0`, the editor rule from Lab 03 never went in. Add it:

```bash
printf '\n# Editor settings\n.vscode/\n' >> .gitignore
```

### 7.3 Write the configuration

```bash
cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app
cat > .env <<'EOF'
AZURE_OPENAI_ENDPOINT="https://andy-2723-resource.openai.azure.com/openai/v1/"
MODEL_DEPLOYMENT="gpt-5.4-mini"
VECTOR_STORE_NAME="travel-brochures"
EOF
cat > .env.example <<'EOF'
AZURE_OPENAI_ENDPOINT="https://YOUR-RESOURCE-NAME.openai.azure.com/openai/v1/"
MODEL_DEPLOYMENT="YOUR-DEPLOYMENT-NAME"
VECTOR_STORE_NAME="travel-brochures"
EOF
cat .env
```

| Key | Used by | Note |
|---|---|---|
| `AZURE_OPENAI_ENDPOINT` | `tools-app.py`, clean-up script | Same value as Lab 03 |
| `MODEL_DEPLOYMENT` | `tools-app.py` | Deployment name, not model name |
| `VECTOR_STORE_NAME` | Clean-up script | Microsoft's lab code hardcodes `travel-brochures` in `tools-app.py`. I left the lab code as written so it matches the course. This key must hold the same name |

Confirm git ignores the two things that must not be committed:

```bash
cd ~/AI_DEV/pro/projects/ai103-labs
git check-ignore -v labs/LP01-M04/tools-app/.env
git check-ignore -v "labs/LP01-M04/tools-app/brochures/London Brochure.pdf"
```

Each command must print a line naming a `.gitignore` rule. No output means the file is not ignored. Stop and send me the result.

### 7.4 Activate the environment and install packages

```bash
conda activate ai103
which python
python --version
```

| Check | Must show |
|---|---|
| `which python` | `/home/andrewcollier/miniconda3/envs/ai103/bin/python` |
| `python --version` | `Python 3.13.18` |

If `which python` shows a `.pyenv/shims` path, stop. Close the terminal, open a new one, and run `conda activate ai103` again. Do not run `pip` until the path is right.

```bash
cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app
pip install -r requirements.txt
pip show openai | grep -i '^version'
```

The three packages were installed in Lab 03, so expect `Requirement already satisfied`. Record the `openai` version in your notes.

### 7.5 Open VS Code

Open it from a terminal where Conda is **not** activated. This is the rule from Lab 03.

```bash
conda deactivate
conda deactivate
code ~/AI_DEV/pro/projects/ai103-labs
```

In VS Code, open a terminal (`` Ctrl+` ``), then:

```bash
conda activate ai103
which python
cd labs/LP01-M04/tools-app
```

### 2026-11-27 09:36: Incorrect python path in VS Code
andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ conda activate ai103
(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ which python
==🔴/home/andrewcollier/.pyenv/shims/python==

#### Claude's Explanation
That path is wrong for the lab, and it is the same fault as in Lab 03. The `(ai103)` label was inherited, but pyenv's folder sits ahead of Conda's in this terminal's PATH. Your environments are not damaged; only this one terminal is affected.

Fix is below: 

(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP
01-M04/tools-app$ conda deactivate
andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ conda deactivate
andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ conda activate ai103
(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ which python
/home/andrewcollier/miniconda3/envs/ai103/bin/python
(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ python --version
Python 3.13.18
## 8. Add the code, in four stages

Open `labs/LP01-M04/tools-app/tools-app.py` in VS Code.

Rules for every stage:

| Rule | Detail |
|---|---|
| Replace, don't append | Each block below starts with the comment line that is already in the file. Select that comment line and the blank lines under it, then paste the block over them |
| Indentation is part of the code | Paste the block exactly as shown. Stage 1 starts at the left margin. Stages 2 and 3 are indented 8 spaces. Stage 4 is indented 12 spaces |
| Save after each stage | `Ctrl+S`, then run the check |
| The app is not run until all four stages are in | Stages 1 to 3 produce nothing useful alone |

If the indentation goes wrong at any point, skip to Appendix A. It writes the whole finished file in one command.

### Stage 1: Imports

Find `# Import namespaces` near the top. Replace it with:

```python
# Import namespaces
from openai import OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
```

Check:

```bash
grep -c 'from openai import OpenAI' tools-app.py
python -m py_compile tools-app.py && echo COMPILE_OK
```

Expected: `1`, then `COMPILE_OK`.

### Stage 2: Client

Find `# Initialize the OpenAI client` inside `main`. Replace it with:

```python
        # Initialize the OpenAI client
        token_provider = get_bearer_token_provider(
            DefaultAzureCredential(), "https://ai.azure.com/.default"
        )

        openai_client = OpenAI(
            base_url=azure_openai_endpoint,
            api_key=token_provider
        )
```

Check:

```bash
grep -c 'get_bearer_token_provider(' tools-app.py
grep -c 'openai_client = OpenAI(' tools-app.py
python -m py_compile tools-app.py && echo COMPILE_OK
```

Expected: `1`, `1`, `COMPILE_OK`.

| Line | What it does |
|---|---|
| `DefaultAzureCredential()` | Picks up your `az login` session. No key in the file |
| `"https://ai.azure.com/.default"` | The scope the token is issued for. Same as Lab 03 |
| `api_key=token_provider` | The SDK calls this function for a fresh token whenever it needs one |

### Stage 3: Vector store

Find `# Create vector store and upload files`. Replace it with:

```python
        # Create vector store and upload files
        print("Creating vector store and uploading files...")
        vector_store = openai_client.vector_stores.create(
            name="travel-brochures"
        )
        file_streams = [open(f, "rb") for f in glob.glob("brochures/*.pdf")]
        if not file_streams:
            print("No PDF files found in the brochures folder!")
            return
        file_batch = openai_client.vector_stores.file_batches.upload_and_poll(
            vector_store_id=vector_store.id,
            files=file_streams
        )
        for f in file_streams:
            f.close()
        print(f"Vector store created with {file_batch.file_counts.completed} files.")
```

Check:

```bash
grep -c 'vector_stores.create(' tools-app.py
grep -c 'upload_and_poll(' tools-app.py
python -m py_compile tools-app.py && echo COMPILE_OK
```

Expected: `1`, `1`, `COMPILE_OK`.

| Line | What it does |
|---|---|
| `vector_stores.create(name=...)` | Creates an empty vector store in your Foundry resource. **Every run of the app creates a new one** |
| `glob.glob("brochures/*.pdf")` | Finds the PDFs relative to the folder you run from. Run the app from `tools-app`, or it finds nothing |
| `upload_and_poll(...)` | Uploads the files, then waits until Azure has chunked and embedded them |
| `file_batch.file_counts.completed` | How many files finished. Must be 6 |

### Stage 4: Response with tools

Find `# Get a response using tools` inside the `while` loop. Replace it with:

```python
            # Get a response using tools
            response = openai_client.responses.create(
                model=model_deployment,
                instructions="""
                You are a travel assistant that provides information on travel services available from Margie's Travel.
                Answer questions about services offered by Margie's Travel using the provided travel brochures.
                Search the web for general information about destinations or current travel advice.
                """,
                input=input_text,
                previous_response_id=last_response_id,
                tools=[
                    {
                        "type": "file_search",
                        "vector_store_ids": [vector_store.id]
                    },
                    {
                        "type": "web_search"
                    }
                ]
            )
            print(response.output_text)
            last_response_id = response.id
```

Check:

```bash
grep -c '"type": "file_search"' tools-app.py
grep -c '"type": "web_search"' tools-app.py
grep -c 'last_response_id = response.id' tools-app.py
python -m py_compile tools-app.py && echo COMPILE_OK
```

Expected: `1`, `1`, `1`, `COMPILE_OK`.

| Line | What it does |
|---|---|
| `instructions=` | System prompt. Tells the model when to use brochures and when to use the web |
| `previous_response_id=last_response_id` | Carries the conversation, as in Lab 03 stage 3. This is why "there" in the second question means San Francisco |
| `tools=[...]` | The model decides per question which tool to call. You don't call them yourself |
| `"vector_store_ids": [vector_store.id]` | Points `file_search` at the store created in stage 3 |

## 9. Run and test

```bash
cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app
which python
python tools-app.py
```

Expected at start-up, after a wait of up to a minute:

```text
Creating vector store and uploading files...
Vector store created with 6 files.

Enter a question (or type "quit" to exit):
```

| #   | Enter                                           | Expected                                    | Tool it proves                         |
| --- | ----------------------------------------------- | ------------------------------------------- | -------------------------------------- |
| 1   | `What's happening in San Francisco next month?` | Dated, current events                       | `web_search`                           |
| 2   | `What hotels does Margie's Travel offer there?` | Hotel names from the San Francisco brochure | `file_search`, and conversation memory |
| 3   | `quit`                                          | Program ends                                |                                        |

Record in your notes: the file count, the first two lines of each answer, and how long start-up took.

### Response #1:
Creating vector store and uploading files...
Vector store created with 6 files.

Enter a question (or type "quit" to exit): What's happening in San Francisco next month?
A lot is happening in San Francisco next month — December 2026 is packed with holiday events. San Francisco Travel says the city’s holiday season runs from Thanksgiving weekend through the end of January, and highlights tree lightings, Illuminate SF, holiday dining, and New Year’s Eve plans. ([sftravel.com](https://www.sftravel.com/holidays))

Some notable December events include:
- Winter Walk in Union Square, December 13–22. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))
- SantaCon in Union Square, December 14. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))
- Illuminate SF, the citywide light festival, with Let’s Glow SF running December 6–15. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))
- Parol Lantern Festival and Parade at Yerba Buena Gardens. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))
- San Francisco Ballet’s Nutcracker at the War Memorial Opera House. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))
- Guardmen Tree Lot at Fort Mason, which runs through the month. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))
- Kung Pao Kosher Comedy in Chinatown, December 24–26. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))

Weather-wise, December in San Francisco is typically cool and mild, with highs around the upper 50s to low 60s °F and some chance of showers later in the month. ([accuweather.com](https://www.accuweather.com/en/us/san-francisco/94103/december-weather/347629))

If you want, I can also give you:
1. a day-by-day event calendar for December,
2. family-friendly picks,
3. free events only, or
4. what to do if you’re visiting for a weekend.

Enter a question (or type "quit" to exit): 

### Response #1B 
Enter a question (or type "quit" to exit): 4
If you’re visiting San Francisco for a weekend, Margie’s Travel’s brochure suggests two good hotel bases: the Lombard Hotel, which is within easy walking distance of the Golden Gate Bridge and the Presidio and includes free parking, and the Wharf Hotel, which is in Fisherman’s Wharf and includes continental breakfast. 

A simple weekend plan would be:
- Golden Gate Bridge and the Presidio area
- Fisherman’s Wharf
- Downtown/Union Square if you want to catch holiday events and shopping
- If you’re here in December, consider holiday highlights like Winter Walk in Union Square, Illuminate SF, SantaCon, and the San Francisco Ballet’s Nutcracker. ([sftravel.com](https://www.sftravel.com/article/san-francisco-festivals-events-december))

If you want, I can turn that into a 2-day itinerary and suggest which Margie’s Travel hotel fits it best.

### Response #2:
Margie’s Travel offers two San Francisco hotels in its brochure: the Lombard Hotel, a friendly family-run hotel within walking distance of the Golden Gate Bridge and the Presidio, with free parking, and the Wharf Hotel, a great-value option in Fisherman’s Wharf with continental breakfast included. 

If you’d like, I can also help compare them for a weekend trip.

### 9B. Commit Changes

```bash
cd ~/AI_DEV/pro/projects/ai103-labs
git status --short
git add .gitignore \
  labs/LP01-M04/tools-app/.env.example \
  labs/LP01-M04/tools-app/requirements.txt \
  labs/LP01-M04/tools-app/tools-app.py
git diff --cached --name-only
```
```bash
git commit -m "LP01-M04: tools app with file_search and web_search"
git push
git status --short
git log -1 --format='%h %s'
```

### 9C. View AI Azure Resources to View Uploaded Files and Vector DBs before Cleanup Step 10

### Where the vector stores and files are

They are in Azure, inside the Foundry resource `andy-2723-resource`. Nothing is stored in WSL except the original PDFs in `brochures/`.

|Object|What it is|Count to expect|
|---|---|---|
|Uploaded file|A copy of each PDF, held by the resource|6 per run of the app|
|Vector store|The chunked, embedded index over those files, named `travel-brochures`|1 per run of the app|

#### In the portal

| Step | Action                                                           |
| ---- | ---------------------------------------------------------------- |
| 1    | Open `https://ai.azure.com` with **New Foundry** on              |
| 2    | Select Resource Name (i.e., andy-2723) - not the Parent Resource |
| 3    | Select **Build** in the top menu                                 |
| 4    | Select **Data** in the left pane                                 |
| 5    | Select **Files**                                                 |

##### 2026-11-27 12:31: File(s) and Vector DB(s) Don't Exist

![[Pasted image 20261127123227.png|462]]![[Pasted image 20261127123305.png|466]]

###### Claude's Response
The empty portal pages don't yet tell us whether the stores exist. There are two possible explanations, and the terminal listing separates them.

|Explanation|How it would happen|
|---|---|
|The stores exist, but this page doesn't show them|The page is scoped to the project `andy-2723`. Your app created the stores through the Azure OpenAI endpoint of the resource, not through the project endpoint. The portal may only list project-scoped data. I have not confirmed this is how the page behaves|
|The stores don't exist|The app never got as far as `Vector store created with 6 files.` I haven't seen the output of a run, so I can't rule this out|

##### Settle it from the terminal - execute list-vector-stores.pyp

The listing script asks the same endpoint the app used, so it will show the stores if they exist.

bash

```bash
cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app
cat > list-vector-stores.py <<'EOF'
"""List every vector store on the resource and the files in each. Read-only.

Reads AZURE_OPENAI_ENDPOINT from .env.
"""
import os
import sys

from dotenv import load_dotenv
from openai import OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider


def main():
    load_dotenv()
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    if not endpoint:
        print("FAIL  AZURE_OPENAI_ENDPOINT must be set in .env")
        return 1

    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(), "https://ai.azure.com/.default"
    )
    client = OpenAI(base_url=endpoint, api_key=token_provider)

    stores = list(client.vector_stores.list())
    print(f"Vector stores on this resource: {len(stores)}")
    for store in stores:
        print(f"\n{store.id}  name={store.name}  status={store.status}  bytes={store.usage_bytes}")
        for item in client.vector_stores.files.list(vector_store_id=store.id):
            try:
                filename = client.files.retrieve(item.id).filename
            except Exception as ex:
                filename = f"(name not available: {ex})"
            print(f"    {item.id}  {item.status}  {filename}")

    all_files = list(client.files.list())
    print(f"\nUploaded files on this resource (all): {len(all_files)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
EOF

cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app
which python
python list-vector-stores.py
```


|Result|Meaning|Next step|
|---|---|---|
|`Vector stores on this resource: 1` or more, each with 6 files|They exist. The portal page does not show resource-level stores|Record the output in `NOTES.md`, then run section 10|
|`Vector stores on this resource: 0`|Nothing was created|Send me what `python tools-app.py` printed when you ran it|
|An error|Sign-in or endpoint problem|Send me the error text|

##### Results of Vector DB and Files Listing
(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ python list-vector-stores.py
Vector stores on this resource: 1

vs_T4WFgGkBv1TfIOaM95Y9UlFw  name=travel-brochures  status=completed  bytes=13827
    assistant-T9k1VAizAWmymNnznUk9h9  completed  New York Brochure.pdf
    assistant-3wfwHxe2JauGBLxWhqNmsN  completed  Dubai Brochure.pdf
    assistant-KQcmLqzJhWqTx6GNGVbWy6  completed  San Francisco Brochure.pdf
    assistant-BjyveeHVd567JZQjbHMpE6  completed  Margies Travel Company Info.pdf
    assistant-JaGkaLfvwQGkztEMvgU1jW  completed  London Brochure.pdf
    assistant-6TQo7pB4H5fvtjRZbJALhs  completed  Las Vegas Brochure.pdf

Uploaded files on this resource (all): 6

###### 2026-11-27 13:25: Claude's Assessment of Listing
The store exists: one vector store with all six brochures, from one run of the app. The portal's **Data** page does not show it, so that page is not a reliable inventory of what the resource holds.

##### What the output shows

|Item|Value|Meaning|
|---|---|---|
|Vector stores|1|You ran `tools-app.py` once|
|Store name and status|`travel-brochures`, `completed`|Indexing finished|
|Store size|13,827 bytes|About 14 KB of index from 2.5 MB of PDFs. Storage cost at this size is negligible|
|Files in the store|6, all `completed`|Every brochure was indexed|
|Uploaded files on the resource|6|No strays from other runs|

One correction to what I told you: the file IDs start with `assistant-`, not `file-` as I wrote in the earlier table.

##### Why the portal is empty

The exact mechanism is not confirmed. What the evidence shows is that data created through the Azure OpenAI endpoint with the OpenAI SDK did not appear in the project's **Data > Files** or **Data > Vector stores** tabs. The likely reason is that those tabs list project-scoped data only. Either way, the practical rule for client work is to list through the endpoint that created the data, and not to treat an empty portal page as proof that nothing is stored.

##### Next steps

1. Following instruction in Setp 12.1 Lab Notes below, create the NOTES.md file
2. Paste the listing into `labs/LP01-M04/NOTES.md` as the "before" record.
3. Run section 10 of the runbook: create `cleanup-vector-stores.py`, run it in plan mode, then with `--execute`.
4. Run `python list-vector-stores.py` again for the "after" record.

|Step|Expected|
|---|---|
|Plan mode|One line for `vs_T4WF…` with `files=6`, then `Plan only. Nothing deleted.`|
|`--execute`|`Remaining after delete: 0 failures: 0`|
|Listing afterward|`Vector stores on this resource: 0` and `Uploaded files on this resource (all): 0`|

The clean-up script has not been run against Azure before, so send me the output of the plan and the delete if either differs from this.

I still haven't seen the answers to the two test questions in section 9. If both worked, note in `NOTES.md` that `gpt-5.4-mini` handled `web_search` and `file_search` on your subscription. That settles the open question from section 2 of the runbook.


That path comes from a Microsoft Q&A answer dated November 2025, which directs users to Build, then Data, then Files for Azure OpenAI files. The portal has changed since, so it may have moved. I found no confirmed location for vector stores in the new portal; look for a **Vector stores** tab next to **Files**. If neither shows your data, the script below is the reliable route, because it asks the same endpoint that created them. [microsoft](https://learn.microsoft.com/en-us/answers/questions/5635089/where-can-i-find-my-azure-openai-files-in-the-new)



Paste the output into `NOTES.md` before running section 10, so you have a before-and-after record. The IDs are not secrets, but they are meaningless once deleted, so the counts are what matter.

If you keep `list-vector-stores.py`, commit it along with `cleanup-vector-stores.py` after section 10.


## 10. Clean up vector stores

Each run leaves a vector store and six uploaded files in your resource. They are small, but stored data is billed once it passes the free allowance, and they pile up with every run. Microsoft's lab does not remove them.

Create the clean-up script. It reads its settings from `.env`, lists by default, and deletes only with `--execute`.

```bash
cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app
cat > cleanup-vector-stores.py <<'EOF'
"""List or delete the vector stores this lab creates.

Reads AZURE_OPENAI_ENDPOINT and VECTOR_STORE_NAME from .env.
Default is plan mode (list only). Add --execute to delete.
"""
import os
import sys

from dotenv import load_dotenv
from openai import OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider


def main():
    execute = "--execute" in sys.argv[1:]

    load_dotenv()
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    store_name = os.getenv("VECTOR_STORE_NAME")
    if not endpoint or not store_name:
        print("FAIL  AZURE_OPENAI_ENDPOINT and VECTOR_STORE_NAME must both be set in .env")
        return 1

    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(), "https://ai.azure.com/.default"
    )
    client = OpenAI(base_url=endpoint, api_key=token_provider)

    stores = [s for s in client.vector_stores.list() if s.name == store_name]
    print(f"Vector stores named '{store_name}': {len(stores)}")
    if not stores:
        return 0

    failures = 0
    for store in stores:
        file_ids = [f.id for f in client.vector_stores.files.list(vector_store_id=store.id)]
        print(f"  {store.id}  files={len(file_ids)}  bytes={store.usage_bytes}")
        if not execute:
            continue
        for file_id in file_ids:
            try:
                client.files.delete(file_id)
            except Exception as ex:
                failures += 1
                print(f"    FAIL  file {file_id}: {ex}")
        try:
            client.vector_stores.delete(store.id)
            print("    deleted")
        except Exception as ex:
            failures += 1
            print(f"    FAIL  store {store.id}: {ex}")

    if not execute:
        print("Plan only. Nothing deleted. Run again with --execute to delete.")
        return 0

    remaining = [s for s in client.vector_stores.list() if s.name == store_name]
    print(f"Remaining after delete: {len(remaining)}  failures: {failures}")
    return 1 if (remaining or failures) else 0


if __name__ == "__main__":
    sys.exit(main())
EOF
python -m py_compile cleanup-vector-stores.py && echo COMPILE_OK
```

Plan first:

```bash
python cleanup-vector-stores.py
```

Expected: one line per run of the app, each with `files=6`, then `Plan only. Nothing deleted.`

Then delete:

```bash
python cleanup-vector-stores.py --execute
```

Expected last line: `Remaining after delete: 0  failures: 0`.

This script has not been run against Azure. If the plan output or the delete output differs from the above, send it to me.

## 11. If something fails

| Symptom | Likely cause | Action |
|---|---|---|
| `Connection error.` | `.env` endpoint points at a resource that no longer exists | Rerun the deployment listing in section 5. Fix `.env` |
| `No PDF files found in the brochures folder!` | App run from the wrong folder, or brochures not copied | `pwd` must end in `tools-app`. `ls brochures` must show 6 files |
| `Vector store created with` fewer than 6 files | An upload failed on Azure's side | Run clean-up, then run the app again. If it repeats, send me the number |
| Error naming `web_search` as unsupported or not allowed | The tool is not available for this model, region or subscription tier | See the isolation test below |
| Error naming `file_search` or `vector_stores` | Same, for the file tool | Send me the full error text |
| `401` or `403` | Sign-in expired, or your account lacks a data-plane role on the resource | `az account show --query name -o tsv`. If signed in and it still fails, send me the error |
| `429` | Rate limit on the deployment | Wait one minute and retry |
| `DeploymentNotFound` | `MODEL_DEPLOYMENT` does not match a deployment name | Compare with the section 5 listing |
| Prompt returns with no answer | A stage is missing | Rerun all the `grep -c` checks in section 8 |

**Isolation test for a tool error.** To find which tool is failing, temporarily remove the `web_search` entry so the `tools` list holds only `file_search`, save, and run question 2. If that works, `file_search` is fine and the problem is `web_search` alone. Put the entry back afterward.

**Model fallback.** If `gpt-5.4-mini` rejects a tool, change one line in `.env` to `MODEL_DEPLOYMENT="gpt-5.4"` and rerun. It costs more per token, so use it for this test and go back to the mini model after.

**Cost.** This lab spends against your $200 credit in three ways: model tokens, web search calls, and vector storage. All three should be small for two questions. Check **Cost Management** in the Azure portal the day after and note the figure.

## 12. Record and commit

### 12.1 Lab notes

```bash
cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04
cat > NOTES.md <<'EOF'
# LP01-M04: Tools app (file_search + web_search)

| Item | Value |
|---|---|
| Date run | 2026-11-24 |
| Microsoft lab file | Instructions/Exercises/04a-use-own-data.md |
| Reference commit | b702dc2 (2026-08-19) |
| Deployment used | gpt-5.4-mini |
| openai package version | |
| Files in vector store | |
| Start-up time | |

## Results

| Question | Tool expected | Result |
|---|---|---|
| What's happening in San Francisco next month? | web_search | |
| What hotels does Margie's Travel offer there? | file_search | |

## What I learned

-

## Problems and fixes

| Problem | Cause | Fix |
|---|---|---|
| | | |

## Clean-up

| Check | Result |
|---|---|
| Vector stores before clean-up | |
| Remaining after clean-up | |
EOF
```

Fill in the blanks in VS Code before committing.

### 12.2 Commit

```bash
cd ~/AI_DEV/pro/projects/ai103-labs
git status --short
git add .gitignore labs/LP01-M04
git diff --cached --name-only
```

The staged list must be exactly these six files:

| File | |
|---|---|
| `.gitignore` | |
| `labs/LP01-M04/NOTES.md` | |
| `labs/LP01-M04/tools-app/.env.example` | |
| `labs/LP01-M04/tools-app/cleanup-vector-stores.py` | |
| `labs/LP01-M04/tools-app/requirements.txt` | |
| `labs/LP01-M04/tools-app/tools-app.py` | |

If `.env` or any PDF appears in the list, stop. Run `git reset` and send me the list.

```bash
git commit -m "LP01-M04: tools app with file_search and web_search"
git push
git status --short
```

Expected after the push: `git status --short` prints nothing, unless Lab 03 files are still uncommitted.

## 13. What to take from this lab for the exam

| Concept | Point |
|---|---|
| Tools in the Responses API | Passed as a `tools` list on each `responses.create` call. The model chooses whether to call them |
| `file_search` | Built-in retrieval over a vector store. Azure chunks, embeds and searches. You write no retrieval code |
| `web_search` | Built-in grounding on current web content |
| Vector store | Lives in the Foundry resource, not on your machine. Created through the same client as the model call |
| Grounding | The reason for both tools: answers come from supplied data, not only from training data |
| Endpoint | Azure OpenAI endpoint, because the app uses the OpenAI SDK |
| Authentication | Entra ID through `DefaultAzureCredential`. Preferred over API keys |

## Appendix A: Complete `tools-app.py`

Use this if a stage leaves the file with an indentation error. It overwrites the file with the finished version.

```bash
cd ~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app
cat > tools-app.py <<'EOF'
import os
from dotenv import load_dotenv
import glob

# Import namespaces
from openai import OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider


def main():
    # Clear the console
    os.system('cls' if os.name == 'nt' else 'clear')

    try:
        # Get configuration settings
        load_dotenv()
        azure_openai_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        model_deployment = os.getenv("MODEL_DEPLOYMENT")

        # Initialize the OpenAI client
        token_provider = get_bearer_token_provider(
            DefaultAzureCredential(), "https://ai.azure.com/.default"
        )

        openai_client = OpenAI(
            base_url=azure_openai_endpoint,
            api_key=token_provider
        )

        # Create vector store and upload files
        print("Creating vector store and uploading files...")
        vector_store = openai_client.vector_stores.create(
            name="travel-brochures"
        )
        file_streams = [open(f, "rb") for f in glob.glob("brochures/*.pdf")]
        if not file_streams:
            print("No PDF files found in the brochures folder!")
            return
        file_batch = openai_client.vector_stores.file_batches.upload_and_poll(
            vector_store_id=vector_store.id,
            files=file_streams
        )
        for f in file_streams:
            f.close()
        print(f"Vector store created with {file_batch.file_counts.completed} files.")

        # Track conversation state
        last_response_id = None

        # Loop until the user wants to quit
        while True:
            input_text = input('\nEnter a question (or type "quit" to exit): ')
            if input_text.lower() == "quit":
                break
            if len(input_text) == 0:
                print("Please enter a question.")
                continue

            # Get a response using tools
            response = openai_client.responses.create(
                model=model_deployment,
                instructions="""
                You are a travel assistant that provides information on travel services available from Margie's Travel.
                Answer questions about services offered by Margie's Travel using the provided travel brochures.
                Search the web for general information about destinations or current travel advice.
                """,
                input=input_text,
                previous_response_id=last_response_id,
                tools=[
                    {
                        "type": "file_search",
                        "vector_store_ids": [vector_store.id]
                    },
                    {
                        "type": "web_search"
                    }
                ]
            )
            print(response.output_text)
            last_response_id = response.id

    except Exception as ex:
        print(ex)

if __name__ == '__main__':
    main()
EOF
python -m py_compile tools-app.py && echo COMPILE_OK
```

## Version history

| Version | Date | Change |
|---|---|---|
| v1 | 2026-11-24 | First issue. Built against Microsoft commit `b702dc2`. Code compiled; not run against Azure |

# 2026-11-27 15:16: The Only Place the Uploaded Files and created Vector DBs can be found are in the old AI Azure Foundry

![[Pasted image 20261127151721.png]]

![[Pasted image 20261127151816.png]]

### 2026-11-27 15:34: Final Cleanup of Uploaded Files and created Vector DB

app$ which python
/home/andrewcollier/miniconda3/envs/ai103/bin/python
(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ python cleanup-vector-stores.py
Vector stores named 'travel-brochures': 1
  vs_T4WFgGkBv1TfIOaM95Y9UlFw  files=6  bytes=13827
Plan only. Nothing deleted. Run again with --execute to delete.
(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ python cleanup-vector-stores.py --execute
Vector stores named 'travel-brochures': 1
  vs_T4WFgGkBv1TfIOaM95Y9UlFw  files=6  bytes=13827
    deleted
Remaining after delete: 0  failures: 0
(ai103) andrewcollier@CollierAssociates:~/AI_DEV/pro/projects/ai103-labs/labs/LP01-M04/tools-app$ python cleanup-vector-stores.py
Vector stores named 'travel-brochures': 0

# 2026-11-27 15:35: Finalize Lab & Commit

```bash
cd ~/AI_DEV/pro/projects/ai103-labs
git add labs/LP01-M04/tools-app/cleanup-vector-stores.py labs/LP01-M04/tools-app/list-vector-stores.py
git diff --cached --name-only
git commit -m "LP01-M04: vector store listing and clean-up scripts"
git push
git status --short
```