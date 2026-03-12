<!-- markdownlint-disable MD033 MD041 -->

<a id="readme-top"></a>

<div align="center">

![Status](https://img.shields.io/badge/Status-In%20Progress-yellow?style=for-the-badge)
![Step](https://img.shields.io/badge/Step-4%20of%207-blue?style=for-the-badge)
![Cost](https://img.shields.io/badge/Est.%20Cost-~%E2%82%AC1%2C040%2Fmo-purple?style=for-the-badge)

# 🏗️ enterprise-foundry

**Enterprise AI Foundry Hub + MCP Catalog with Databricks, Salesforce, and M365 connectors**

[View Architecture](#-architecture) · [View Artifacts](#-generated-artifacts) · [View Progress](#-workflow-progress)

</div>

---

## 📋 Project Summary

| Property           | Value                                     |
| ------------------ | ----------------------------------------- |
| **Created**        | 2026-03-12                                |
| **Last Updated**   | 2026-03-12                                |
| **Region**         | swedencentral                             |
| **Environment**    | prod                                      |
| **Estimated Cost** | ~€1,040/month                             |
| **AVM Coverage**   | 90%                                       |

---

## ✅ Workflow Progress

```text
[████████░░░░░░░] 57% Complete
```

| Step | Phase          | Status | Artifact |
| :--: | -------------- | :----: | -------- |
|  1   | Requirements   | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | [01-requirements.md](./01-requirements.md) |
|  2   | Architecture   | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | [02-architecture-assessment.md](./02-architecture-assessment.md) |
|  3   | Design         | ![Skip](https://img.shields.io/badge/-Skipped-blue?style=flat-square) | — |
|  4   | Planning       | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | [04-implementation-plan.md](./04-implementation-plan.md) |
|  5   | Implementation | ![WIP](https://img.shields.io/badge/-WIP-yellow?style=flat-square) | `infra/bicep/enterprise-foundry/` |
|  6   | Deployment     | ![Pending](https://img.shields.io/badge/-Pending-lightgrey?style=flat-square) | — |
|  7   | Documentation  | ![Pending](https://img.shields.io/badge/-Pending-lightgrey?style=flat-square) | — |

---

## 🏛️ Architecture

### Key Resources

| Resource               | Type                                                 | SKU           | Purpose                   |
| ---------------------- | ---------------------------------------------------- | ------------- | ------------------------- |
| AI Foundry Hub         | Microsoft.MachineLearningServices/workspaces (Hub)   | Basic         | Enterprise AI control plane |
| AI Foundry Project     | Microsoft.MachineLearningServices/workspaces (Project)| Basic        | Model deployments + flows |
| Azure AI Services      | Microsoft.CognitiveServices/accounts                 | S0            | GPT-4o + text-embedding   |
| foundry-mcp App        | Microsoft.App/containerApps                          | Consumption   | MCP server for copilots   |
| Key Vault              | Microsoft.KeyVault/vaults                            | Standard      | Secrets management        |
| Storage Account        | Microsoft.Storage/storageAccounts                    | Standard_ZRS  | Foundry artifacts         |
| Container Registry     | Microsoft.ContainerRegistry/registries               | Standard      | Docker images             |
| Virtual Network        | Microsoft.Network/virtualNetworks                    | Standard      | Private isolation         |

---

## 📄 Generated Artifacts

<details>
<summary><strong>📁 Step 1-2: Requirements & Architecture</strong></summary>

| File | Description | Status | Created |
| ---- | ----------- | :----: | ------- |
| [01-requirements.md](./01-requirements.md) | Project requirements with NFRs | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-03-12 |
| [02-architecture-assessment.md](./02-architecture-assessment.md) | WAF assessment | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-03-12 |

</details>

<details>
<summary><strong>📁 Step 4: Planning</strong></summary>

| File | Description | Status | Created |
| ---- | ----------- | :----: | ------- |
| [04-implementation-plan.md](./04-implementation-plan.md) | Bicep implementation plan | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-03-12 |
| [04-dependency-diagram.py](./04-dependency-diagram.py) | Dependency diagram source | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-03-12 |
| [04-runtime-diagram.py](./04-runtime-diagram.py) | Runtime flow diagram source | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-03-12 |

</details>

---

## 🔗 Related Resources

| Resource              | Path                                                                          |
| --------------------- | ----------------------------------------------------------------------------- |
| **Bicep Templates**   | [`infra/bicep/enterprise-foundry/`](../../infra/bicep/enterprise-foundry/)    |
| **foundry-mcp Server**| [`mcp/foundry-mcp/`](../../mcp/foundry-mcp/)                                  |
| **MCP Connectors**    | [`mcp/connectors/`](../../mcp/connectors/)                                    |

---

<div align="center">

**Generated by [Agentic InfraOps](../../README.md)**

<a href="#readme-top">⬆️ Back to Top</a>

</div>
