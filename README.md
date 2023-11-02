# Helioviewer Docker
This repo provides a containerized development environment for working with Helioviewer

# Usage
To run the dev environment, install [Docker](https://docs.docker.com/get-docker/)

Once installed clone this repo and run docker compose:

```bash
git clone --recurse-submodules https://github.com/Helioviewer-Project/helioviewer.org-docker.git
cd helioviewer.org-docker
docker compose up
```

It may take a while for the containers to be built and the application to start up.
Once the output from docker settles down, check that it's running by going to http://localhost:8080/

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
