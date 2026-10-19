# Azure Front Door monitoring

This Terraform definition records the desired state for two narrowly scoped Azure controls for the public Front Door endpoint:

1. An Azure Monitor action group that emails the operator.
2. An activity-log alert for any administrative change to that endpoint, including an enabled-state change.

It is intentionally separate from the existing application infrastructure because it protects an already-deployed shared public endpoint.

## Persistent state

Terraform state is stored in the existing Azure Storage backend rather than in Azure Cloud Shell. Cloud Shell sessions can be ephemeral; local state would make Terraform ownership unreliable.

- Resource group: `NorthStar-Landing-Zone-RG`
- Storage account: `northstartfstate244d`
- Container: `tfstate`
- State key: `northstar-portfolio/azure-monitoring.tfstate`

The backend uses the signed-in Azure identity and Azure RBAC. No account keys or state files are committed to this repository.

## Adopt existing resources before apply

The action group and activity-log alert were first deployed manually during incident follow-through. Do **not** run `terraform apply` against this subscription until Terraform has imported those resources; otherwise Azure will reject the duplicate names.

Use Azure Cloud Shell to discover IDs, initialize the persistent backend, and import the deployed resources:

```bash
cd ~/northstar-portfolio/infra/azure-monitoring
terraform init -reconfigure \
  -backend-config="resource_group_name=NorthStar-Landing-Zone-RG" \
  -backend-config="storage_account_name=northstartfstate244d" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=northstar-portfolio/azure-monitoring.tfstate" \
  -backend-config="use_azuread_auth=true"
endpoint_id="$(az afd endpoint show \
  --profile-name northstar-portfolio-afd \
  --resource-group northstar-portfolio-rg \
  --endpoint-name guydiangana-portfolio-519 \
  --query id --output tsv)"
subscription_id="$(az account show --query id --output tsv)"
common_vars=(
  -var='alert_email_address=YOUR_EMAIL_ADDRESS'
  -var="front_door_endpoint_resource_id=$endpoint_id"
)

terraform import "${common_vars[@]}" \
  azurerm_monitor_action_group.front_door \
  "/subscriptions/$subscription_id/resourceGroups/northstar-portfolio-rg/providers/Microsoft.Insights/actionGroups/northstar-frontdoor-alerts"

terraform import "${common_vars[@]}" \
  azurerm_monitor_activity_log_alert.front_door_endpoint_administrative_change \
  "/subscriptions/$subscription_id/resourceGroups/northstar-portfolio-rg/providers/Microsoft.Insights/activityLogAlerts/northstar-frontdoor-endpoint-admin-change"

terraform plan "${common_vars[@]}"
```

Review the plan before applying any drift correction. Azure Monitor email delivery must be tested independently; do not treat the action-group receiver state alone as proof of paging.

## Validate

```bash
az monitor activity-log alert show \
  --resource-group northstar-portfolio-rg \
  --name northstar-frontdoor-endpoint-admin-change \
  --query '{Enabled:enabled,Scopes:scopes,Condition:condition,Actions:actions.actionGroups}' \
  --output json
```

The GitHub Actions workflow at `.github/workflows/public-site-availability.yml` independently checks the public HTTPS path and expected page content every ten minutes. A separate external monitor provides the primary five-minute availability notification path. Azure activity-log alerts complement those checks with control-plane change visibility.

The endpoint resource ID is discovered at apply time and is never committed to the repository.
