FROM traefik:v3.0

# Copy Traefik configuration
COPY traefik.yaml /etc/traefik/traefik.yaml
COPY dynamic/ /etc/traefik/dynamic/

# Expose ports
EXPOSE 80 443 8080

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD ["traefik", "healthcheck"]
