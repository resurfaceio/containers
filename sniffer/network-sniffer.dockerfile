FROM --platform=$BUILDPLATFORM golang:1.18 AS build
RUN apt-get update && apt-get install -y flex bison git && wget http://www.tcpdump.org/release/libpcap-1.10.0.tar.gz && tar xzf libpcap-1.10.0.tar.gz && cd libpcap-1.10.0 && ./configure && make install
RUN git clone https://github.com/resurfaceio/goreplay.git
RUN cd goreplay && git checkout resurface && go mod download
ARG TARGETOS TARGETARCH
RUN cd goreplay && GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags "-extldflags \"-static\"" .

FROM alpine
COPY --from=build /go/goreplay /bin/gor
ENTRYPOINT gor ${K8S_INPUT:---input-raw $VPC_MIRROR_DEVICE:$APP_PORT --input-raw-bpf-filter "(dst port $APP_PORT) or (src port $APP_PORT)"} --input-raw-track-response  --output-resurface $USAGE_LOGGERS_URL --output-resurface-rules "$(echo -e $USAGE_LOGGERS_RULES)"
