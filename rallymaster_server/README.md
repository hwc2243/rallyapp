# RallyMaster Server

Spring Boot service for RallyMaster rally-design data and browser UI.

## Run locally

```sh
./mvnw spring-boot:run
```

Open `http://localhost:8080` for the Thymeleaf welcome page.

## Deployment profiles

- `postgres` enables PostgreSQL JPA configuration. Supply `RALLYMASTER_DATABASE_URL`, `RALLYMASTER_DATABASE_USERNAME`, and `RALLYMASTER_DATABASE_PASSWORD`.
- `keycloak` enables JWT bearer-token validation for `/api/**`. Supply `KEYCLOAK_ISSUER_URI` with the Keycloak realm issuer URL.

Example:

```sh
SPRING_PROFILES_ACTIVE=postgres,keycloak KEYCLOAK_ISSUER_URI=https://keycloak.example.com/realms/rallymaster ./mvnw spring-boot:run
```

The default local profile leaves endpoints open only for initial development; do not deploy it.
