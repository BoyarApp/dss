# Boyar Sign – Railway Deployment Bundle

This bundle builds the official [ESIG DSS](https://github.com/esig/dss-demonstrations) webapp for Railway from the dss-demonstrations repository. It provides a working DSS service with all required functionality.

## Contents
- `Dockerfile` – Multi-stage build that clones the dss-demonstrations repository and builds the dss-demo-webapp using Maven, then deploys it on Tomcat.
- `docker-compose.yml` – Local parity stack that uses the same Dockerfile for smoke testing.
- `.env.example` – Sample environment variables to seed in Railway and local runs.
- `config/` – Optional overrides (`application.yml`, PKCS#11 configs, logging tweaks) copied into `/opt/dss/config/` at build time.

## How It Works
The Dockerfile builds directly from the official dss-demonstrations repository, which contains the actual executable DSS webapp. This ensures compatibility and provides all required DSS functionality.

## Deploying on Railway
1. **Create a Railway service** in an EU region (Frankfurt recommended for DSS latency/compliance).
2. **Point Railway at this folder** (monorepo deploy). Set build args `DSS_VERSION` and/or `DSS_ASSET_URL` if needed.
3. **Set environment variables** using `.env.example` as a template: `SIGN_API_KEY`, `SIGN_WEBHOOK_SECRET`, `AZURE_KEY_VAULT_URI`, etc.
4. **Expose port 8080**; Railway auto-assigns an HTTPS endpoint. Drop that URL into Boyar’s `SIGN_BASE_URL`.
5. **Attach persistent storage** (1–5 GB) if you want logs/temp files to survive restarts.
6. **Configure a health check** against `/actuator/health` (or another Spring actuator endpoint you enable).
7. **Sync secrets from Azure Key Vault** so Railway doesn’t store long-lived credentials in plaintext.

## Local Smoke Test
```bash
docker compose --env-file .env.example up --build
```
The service boots on `http://localhost:9000`. Use it to verify configuration overrides and integration behaviour.

## Customising the Build
- Drop configuration files into `config/` to inject additional Spring properties, PKCS#11 modules, or logging config.
- Tune JVM sizing with `JAVA_OPTS` in your environment variables.
- Force a specific artifact by setting `DSS_ASSET_URL` to the GitHub download link shown on the release page.

## Upgrades
When you’re ready for Azure Managed HSM, add the PKCS#11 configuration to `config/` and redeploy. The same container will load the module at boot.
