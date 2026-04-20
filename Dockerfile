# Build the manager binary
FROM --platform=$BUILDPLATFORM golang:1.25 AS builder

ARG TARGETARCH
ARG VERSION=dev
ARG SHA=unknown

WORKDIR /workspace

# Cache deps
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY main/ main/
COPY controllers/ controllers/
COPY cni/ cni/
COPY conf/ conf/
COPY version.go version.go

# Build for the target architecture
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build \
    -trimpath -installsuffix cgo \
    -ldflags "-s -w -X github.com/hyperspike/argocd-cluster-register.Version=${VERSION} -X github.com/hyperspike/argocd-cluster-register.Commit=${SHA}" \
    -o manager main/main.go

# Use distroless as minimal base image
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]
