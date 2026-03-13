"""
Enterprise Foundry — Runtime Flow Diagram
Generated for: agent-output/enterprise-foundry/04-runtime-diagram.py

Usage:
    pip install diagrams
    python 04-runtime-diagram.py
    # Generates: 04-runtime-diagram.png
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.ai import CognitiveServices
from diagrams.azure.compute import ContainerInstances
from diagrams.azure.general import Resourcegroups
from diagrams.azure.identity import ActiveDirectory
from diagrams.azure.security import KeyVaults
from diagrams.onprem.client import Client
from diagrams.saas.communication import Slack
from diagrams.saas.crm import Salesforce

with Diagram(
    "Enterprise Foundry — Runtime Flow",
    show=False,
    filename="04-runtime-diagram",
    direction="LR",
):
    with Cluster("MCP Consumers"):
        copilot = Client("GitHub Copilot")
        vscode = Client("VS Code Copilot")
        studio = Client("Copilot Studio")

    with Cluster("MCP Layer (Azure Container Apps)"):
        mcp_server = ContainerInstances("foundry-mcp\n(MCP Server)")

    with Cluster("Azure AI Foundry"):
        ai_hub = ActiveDirectory("AI Foundry Hub")
        aoai = CognitiveServices("Azure OpenAI\n(GPT-4o, Embeddings)")
        catalog = Resourcegroups("AI Catalog\n(Tools + Models)")

    with Cluster("External Connectors"):
        databricks = Slack("Databricks\nMCP Connector")
        salesforce = Salesforce("Salesforce\nMCP Connector")
        m365 = Client("M365\nMCP Connector")

    with Cluster("Security"):
        kv = KeyVaults("Key Vault\n(Secrets)")

    # Consumer → MCP
    copilot >> Edge(label="MCP/HTTPS") >> mcp_server
    vscode >> Edge(label="MCP/stdio") >> mcp_server
    studio >> Edge(label="MCP/HTTPS") >> mcp_server

    # MCP → Foundry
    mcp_server >> Edge(label="ML SDK") >> ai_hub
    mcp_server >> Edge(label="OpenAI SDK") >> aoai
    mcp_server >> Edge(label="catalog") >> catalog
    ai_hub >> catalog

    # MCP → Connectors
    mcp_server >> Edge(label="forward") >> databricks
    mcp_server >> Edge(label="forward") >> salesforce
    mcp_server >> Edge(label="forward") >> m365

    # Secrets
    mcp_server >> Edge(label="MI auth", style="dashed", color="orange") >> kv
