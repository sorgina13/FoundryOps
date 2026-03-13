"""
Enterprise Foundry — Module Dependency Diagram
Generated for: agent-output/enterprise-foundry/04-dependency-diagram.py

Usage:
    pip install diagrams
    python 04-dependency-diagram.py
    # Generates: 04-dependency-diagram.png
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import ContainerInstances
from diagrams.azure.database import BlobStorage
from diagrams.azure.devops import Repos
from diagrams.azure.general import Resourcegroups
from diagrams.azure.identity import ActiveDirectory
from diagrams.azure.monitor import Monitor
from diagrams.azure.network import VirtualNetworks
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import StorageAccounts

with Diagram(
    "Enterprise Foundry — Module Dependencies",
    show=False,
    filename="04-dependency-diagram",
    direction="TB",
):
    with Cluster("Azure Resource Group"):
        rg = Resourcegroups("rg-foundry-prod")

        with Cluster("Foundation"):
            monitor = Monitor("monitoring.bicep\nLog Analytics + App Insights")
            kv = KeyVaults("key-vault.bicep\nKey Vault")
            storage = StorageAccounts("storage.bicep\nStorage Account (ZRS)")
            acr = Repos("container-registry.bicep\nContainer Registry")
            vnet = VirtualNetworks("networking.bicep\nVNet + DNS Zones")

        with Cluster("AI Platform"):
            ai_hub = ActiveDirectory("ai-hub.bicep\nAI Foundry Hub")
            ai_project = ActiveDirectory("ai-project.bicep\nAI Project + Models")

        with Cluster("MCP Layer"):
            mcp = ContainerInstances("mcp-catalog.bicep\nfoundry-mcp Container App")

        budget = BlobStorage("budget.bicep\nCost Budget")

    # Dependencies
    rg >> Edge(color="gray", style="dashed") >> monitor
    rg >> Edge(color="gray", style="dashed") >> kv
    rg >> Edge(color="gray", style="dashed") >> storage
    rg >> Edge(color="gray", style="dashed") >> acr
    rg >> Edge(color="gray", style="dashed") >> vnet

    monitor >> ai_hub
    kv >> ai_hub
    storage >> ai_hub
    acr >> ai_hub
    vnet >> ai_hub

    ai_hub >> ai_project
    ai_project >> mcp

    kv >> mcp
    acr >> mcp
    vnet >> mcp
    monitor >> mcp

    rg >> Edge(color="orange", style="dotted") >> budget
