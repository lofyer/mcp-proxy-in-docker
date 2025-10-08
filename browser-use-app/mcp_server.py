#!/usr/bin/env python3
"""
Browser-Use MCP Server with Custom Model Support

This script starts the browser-use MCP server with customizable LLM configuration.
Modify the configuration section below to use your preferred model.

Environment Variables:
  - MODEL_NAME: Model name (default: gpt-4o-mini)
  - MODEL_PROVIDER: Provider type - openai, anthropic, google, azure, ollama (default: openai)
  - API_KEY: API key for the model provider
  - BASE_URL: Custom API endpoint (optional, for OpenAI-compatible APIs)
  - OPENAI_API_KEY: OpenAI API key (alternative to API_KEY)
  - ANTHROPIC_API_KEY: Anthropic API key (alternative to API_KEY)
  - GOOGLE_API_KEY: Google API key (alternative to API_KEY)

Examples:
  # Use OpenAI GPT-4
  MODEL_PROVIDER=openai MODEL_NAME=gpt-4 OPENAI_API_KEY=xxx python mcp_server.py

  # Use Anthropic Claude
  MODEL_PROVIDER=anthropic MODEL_NAME=claude-sonnet-4-0 ANTHROPIC_API_KEY=xxx python mcp_server.py

  # Use Google Gemini
  MODEL_PROVIDER=google MODEL_NAME=gemini-2.0-flash-exp GOOGLE_API_KEY=xxx python mcp_server.py

  # Use local Ollama
  MODEL_PROVIDER=ollama MODEL_NAME=llama3.1:8b python mcp_server.py

  # Use custom OpenAI-compatible API
  MODEL_PROVIDER=openai MODEL_NAME=custom-model BASE_URL=https://api.example.com/v1 API_KEY=xxx python mcp_server.py
"""

import os
import sys

# ============ Configuration ============

# Get model provider (openai, anthropic, google, azure, ollama)
MODEL_PROVIDER = os.getenv("MODEL_PROVIDER", "openai").lower()

# Get model name
MODEL_NAME = os.getenv("MODEL_NAME", "gpt-4o-mini")

# Get API key (try provider-specific env var first, then generic API_KEY)
API_KEY = os.getenv("API_KEY")
if not API_KEY:
    if MODEL_PROVIDER == "openai":
        API_KEY = os.getenv("OPENAI_API_KEY")
    elif MODEL_PROVIDER == "anthropic":
        API_KEY = os.getenv("ANTHROPIC_API_KEY")
    elif MODEL_PROVIDER == "google":
        API_KEY = os.getenv("GOOGLE_API_KEY")
    elif MODEL_PROVIDER == "azure":
        API_KEY = os.getenv("AZURE_OPENAI_API_KEY")

# Get custom base URL (for OpenAI-compatible APIs)
BASE_URL = os.getenv("BASE_URL")

# Azure-specific configuration
AZURE_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT")

# ============ Create LLM Instance ============

try:
    if MODEL_PROVIDER == "openai":
        from langchain_openai import ChatOpenAI
        llm_kwargs = {"model": MODEL_NAME}
        if API_KEY:
            llm_kwargs["api_key"] = API_KEY
        if BASE_URL:
            llm_kwargs["base_url"] = BASE_URL
        llm = ChatOpenAI(**llm_kwargs)
        print(f"✓ Using OpenAI model: {MODEL_NAME}", file=sys.stderr)

    elif MODEL_PROVIDER == "anthropic":
        from langchain_anthropic import ChatAnthropic
        llm_kwargs = {"model": MODEL_NAME}
        if API_KEY:
            llm_kwargs["api_key"] = API_KEY
        llm = ChatAnthropic(**llm_kwargs)
        print(f"✓ Using Anthropic model: {MODEL_NAME}", file=sys.stderr)

    elif MODEL_PROVIDER == "google":
        from langchain_google_genai import ChatGoogleGenerativeAI
        llm_kwargs = {"model": MODEL_NAME}
        if API_KEY:
            llm_kwargs["google_api_key"] = API_KEY
        llm = ChatGoogleGenerativeAI(**llm_kwargs)
        print(f"✓ Using Google model: {MODEL_NAME}", file=sys.stderr)

    elif MODEL_PROVIDER == "azure":
        from langchain_openai import AzureChatOpenAI
        llm_kwargs = {"model": MODEL_NAME}
        if API_KEY:
            llm_kwargs["api_key"] = API_KEY
        if AZURE_ENDPOINT:
            llm_kwargs["azure_endpoint"] = AZURE_ENDPOINT
        llm = AzureChatOpenAI(**llm_kwargs)
        print(f"✓ Using Azure OpenAI model: {MODEL_NAME}", file=sys.stderr)

    elif MODEL_PROVIDER == "ollama":
        from langchain_ollama import ChatOllama
        llm_kwargs = {"model": MODEL_NAME}
        if BASE_URL:
            llm_kwargs["base_url"] = BASE_URL
        llm = ChatOllama(**llm_kwargs)
        print(f"✓ Using Ollama model: {MODEL_NAME}", file=sys.stderr)

    else:
        print(f"✗ Unknown MODEL_PROVIDER: {MODEL_PROVIDER}", file=sys.stderr)
        print(f"  Supported providers: openai, anthropic, google, azure, ollama", file=sys.stderr)
        sys.exit(1)

except ImportError as e:
    print(f"✗ Failed to import LLM provider: {e}", file=sys.stderr)
    print(f"  Install the required package:", file=sys.stderr)
    if MODEL_PROVIDER == "openai":
        print(f"    uv pip install langchain-openai", file=sys.stderr)
    elif MODEL_PROVIDER == "anthropic":
        print(f"    uv pip install langchain-anthropic", file=sys.stderr)
    elif MODEL_PROVIDER == "google":
        print(f"    uv pip install langchain-google-genai", file=sys.stderr)
    elif MODEL_PROVIDER == "azure":
        print(f"    uv pip install langchain-openai", file=sys.stderr)
    elif MODEL_PROVIDER == "ollama":
        print(f"    uv pip install langchain-ollama", file=sys.stderr)
    sys.exit(1)

# ============ Start MCP Server ============

if __name__ == "__main__":
    try:
        # Set the LLM as environment variable for browser-use CLI
        # The browser-use CLI will use this LLM instance
        os.environ["BROWSER_USE_LLM_PROVIDER"] = MODEL_PROVIDER
        os.environ["BROWSER_USE_LLM_MODEL"] = MODEL_NAME
        
        # Import and run browser-use MCP server
        # Note: browser-use CLI uses uvx, so we just exec it with the env vars set
        import subprocess
        
        # Run browser-use --mcp with the configured environment
        result = subprocess.run(
            ["browser-use", "--mcp"],
            env=os.environ.copy()
        )
        sys.exit(result.returncode)
        
    except KeyboardInterrupt:
        print("\n✓ MCP server stopped", file=sys.stderr)
        sys.exit(0)
    except Exception as e:
        print(f"✗ Error starting MCP server: {e}", file=sys.stderr)
        sys.exit(1)

