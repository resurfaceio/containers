# resurfaceio-network-sniffer

Capture detailed API calls from network traffic to your own [data lake](http://resurface.io/).

Dockerfiles and scripts to build and push official `resurfaceio/network-sniffer` images

## Capturing network traffic

Resurface uses [GoReplay](https://github.com/resurfaceio/goreplay) to capture HTTP traffic directly from network devices in userspace. Think tcpdump or Wireshark but without having to go through any of the packet reassembly or parsing process yourself.

Our sniffer runs as an independent containerized application. It captures packets from network interfaces, reassembles them, parses both HTTP request and response, packages the entire API calls, and sends it to your Resurface DB instance automatically.

After modifying the `.env` file with the required environment variables, just run the following docker command in the host machine:

```bash
docker run -d --name netsniffer --env-file .env --network host resurfaceio/network-sniffer:1.2.3
```

The `--network host` option must be specified in to capture traffic from other containers (or non-containerized apps) running in the machine.

## Building multi-architecture images with docker buildx

### Compiling from source

The `Dockerfile` is constructed in two stages: one to compile the sniffer using `go build`, and
another for running the binary file itself.

Docker buildx selects the base images according to the `--platform` option, and it can usually
generate binaries for the target architecture using binaries from the client's native
architecture. However, this not always works, especially if all the necessary libraries for the
target architecture must be available and pre-compiled at build time. Because of this, **the
`network-sniffer` image can only be built from the same architecture as the target one**.


### Using remote builders

Both the docker remote daemon and buildx features are leveraged in the `network-sniffer.sh`
script in order to produce true multiplaform images, as no emulation or even cross compilation
takes place. Just run the follwoing command:

```bash
./network-sniffer.sh x.y.z a.b.c-Resurface
```

The script takes two positional arguments: an `x.y.z` docker tag, and a custom version
`a.b.c-Resurface` for the sniffer binary file. Both values are needed in order for the build
process to take place. For example:

```bash
./network-sniffer.sh 1.2.4 1.3.6-Resurface
```

Will build and push the `resurfaceio/network-sniffer:1.2.4` image, running the `gor` binary with its 
version being `1.3.6-Resurface`.

The script spins up two EC2 instances to be used as distinct nodes for a docker buildx builder: a
graviton (`arm64`) machine and one t2 instance (`amd64`). Each node then creates a docker image using
the same `Dockerfile`, with both build and runtime stages execution happening natively.

The script will ask for an AWS profile in order to run the `aws ec2` commands properly. You must be 
logged in your docker client and be part of the `resurfaceio` organization in order to push images
to the `resurfaceio/network-sniffer` repository.
