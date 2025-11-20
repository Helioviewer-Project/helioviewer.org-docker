# Helioviewer Docker
This repo provides a containerized development environment for working with Helioviewer

# Usage
To run the dev environment, install [Docker](https://docs.docker.com/get-docker/)

Once installed clone this repo and run docker compose:

```bash
git clone --recurse-submodules https://github.com/helioviewer-project/helioviewer.org-docker.git
cd helioviewer.org-docker
mv .env.example .env
docker compose up -d --wait
```

It may take a while for the containers to be built and the application to start up.
Once the output from docker settles down, check that it's running by going to http://localhost:8080/

## ESAJPIP Usage

This compose project supports running esajpip alone without the web front end.

1. Clone this repository with recurse submodules:
   ```bash
   git clone --recurse-submodules https://github.com/helioviewer-project/helioviewer.org-docker.git
   cd helioviewer.org-docker
   ```

2. Configure environment variables:
   ```bash
   mv .env.example .env
   ```
   Set variables accordingly. If you already have data, then set `USE_TEST_DATA=false`.

3. Create the required folders:
   ```bash
   mkdir -p data/jp2 data/logs data/cache
   ```
   All your JPEGs should be placed in `data/jp2`. If your data is not in `data/jp2`, you can specify the path in the x-volumes section of `compose.yaml`. It should point to the top level directory containing jp2 files. The jp2 files may be in subdirectories.

4. Run the JPIP server:
   ```bash
   docker compose up jpip
   ```

## Configuration

Configuration is made via the `.env` file. By default this is set to
bind and run everything on localhost. You can change this by editing `.env`

## Secure Connections

If you plan to host this in production, you'll want to use SSL/TLS. To set this up:

- For the Helioviewer API: Use nginx or Apache as a reverse proxy
- For ESAJPIP: Note that a reverse proxy doesn't work for the JPIP protocol. Instead, use a socat tunnel:

```bash
/usr/bin/socat SSL-L:$PUBLIC_JPIP_PORT,reuseaddr,fork,cafile=path/to/your/ca.crt,cert=path/to/your/cert.crt,key=path/to/your/private.key,verify=0 TCP:127.0.0.1:$JPIP_CONTAINER_PORT
```

Replace `$PUBLIC_JPIP_PORT` with your desired public port and `$JPIP_CONTAINER_PORT` with the port exposed by the JPIP container. Update the certificate paths accordingly.

You also need to update the API Configuration to point to your public JPIP URL by editing `api/settings/Config.ini` and updating the `[urls]` section:

```ini
[urls]
; The URL that corresponds with the root_dir specified above. This is your API root
web_root_url     = http://localhost

; The URL that corresponds with the jp2_dir specified above.
jp2_root_url     = http://localhost/jp2

; The root URL to your JPIP server if one is available.
jpip_root_url    = jpip://localhost:8090
```

Update these URLs to your domain. With JPIP served over SSL/TLS with socat, set the scheme to `jpips://` (e.g., `jpips://yourdomain.com:8090`).

# Testing
For contributors to this environment, you can write tests to verify that the
Helioviewer environment is working. The `tests` folder contains scripts that
test a particular feature of Helioviewer.

After creating a test, add it to the `Test Helioviewer environment` step in
`.github/workflows/build-check.yaml


## Debugging
The container has xdebug configured for debugging.
If you have xdebug listening on port 9003 (the default xdebug port), then php code running in the container will trigger debug requests.

Client configuration may vary.

### VSCode
For vscode, install the PHP Debug extension provided by xdebug and use the following configuration:
```json
{
    "name": "Listen for Xdebug",
    "type": "php",
    "request": "launch",
    "port": 9003,
    "pathMappings": {
        "/var/www/api.helioviewer.org": "${workspaceFolder}"
    }
}
```

# Troubleshooting
If the helioviewer isn't loading for you, here are the first things to check.

## Submodules
The `helioviewer.org` repository relies on some submodules.
Make sure to run `git submodule update --init --recursive --remote` in the helioviewer.org repository.
If you cloned this repo with `--recurse-submodules` then this likely isn't the problem.

## Bad configuration
On a clean setup, the container installs its own `Config.ini` and `Private.php` in `api/settings`, and `Config.js` in `helioviewer.org/resources/js/Utility`.

Double check these files if you're getting strange errors. Config.js should point to `localhost:8080/8081` and not `*helioviwer.org`.


## Services not running
There are 5 primary containers that make up this environment
- redis
- mariadb
- API server
- Web Server
- Movie Builder

There is also a "CLI" container, which doesn't provide any direct service, but is useful for development purposes like downloading test data or accessing application data.

If any of the primary containers aren't running properly, this could be the source of some issues.

## XDebug Ports
If anything is listening on port 9003 besides xdebug, it can interfere with the xdebug extension running in the container.

The **Jupyter** extensions by microsoft use port 9003 when you are working with a python notebook in vscode.
This will interfere with the xdebug extension in the container, and it will seem like the webserver has hung.

If everything seems like it should be working, but requests are hanging for no apparent reason, check if you have a running process listening on port 9003.
