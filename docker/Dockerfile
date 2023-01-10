FROM golang:1.17.6 as builder
MAINTAINER multiversx

RUN apt-get update && apt-get install -y

WORKDIR /config
COPY . .

WORKDIR /go
RUN git clone https://github.com/multiversx/mx-chain-go.git && cd mx-chain-go && git checkout --force $(cat /config/binaryVersion)
WORKDIR /go/mx-chain-go

# MultiversX node
WORKDIR /go/mx-chain-go/cmd/node
RUN go build -i -v -ldflags="-X main.appVersion=$(git --git-dir /config/.git describe --tags --long --dirty)"
RUN cp /go/pkg/mod/github.com/!elrond!network/arwen-wasm-vm@$(cat /go/mx-chain-go/go.mod | grep arwen-wasm-vm | sed 's/.* //' | tail -n 1)/wasmer/libwasmer_linux_amd64.so /lib/libwasmer_linux_amd64.so

WORKDIR /config
RUN cp -r * /go/mx-chain-go/cmd/node/config/

WORKDIR /go/mx-chain-go/cmd/node

# ===== SECOND STAGE ======
FROM ubuntu:22.04
RUN apt-get update -y && apt-get upgrade -y
COPY --from=builder "/go/mx-chain-go/cmd/node" "/go/mx-chain-go/cmd/node/"
COPY --from=builder "/lib/libwasmer_linux_amd64.so" "/lib/libwasmer_linux_amd64.so"
WORKDIR /go/mx-chain-go/cmd/node/
EXPOSE 8080
ENTRYPOINT ["/go/mx-chain-go/cmd/node/node", "--rest-api-interface=:8080"]
