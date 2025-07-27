# Traefik Reverse Proxy

This directory contains the Traefik configuration for the Lambda monorepo.

## Architecture

```
Internet → ALB → Traefik (ECS) → API Gateway → Lambda
```

## Key Features

- **Advanced Routing**: Path and host-based routing rules
- **Rate Limiting**: Protect backend services from overload
- **Circuit Breaker**: Automatic failover and recovery
- **Observability**: Prometheus metrics and structured logs
- **Security**: TLS termination, security headers, authentication

## Local Development

```bash
# Start Traefik locally
make test-traefik-local

# View dashboard at http://traefik.localhost
```

## Configuration

- Static config: `config/traefik.yaml`
- Dynamic routing: `config/dynamic/*.yaml`
- Environment-specific: `../../config/traefik.yaml`

## Monitoring

- Dashboard: https://your-alb-url/dashboard
- Metrics: https://your-alb-url/metrics
- Health: https://your-alb-url/ping

## Troubleshooting

1. **503 Service Unavailable**
   - Check API Gateway URL in dynamic config
   - Verify security groups allow egress to API Gateway
   - Check circuit breaker status

2. **Rate Limit Exceeded**
   - Review rate limit configuration
   - Check source IP for distributed requests
   - Consider increasing limits

3. **High Latency**
   - Check ECS task metrics
   - Review retry configuration
   - Verify API Gateway performance
