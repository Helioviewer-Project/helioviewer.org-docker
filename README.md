# HelioViewer Docker
This repo provides a containerized development environment for working with HelioViewer

# Usage
To run the dev environment:

- checkout the [api](https://github.com/Helioviewer-Project/api)
- checkout tho [app](https://github.com/Helioviewer-Project/helioviewer.org) repositories.
- In the app repository, get submodules with `git submodule update --init --recursive --remote`
- Run the following:
```
docker run -p 127.0.0.1:8080:80 -p 127.0.0.1:8081:81 -v "$PWD/api:/home/helioviewer/api.helioviewer.org" -v "$PWD/helioviewer.org:/home/helioviewer/helioviewer.org" -d -t dgarciabriseno/helioviewer.org
```

The important thing to note about the above command is that ports 8080 and 8081 are exposed, and that the api and helioviewer.org repositories are mounted in the container.

Now wait for the container to startup the server and then you can access the site by going to http://localhost:8080/

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