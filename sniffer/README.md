# resurfaceio-network-sniffer/buildx

Dockerfiles and scripts to build and push official `resurfaceio/network-sniffer` images

## Building multi-architecture images with docker buildx

### Compiling from source

By passing the `--platform` option, docker buildx can build docker images for specific
architectures. Buildx selects the base images accordingly and can use the binaries of the client's
native architecture to generate new binaries for the target architecture. However, this not
always works, especially for compilation since all the necessary libraries must be available at
build time.

The `Dockerfile` is constructed in two stages: one to compile the sniffer binary file using go, and
another for running the sniffer itself. Because of the previous caveat, the `network-sniffer` image
can only be built from the same architecture as the target one.


### Using remote builders

Both the docker remote daemon and buildx features can be leveraged in order to produce true
multiplaform images, as no emulation or even cross compilation takes place.

In the `network-sniffer.sh` script two EC2 instances are used as distinct nodes for a docker buildx
builder, one running the `arm64` architecture and another one running `amd64`. Each create a docker
image using the same `Dockerfile`, with both build and runtime stages execution happening natively.

The script takes two positional arguments: a docker tag, and a binary version. Both values are needed
in order for the build process to take place. For example:

```bash
./network-sniffer.sh 1.2.4 1.3.6-Resurface
```

Will build and push the `resurfaceio/network-sniffer:1.2.4` image, running the `gor` binary with its 
version being `1.3.6-Resurface`.

The script will ask for an AWS profile in order to run the `aws ec2` commands properly. You must be 
logged in your docker client and be part of the `resurfaceio` organization in order to push images
to the `resurfaceio/network-sniffer` repository.
