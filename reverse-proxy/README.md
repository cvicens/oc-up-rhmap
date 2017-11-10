# NGNIX Docker image

## Clone this repo

```
$ git clone https://github.com/cvicens/
```

## Set up environment to name the image properly

```
export PROJECT_ID="rhmap"
export IMAGE_NAME="rhmap-reverse-proxy"
export IMAGE_VERSION="v1.0"
export CONTAINER_NAME="rhmap-reverse-proxy"
```

## Build the image

```
docker build -t $PROJECT_ID/$IMAGE_NAME:$IMAGE_VERSION .
```

## Now let's run the image

```
docker run -p=80:80 -it --rm -v $(pwd)/projects:/usr/projects  --name $CONTAINER_NAME $PROJECT_ID/$IMAGE_NAME:$IMAGE_VERSION /bin/bash
```

## Example: running a cloud app and a service locally
Running locally a Cloud App that in its turn call a service also running locally.

### Run the container exposing 8001

```
docker run -p=8001:8001 -it --rm -v $(pwd)/projects:/usr/projects --name $CONTAINER_NAME $PROJECT_ID/$IMAGE_NAME:$IMAGE_VERSION /bin/bash
```

### Running the service in background

Clone both repos and run ``npm install`` (Cloud App and Service) then change dir to the service folder and run.

```
$ nohup grunt serve &
```

Now move to the cloud app folder and run

```
$ grunt serve:local
```

Finally use Postman, for instance, to call you cloud app running on port 8001 on your localhost.

### Stop all and exit
Type Ctrl+C and exit
