FROM golang:alpine3.16 AS build
RUN apk add --no-cache --upgrade linux-headers build-base make git flex bison && wget http://www.tcpdump.org/release/libpcap-1.10.1.tar.gz && tar xzf libpcap-1.10.1.tar.gz && cd libpcap-1.10.1 && ./configure && make install
RUN git clone https://github.com/resurfaceio/goreplay.git && cd goreplay && git checkout resurface
WORKDIR /go/goreplay
ARG TARGETOS TARGETARCH GORVER
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/gor -ldflags "-extldflags=-static -X main.VERSION=$GORVER" .

FROM alpine:3.16
COPY --from=build /out/gor /bin
ENTRYPOINT gor ${K8S_INPUT:---input-raw $VPC_MIRROR_DEVICE:$APP_PORT --input-raw-bpf-filter "(dst port $APP_PORT) or (src port $APP_PORT)"} --input-raw-track-response  --output-resurface $USAGE_LOGGERS_URL --output-resurface-rules "$(echo -e $USAGE_LOGGERS_RULES)"
