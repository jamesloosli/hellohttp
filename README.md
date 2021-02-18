# hellohttp

Helloworld, but http

## Build

For running locally while developing, `make start` will compile and start the server. This will also watch the project directory for changes, and restart the application on each update.

For testing the service as a docker container, `make docker` will ... make a container.

## Test

TODO: Add tests.

## Release

All merges to master trigger a build, and push a new container to dockerhub.

## Deploy

To deploy the base infrastructure and default service, use the deploy script;

```
deploy.sh create 4.2.0
```

Once that's in place, you can re-run the script with a newer version to update that default service.

To deploy a 'canary' version, you also need to specify a path prefix.

```
deploy.sh canary 4.2.2
```