# Boyar Sign – Railway Deployment Bundle

This bundle builds the official [ESIG DSS](https://github.com/esig/dss) Spring Boot webapp from source and packages it for Railway. The generated container exposes the same endpoints as the stock DSS distribution, so you can deploy a compliant signing backend without relying on third-party images.

## Contents
- `Dockerfile` – Multi-stage build that clones the official DSS repository, optionally checks out a ref (branch or tag) you provide, packages `dss-signature-webapp`, and runs it on Eclipse Temurin 17.
- `docker-compose.yml` – Local parity stack that uses the same Dockerfile; handy for smoke tests before pushing to Railway.
- `.env.example` – Sample environment variables to seed in Railway and local runs.
- `config/` – Optional overrides (`application.yml`, PKCS#11 configs, logging tweaks) copied into `/opt/dss/config/` at build time.

## Choosing a DSS Version
- Leave `DSS_REF` blank to build the repository’s default branch (currently `master`).
- Set `DSS_REF` to a branch or tag when you want a specific release, e.g. `refs/tags/dss-6.2.2` or `release-6.2.x`.
- To confirm available tags, check the [official tag list](https://github.com/esig/dss/tags).

## Deploying on Railway
1. **Create a Railway service** in an EU region (Frankfurt recommended for DSS latency/compliance).
2. **Point Railway at this folder** (monorepo deploy). If you need a specific release, set the build argument `DSS_REF` accordingly.
3. **Set environment variables** using `.env.example` as a template: `SIGN_API_KEY`, `SIGN_WEBHOOK_SECRET`, `AZURE_KEY_VAULT_URI`, and any DSS-specific toggles.
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

## Upgrades
When you’re ready for Azure Managed HSM, add the PKCS#11 configuration to `config/` and redeploy. The same container will load the module at boot.
