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
        "/home/helioviewer/api.helioviewer.org": "${workspaceFolder}"
    }
}
```

# Troubleshooting
If the helioviewer isn't loading for you, here are the first things to check.

## Submodules
The `helioviewer.org` repository relies on some submodules.
Make sure to run `git submodule update --init --recursive --remote` in the helioviewer.org repository.

## Bad configuration
On a clean setup, the container installs its own `Config.ini` and `Private.php` in `api/settings`, and `Config.js` in `helioviewer.org/resources/js/Utility`.

If you have modified these at all, then the container won't overwrite your own configuration, but it can lead to issues in the container.
Use the configurations [here](https://github.com/Helioviewer-Project/helioviewer.org-docker/tree/main/setup_files/app_config).

## Services not running
For simplicity, the single container runs all required services including:
- redis
- mysql
- httpd
- helioviewer specific background jobs

Most of these get started automatically when you start the container, but sometimes if the container doesn't shutdown properly (i.e. due to a sudden system shutdown), then they might not start up automatically on the next run.
You can check that these services are running and start them manually or just delete the container and start again.
