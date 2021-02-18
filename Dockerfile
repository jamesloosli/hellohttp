FROM golang:alpine AS build-env
RUN apk add make git
WORKDIR /src
ADD . /src
ARG VERSION
ARG BUILD
RUN cd /src && go build -o binary -ldflags "-X=main.Version=${VERSION} -X=main.Build=${BUILD}"

FROM alpine
WORKDIR /app
COPY --from=build-env /src/binary /app/
ENTRYPOINT ./binary
