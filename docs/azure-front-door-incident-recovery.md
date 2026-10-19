# Azure Front Door Incident Recovery Exercise

**Service:** GuyDiangana.com public site
**Platform:** Azure Front Door Standard and Azure Storage static website
**Incident window:** October 17–18, 2026
**Status:** Resolved; independent availability monitoring implemented

## Executive summary

The public portfolio domain became unavailable through Azure Front Door. Visitors received an HTTP 502 response with the message `Certificate verify failed: hostname mismatch`. The Azure Storage static website origin remained available throughout the incident.

Investigation identified that the Azure Front Door endpoint was disabled. The associated route and origin group were enabled and provisioned successfully. The endpoint was re-enabled, after which the public service recovered following Front Door edge propagation.

The observed certificate message was treated as a diagnostic signal, but the origin configuration was verified as correct. There is no evidence that the storage-origin hostname or host-header configuration caused the outage. The source of the endpoint disablement remains an open investigation item and must be validated through Azure Activity Log before attribution.

## Customer impact

| Area | Effect |
| --- | --- |
| Public domain | `www.guydiangana.com` unavailable through the Front Door edge |
| Visitor experience | Azure Front Door returned HTTP 502 |
| Origin content | Azure Storage static website remained available directly |
| Security posture | No evidence of data exposure, credential compromise, or origin tampering |

## Evidence collected

| Component | Verified state |
| --- | --- |
| Front Door profile | `northstar-portfolio-afd` provisioned successfully |
| Custom domain | `www.guydiangana.com` provisioned; validation approved |
| Endpoint | Observed **Disabled** during investigation; later re-enabled |
| Route | `portfolio-route` enabled; provisioning succeeded |
| Origin group | `portfolio-static-origin` provisioned successfully |
| Origin host name and host header | `northstarportfolio26681.z9.web.core.windows.net` |
| Certificate subject-name validation | Enabled |
| Direct origin test | Current portfolio content served successfully |

## Technical timeline

1. A public site failure was reported.
2. External validation returned `502 Bad Gateway` with `Certificate verify failed: hostname mismatch`.
3. The static website origin was tested independently and served the expected portfolio content.
4. Azure Front Door configuration review showed a disabled endpoint while its route and origin group remained healthy.
5. The endpoint was enabled.
6. The origin configuration was inspected: the storage hostname, origin host header, certificate validation, and origin status were correct.
7. Azure Front Door propagated the endpoint change and the public domain recovered.

## Root-cause statement

### Confirmed proximate cause

The Azure Front Door endpoint was disabled, preventing the configured route from serving the public domain.

### Cause still under investigation

The reason the endpoint entered a disabled state is not yet established. Review the Azure Activity Log for Front Door write operations in the incident window. Document the initiating principal, operation name, timestamp, and correlation ID before assigning an underlying root cause.

Use the following read-only query while signed in to the Azure subscription:

```bash
endpoint_id="$(az afd endpoint show \
  --profile-name northstar-portfolio-afd \
  --resource-group northstar-portfolio-rg \
  --endpoint-name guydiangana-portfolio-519 \
  --query id --output tsv)"

az monitor activity-log list \
  --resource-id "$endpoint_id" \
  --start-time 2026-10-17T00:00:00Z \
  --end-time 2026-10-19T00:00:00Z \
  --query "[].{Time:eventTimestamp,Operation:operationName.localizedValue,Status:status.localizedValue,Caller:caller,Correlation:correlationId}" \
  --output table
```

Record the output in a private incident note. Do not add account identifiers, callers, or raw logs to the public repository.

## Recovery runbook

1. Confirm impact from an external network and record the exact HTTP status and visible error.
2. Test the static website origin directly. If it serves expected content, focus on Front Door rather than publishing or storage.
3. In Azure Portal, open **Front Door and CDN profiles** → `northstar-portfolio-afd` → **Front Door manager**.
4. Check endpoint status first. If disabled, enable the endpoint and record the time of change.
5. Verify the route is enabled and points to `portfolio-static-origin`.
6. Verify the origin uses:
   - Host name: `northstarportfolio26681.z9.web.core.windows.net`
   - Origin host header: `northstarportfolio26681.z9.web.core.windows.net`
   - Certificate subject-name validation: enabled
   - Origin status: enabled
7. Allow up to 15 minutes for Front Door configuration propagation. Do not repeatedly modify healthy settings during this period.
8. Validate the public custom domain in a private browser session and from a second network.
9. Capture final evidence, update the timeline, and review Activity Log before assigning root cause.

## Reliability controls implemented

| Control | State | Outcome |
| --- | --- | --- |
| GitHub Actions public-content probe | Implemented | Checks HTTPS reachability and expected page content every ten minutes. |
| Independent external availability monitor | Implemented and email-tested | Checks the public HTTPS endpoint every five minutes and sends outage and recovery notifications. |
| Azure Activity Log alerts | Deployed for endpoint administrative changes | Retained as a control-plane audit signal. Email delivery was not validated during this exercise, so it is not the primary paging mechanism. |
| Terraform monitoring definition | Added | Captures the intended Azure Monitor configuration; manually created resources must be imported before Terraform manages them. |
| Activity Log review | Ongoing | Required before assigning an underlying cause for the endpoint disablement. |

## Monitoring decision

The public endpoint must be monitored from outside Azure Front Door. Azure configuration alerts are useful for change visibility, but they are not sufficient proof that visitors can reach the site or that a notification will arrive. The independent monitor is therefore the primary availability notification path. GitHub Actions provides a second, content-aware verification path.

## Exercise outcome

The recovery demonstrated the value of layered validation: test the public edge, test the origin independently, inspect endpoint state, and verify configuration before making changes. The resulting design adds independent external monitoring, content-aware scheduled validation, controlled change paths, and a concise recovery runbook.

## Publication boundary

This record is retained as internal engineering evidence. It is not a public site feature. The public site may reference the resulting resilience practices only after the underlying Activity Log review is complete.
