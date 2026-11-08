# Custom policy set definitions

Policy set definition JSON files in this folder are deployed at the configured root management group by `main.policy_set_definitions.tf`. Give security-owned copies distinct names to avoid collisions with definitions deployed by the platform; ALZ `placeholder` scope references are resolved by Terraform.

The design rationale for security-owned custom definitions is documented in [DD08: Dependency on platform-deployed definitions](../../design/alz-diagnostic-logging-design.md#dependency-on-platform-deployed-definitions).