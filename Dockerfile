FROM harbor.devops.kubesphere:30280/library/golang:1.11.3-alpine3.8 as builder

WORKDIR /go/src/kubesphere.io/devops-go-sample/

COPY . .

RUN go build -o hello-world

FROM harbor.devops.kubesphere:30280/library/alpine

COPY --from=builder /go/src/kubesphere.io/devops-go-sample/hello-world /usr/local/bin/

EXPOSE 8080
CMD ["/usr/local/bin/hello-world"]
