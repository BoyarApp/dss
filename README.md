# Boyar Sign – Railway Deployment Bundle

This folder hosts the assets you can point Railway at when you want a managed Digital Signature Service (DSS) runtime for the Boyar Sign module.

## Contents
- `Dockerfile` – Thin wrapper that pulls the official DSS container image so Railway can build and deploy it from this repo.
- `docker-compose.yml` – Parity script for running the same image locally (useful for smoke tests before pushing to Railway).
- `.env.example` – Suggested environment variables you should seed in Railway.
- `config/` – Placeholder for optional DSS configuration overrides (copied into the container at build time if present).

## How to Deploy on Railway
1. **Create a new Railway project** in the EU region (Frankfurt is a good default).
2. **Connect this repo/folder** and let Railway build using the provided Dockerfile. Override the `DSS_IMAGE` build argument if you need a specific tag.
3. **Set service variables** using `.env.example` as a template (at minimum `SIGN_API_KEY`, `SIGN_WEBHOOK_SECRET`, `AZURE_KEY_VAULT_URI`).
4. **Expose port 8080**; Railway will automatically assign an HTTPS endpoint. Copy that URL into Boyar’s `SIGN_BASE_URL`.
5. **Attach storage** (1–5 GB) if you want DSS to persist logs/temp files between deployments.
6. **Configure health checks** on `/actuator/health` (or whatever you configure in your wrapper).
7. **Wire secrets** from Azure Key Vault (or rotate them manually) before you flip the feature flag in production.

## Local Smoke Test
```bash
docker compose --env-file .env.example up --build
```
This will boot DSS on `http://localhost:9000`. Use it to verify the service starts and honours your configuration overrides.

## Notes
- The Dockerfile only copies files from `config/` if you add them (e.g., `application.yml`, custom PKCS#11 configs). Remove the directory if unused.
- Keep the Azure Key Vault keys and DSS secrets in sync—Railway should never store long‑lived secrets in plain text.
- When you upgrade to Azure Managed HSM, the same container image can load PKCS#11 modules; just mount the additional config in `config/`.
