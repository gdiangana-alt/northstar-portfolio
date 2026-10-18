# Azure Front Door monitoring

This Terraform definition creates two narrowly scoped controls for the portfolio Front Door endpoint:

1. An Azure Monitor action group that emails the operator.
2. An activity-log alert whenever the endpoint is written or its enabled state changes.

It is intentionally separate from the existing application infrastructure because it protects an already-deployed shared public endpoint.

## Apply

Use Azure Cloud Shell after reviewing the plan:

```bash
cd ~/northstar-portfolio/infra/azure-monitoring
terraform init
endpoint_id="$(az afd endpoint show \
  --profile-name northstar-portfolio-afd \
  --resource-group northstar-portfolio-rg \
  --endpoint-name guydiangana-portfolio-519 \
  --query id --output tsv)"
terraform plan -var='alert_email_address=YOUR_EMAIL_ADDRESS' -var="front_door_endpoint_resource_id=$endpoint_id"
terraform apply -var='alert_email_address=YOUR_EMAIL_ADDRESS' -var="front_door_endpoint_resource_id=$endpoint_id"
```

Azure sends an email subscription confirmation for the action group. Confirm it before treating the alert as operational.

## Validate

```bash
az monitor activity-log alert show \
  --resource-group northstar-portfolio-rg \
  --name northstar-frontdoor-endpoint-change \
  --query '{Enabled:enabled,Scopes:scopes,Operation:criteria.allOf[1].equals}' \
  --output json
```

The GitHub Actions workflow at `.github/workflows/public-site-availability.yml` independently checks the public HTTPS path and expected page content every ten minutes. It does not replace Azure Monitor alerts: it detects visitor-facing failures, while the activity-log alert records a control-plane change.

The endpoint resource ID is discovered at apply time and is never committed to the repository.
