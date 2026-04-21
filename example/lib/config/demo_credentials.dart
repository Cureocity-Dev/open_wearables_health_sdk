/// Demo credentials for the local docker-compose Open Wearables backend.
///
/// NOT production secrets — the API key only authenticates against a
/// developer's own `localhost:8000` stack (seeded from the gitignored
/// `backend/config/.env` in the open-wearables clone). Safe to commit
/// to the Cureocity fork. See `docs/superpowers/specs/` for rationale.
const kDemoUserId = 'cf455d6a-d670-453b-bd8d-d08adc9c921e';
const kDemoApiKey = 'sk-7a2713eb51a5752d0ba147c173d67e2a';
