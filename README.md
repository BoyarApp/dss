# Boyar Sign – Railway Deployment Bundle

This bundle packages the official [ESIG DSS](https://github.com/esig/dss) signing webapp for Railway using the published binaries from Maven Central. It avoids compiling from source, keeping builds fast and deterministic.

## Contents
- `Dockerfile` – Downloads `dss-signature-webapp` version `DSS_VERSION` from Maven Central and runs it on Eclipse Temurin 17.
- `docker-compose.yml` – Local parity stack that uses the same Dockerfile for smoke testing.
- `.env.example` – Sample environment variables to seed in Railway and local runs.
- `config/` – Optional overrides (`application.yml`, PKCS#11 configs, logging tweaks) copied into `/opt/dss/config/` at build time.

## Selecting a Version
Set the build argument/environment variable `DSS_VERSION` to any release available on Maven Central (e.g. `6.2.2`). Check https://repo1.maven.org/maven2/eu/europa/esig/dss-signature-webapp/ for the latest list.

## Deploying on Railway
1. **Create a Railway service** in an EU region (Frankfurt recommended for DSS latency/compliance).
2. **Point Railway at this folder** (monorepo deploy) and set the build argument `DSS_VERSION` if you want something other than the default `6.2.2`.
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

## Upgrades
When you’re ready for Azure Managed HSM, add the PKCS#11 configuration to `config/` and redeploy. The same container will load the module at boot.
