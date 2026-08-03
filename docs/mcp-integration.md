# MCP integration

`IMcpToolClient` is the narrow Application boundary. Infrastructure is disabled by default and rejects calls unless enabled, an endpoint exists, the exact tool is allowlisted, and the caller is authorized. Timeout/cancellation and input/output validation belong at this boundary; logs contain tool name, result, and duration only. `SyntheticDemo` returns clearly labeled synthetic development data and must remain false in Production.

A production owner must supply the MCP server URL, tool catalog/schema, authorization policy, network controls, and an authentication strategy (prefer managed/workload identity; place any unavoidable secret in Key Vault/App Service settings). Add a typed transport behind the interface, enforce response size/schema, map user authorization to each tool, and configure allowlist/timeout. Never give retrieved documents authority to call tools.
