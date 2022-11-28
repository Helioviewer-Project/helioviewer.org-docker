# HelioViewer Docker
This repo provides a containerized development environment for working with HelioViewer

# Installation
If you just want the easiest setup without dealing with dockerfiles and building
containers, then grab the pre-built container [here](https://hub.docker.com/repository/docker/dgarciabriseno/helioviewer.org-docker/general)

# Manual Setup
Open a terminal and clone this repository.
```bash
git clone git@github.com:Helioviewer-Project/helioviewer.org-docker.git
```

cd into the cloned folder and pull the helioviewer sources with the following commands
```bash
git submodule update --init --recursive --remote
```

Next, create a folder to use as the sample data. Let's call it `sample-data`.
Your directory structure should look like this with these 3 folders. (Extra
items are ok.)
```
- api
- helioviewer.org
- sample-data
```

Next, to build the container, run Docker and then execute the following command:
```bash
docker build -t helioviewer-dev:test .
```

Now spin up the container using the provided run.sh
*Note* - if you have different paths for any folders (api, helioviewer.org, or sample-data)
or if you built the container with a different name, then you can specify these in run.sh
```bash
./run.sh
```

Once the container is running, open it in Docker. To complete the setup,
run the provided install.sh script located in /root this will setup the database
and complete installation so the container is ready to go.
```bash
cd /root/setup_files/scripts
./install.sh
```

When prompted, enter the following:
- For Location of JP2 Images: /var/www/jp2
- Enter [1], you do want to create the database schema
- Leave the fields blank for Database name, username, and password to use the defaults
- Leave database host as localhost
- Enter [1] for desired database to select MySQL
- Leave username and password blank

At this point the development container is all set up.
Any changes you make to the api, helioviewer.org, and sample-data folders
will be reflected in the container.

Lastly, run the following to download jp2 images to view
```bash
cd /root/setup_files/scripts
./download_data.sh
```

You can access the site by going to http://localhost:8080/

# Other Notes
- The run script assumes you will be using ports 8080 and 8081. Modify the docker run command in
  run.sh if you need to change this.
