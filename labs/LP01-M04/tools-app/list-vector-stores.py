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
