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
