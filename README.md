# docker-redmine

This repository is a fork of [sameersbn/docker-redmine](https://github.com/sameersbn/docker-redmine).

The fork exists to continue maintaining a practical Docker image and runtime setup for both Redmine and Redmica. In particular, Redmica-specific maintenance should live here instead of depending on upstream support.

## Why This Fork Exists

The upstream repository is a strong base, but this fork has a different maintenance goal:

- keep Redmine support working
- add and maintain Redmica as a first-class build target
- make local and server operations explicit through this repository
- accept that upstream and this fork may evolve at different speeds

This repository should be read as an operational fork, not as a mirror of upstream.

## Scope

This repository maintains:

- Docker build and runtime definitions for Redmine and Redmica
- `docker compose` based startup for PostgreSQL-backed deployments
- flavor-specific builds through `REDMINE_FLAVOR`
- operational fixes required to keep the images usable

This repository does not guarantee:

- compatibility with every third-party plugin or theme
- immediate synchronization with upstream changes
- support for every historical image tag published by upstream

## Supported Flavors

The image can be built in two flavors:

- `redmine`
- `redmica`

Current defaults in this repository:

- `redmine`: `6.1.2`
- `redmica`: `4.0.3`

The flavor is selected at build time through `REDMINE_FLAVOR`, and the application archive is downloaded accordingly.

## Project Layout

The main operational entrypoints in this repository are:

- [`Makefile`](./Makefile): build, startup, logs, config, release helpers
- [`Dockerfile`](./Dockerfile): common image definition
- [`docker-compose.yml`](./docker-compose.yml): PostgreSQL-backed runtime
- [`assets/build/install.sh`](./assets/build/install.sh): flavor-aware install logic

## Quick Start

### Requirements

- Docker Engine with Compose support
- `make`
- `sudo` access to create bind mount directories under `/srv/docker/redmine`

### Start Redmine

```bash
make up-redmine
```

This uses the defaults below:

- flavor: `redmine`
- version: `6.1.2`
- app port: `10083`
- database name: `redmine_production`

### Start Redmica

```bash
make up-redmica
```

This uses the defaults below:

- flavor: `redmica`
- version: `4.0.3`
- app port: `10084`
- database name: `redmica_production`

### Open the Application

After startup, access:

- Redmine: `http://localhost:10083`
- Redmica: `http://localhost:10084`

Please allow the application a short time to bootstrap on the first run.

## Common Commands

### Build

```bash
make build FLAVOR=redmine VERSION=6.1.2
make build FLAVOR=redmica VERSION=4.0.3
```

### Start

```bash
make up FLAVOR=redmine VERSION=6.1.2 APP_PORT=10083
make up FLAVOR=redmica VERSION=4.0.3 APP_PORT=10084
```

### Stop

```bash
make down FLAVOR=redmine VERSION=6.1.2
make down FLAVOR=redmica VERSION=4.0.3
```

### Logs

```bash
make logs FLAVOR=redmine VERSION=6.1.2
make logs FLAVOR=redmica VERSION=4.0.3
```

### Render Effective Compose Config

```bash
make config FLAVOR=redmine VERSION=6.1.2
make config FLAVOR=redmica VERSION=4.0.3
```

Run `make help` for the shortcut targets and examples bundled with this repository.

## Configuration Model

The default runtime is driven by variables exported through the `Makefile` into `docker compose`.

Important parameters:

- `FLAVOR`: `redmine` or `redmica`
- `VERSION`: application version to build
- `APP_PORT`: published HTTP port
- `TZ`: container timezone, default `Asia/Tokyo`
- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASS`
- `DB_NAME`
- `IMAGE_REPO`: image repository name, default `sameersbn/redmine`

Example:

```bash
make up FLAVOR=redmica VERSION=4.0.3 APP_PORT=11084 IMAGE_REPO=yassan/redmine
```

## Runtime Directories

By default the repository uses bind mounts under `/srv/docker/redmine`.

For each flavor, the following directories are used:

- application data: `/srv/docker/redmine/<flavor>`
- application logs: `/srv/docker/redmine/<flavor>-logs`
- PostgreSQL data: `/srv/docker/redmine/<flavor>-postgresql`

Examples:

- Redmine data: `/srv/docker/redmine/redmine`
- Redmica data: `/srv/docker/redmine/redmica`

These directories are created by `make up` via the `prepare-dirs` target.

## Image Behavior

The image is built from a single [`Dockerfile`](./Dockerfile) and switches behavior by flavor:

- `REDMINE_FLAVOR=redmine` downloads Redmine from `redmine.org`
- `REDMINE_FLAVOR=redmica` downloads Redmica from `github.com/redmica/redmica`

The build installs the application, bundles gems, and prepares an nginx + puma runtime managed by supervisor.

## Other Compose Files

This repository still contains additional compose examples inherited from upstream, such as:

- [`docker-compose-mysql.yml`](./docker-compose-mysql.yml)
- [`docker-compose-mariadb.yml`](./docker-compose-mariadb.yml)
- [`docker-compose-sqlite3.yml`](./docker-compose-sqlite3.yml)
- [`docker-compose-ssl.yml`](./docker-compose-ssl.yml)
- [`docker-compose-memcached.yml`](./docker-compose-memcached.yml)

Treat them as secondary examples. The primary supported path in this fork is the default PostgreSQL-based `docker-compose.yml`.

## Configuration

This fork no longer documents every historical option inline, but the runtime still supports the main upstream-style environment model.

The default compose path in this repository actively uses:

- database settings: `DB_ADAPTER`, `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`, `DB_SSL_MODE`
- app URL settings: `REDMINE_PORT`, `REDMINE_HTTPS`, `REDMINE_RELATIVE_URL_ROOT`
- app behavior: `REDMINE_SECRET_TOKEN`, `REDMINE_SUDO_MODE_ENABLED`, `REDMINE_SUDO_MODE_TIMEOUT`, `REDMINE_CONCURRENT_UPLOADS`
- nginx settings: `NGINX_MAX_UPLOAD_SIZE`
- mail settings: `SMTP_*`
- incoming mail settings: `IMAP_*`

The runtime also supports additional options implemented in [`assets/runtime/functions`](./assets/runtime/functions), including:

- `DATABASE_URL`
- `MEMCACHE_HOST`, `MEMCACHE_PORT`
- `REDMINE_BACKUP_SCHEDULE`, `REDMINE_BACKUP_TIME`, `REDMINE_BACKUP_EXPIRY`
- `REDMINE_FETCH_COMMITS`
- `SSL_CERTIFICATE_PATH`, `SSL_KEY_PATH`, `SSL_DHPARAM_PATH`
- `NGINX_ENABLED`, `NGINX_WORKERS`, `NGINX_HSTS_ENABLED`, `NGINX_HSTS_MAXAGE`
- `USERMAP_UID`, `USERMAP_GID`

Generated application config is written inside the container under:

- `/home/redmine/redmine/config/database.yml`
- `/home/redmine/redmine/config/configuration.yml`
- `/home/redmine/redmine/config/additional_environment.rb`
- `/home/redmine/redmine/config/puma.rb`

User-managed files should live in the data volume under `/home/redmine/data`, especially:

- `/home/redmine/data/plugins`
- `/home/redmine/data/themes`
- `/home/redmine/data/config`
- `/home/redmine/data/entrypoint.custom.sh`
- `/home/redmine/data/certs`

If you need low-level option details that are unchanged from upstream behavior, refer to the upstream README as supplemental background:

- [sameersbn/docker-redmine README](https://github.com/sameersbn/docker-redmine/blob/master/README.md)

Use the upstream document as reference, but prefer this repository's `Makefile`, compose files, and runtime scripts when behavior differs.

## Plugins

Plugins are still supported in this fork.

Place plugins in the data volume directory:

- `/srv/docker/redmine/<flavor>/plugins`

At startup, the entrypoint copies plugin files into the application, installs any required gems, and runs `redmine:plugins:migrate` when plugin contents change.

This fork also keeps support for optional lifecycle hooks:

- `plugins/pre-install.sh`
- `plugins/post-install.sh`

Use these only when a plugin needs extra packages, setup, or cron configuration.

Plugin compatibility remains version-specific. Redmine and Redmica upgrades can break plugin APIs, so test plugin-heavy environments before rolling out new images.

For plugin management patterns that are still broadly applicable, you can also consult:

- [sameersbn/docker-redmine plugin docs](https://github.com/sameersbn/docker-redmine/blob/master/README.md#plugins)

## Themes

Themes are still supported in this fork.

Place themes in the data volume directory:

- `/srv/docker/redmine/<flavor>/themes`

At startup, the entrypoint copies themes from the data volume into the application theme directory.

Theme compatibility is application-version dependent, especially when moving between Redmine and Redmica releases. Treat themes as application-level assets that need their own validation during upgrades.

For background details that still apply, see:

- [sameersbn/docker-redmine theme docs](https://github.com/sameersbn/docker-redmine/blob/master/README.md#themes)

## Maintenance

The container entrypoint still exposes the main maintenance commands:

- `app:init`
- `app:start`
- `app:rake`
- `app:backup:create`
- `app:backup:restore`

These are defined in [`entrypoint.sh`](./entrypoint.sh).

### Rake Tasks

You can run Redmine rake tasks against a running container with `docker compose exec` or `docker exec`.

Example:

```bash
docker compose exec redmine /sbin/entrypoint.sh app:rake redmine:email:test[admin] RAILS_ENV=production
```

### Backups

Backup and restore support is still implemented in the runtime scripts.

Create a backup:

```bash
docker compose exec redmine /sbin/entrypoint.sh app:backup:create
```

Restore a backup:

```bash
docker compose exec redmine /sbin/entrypoint.sh app:backup:restore
```

Backups include database content plus files, dotfiles, plugins, and themes from the data volume. By default they are stored under the configured backup path in the data directory.

If you use scheduled backups, configure:

- `REDMINE_BACKUP_SCHEDULE`
- `REDMINE_BACKUP_TIME`
- `REDMINE_BACKUP_EXPIRY`

### Shell Access

For debugging or inspection:

```bash
docker compose exec redmine bash
```

### Upgrade Practice

For this fork, the safe upgrade flow is:

- back up the current environment
- build the target flavor and version explicitly
- boot it against a test copy of the data when plugins or themes are installed
- confirm migrations complete successfully
- then replace production containers

The upstream maintenance notes are still useful as background for generic Redmine container operations:

- [sameersbn/docker-redmine maintenance docs](https://github.com/sameersbn/docker-redmine/blob/master/README.md#maintenance)

## Upgrade Policy

This fork intends to upgrade Redmine and Redmica intentionally, not automatically.

When bumping versions:

- verify the target version builds cleanly
- confirm the runtime boots with the default PostgreSQL compose setup
- review plugin and theme breakage risk separately
- document notable version changes in [`Changelog.md`](./Changelog.md) when appropriate

## Differences From Upstream

Important differences from `sameersbn/docker-redmine`:

- this repository treats Redmica as a supported flavor
- the recommended workflow is local build plus `docker compose`, not pulling a prebuilt upstream image
- issue tracking and changes for this fork should stay in this repository
- upstream release timing does not define this fork's roadmap

## Contributing

Contributions are welcome, especially for:

- Redmine or Redmica version bumps
- build fixes
- runtime fixes
- compose improvements
- documentation fixes

When contributing, please state clearly:

- which flavor you tested
- which version you tested
- whether the change affects build time, boot time, or runtime behavior

## Notes On Compatibility

Plugins, themes, and custom patches can break across Redmine or Redmica upgrades. This repository can provide the base image and runtime, but application-level compatibility remains environment-specific.

If your deployment depends on many third-party extensions, test upgrades in an isolated environment before replacing production containers.
