# Centreon Log Management Plugin

This plugin allows you to fetch log counts from Centreon Log Management based on a query and time period.

## Usage

```bash
perl centreon_plugins.pl \
    --plugin=apps::centreon::logmanagement::restapi::plugin \
    --mode=log-count \
    --hostname=api.euwest1.obs.mycentreon.com \
    --org=YOUR_ORG_CODE \
    --token=YOUR_AUTH_TOKEN \
    --query='service_name:httpd' \
    --period=3600 \
    --warning-count=100 \
    --critical-count=500
```

## Parameters

### Required Parameters

- `--org`: Organization code - This is the organization identifier in the API URL path
- `--token`: Authentication token for the API (sent as X-Api-Key header)
- `--query`: Query string for log filtering (e.g., 'severity_text:error')

### Optional Parameters

- `--hostname`: Centreon Log Management API hostname
- `--api-path`: API endpoint path (default: `/v1/orgs/{org}/datasources/centreon-log/query/metrics`)
- `--proto`: Protocol (default: `https`)
- `--period`: Time period in seconds (default: `3600` - 1 hour, must be a positive integer)
- `--timeout`: HTTP timeout in seconds (default: `30`)

### Threshold Parameters

- `--warning-count`: Warning threshold for log count
- `--critical-count`: Critical threshold for log count

## Examples

### Basic Usage

```bash
perl centreon_plugins.pl \
    --plugin=apps::centreon::logmanagement::restapi::plugin \
    --mode=log-count \
    --hostname=api.euwest1.obs.mycentreon.com \
    --org=your-org-code \
    --token=your_token_here \
    --query='severity_text:error' \
    --period=86400
```

### With Thresholds

```bash
perl centreon_plugins.pl \
    --plugin=apps::centreon::logmanagement::restapi::plugin \
    --mode=log-count \
    --hostname=api.euwest1.obs.mycentreon.com \
    --org=your-org-code \
    --token=your_token_here \
    --query='service_name:nginx AND status:500' \
    --period=3600 \
    --warning-count=50 \
    --critical-count=100
```

### Custom API Path

```bash
perl centreon_plugins.pl \
    --plugin=apps::centreon::logmanagement::restapi::plugin \
    --mode=log-count \
    --hostname=api.euwest1.obs.mycentreon.com \
    --org=your-org-code \
    --api-path='/v1/orgs/{org}/datasources/centreon-log/query/metrics' \
    --token=your_token_here \
    --query='application:web' \
    --period=1800
```

## API Request Format

The plugin sends a POST request to the Centreon Log Management API with the following JSON body:

```json
{
  "op": "count-doc",
  "period": 3600,
  "query": "service_name:httpd",
  "version": "1",
  "interval": 3600
}
```

Note: Both `period` and `interval` use the same value from the `--period` parameter to ensure proper aggregation over the entire time period.

## Response Handling

The plugin expects a JSON response in the following format:
```json
{
  "curves": [
    {
      "metric": "count",
      "times": [1769644800000, 1770249600000],
      "data": [count_value, ...],
      "attributes": []
    }
  ]
}
```

The plugin extracts the log count from `response.curves[0].data[0]`.

If the count cannot be found, the plugin will return a critical status.

## Error Handling

The plugin handles various error conditions:
- Invalid or missing required parameters
- API connection failures
- JSON parsing errors
- API error responses
- Missing count in API response