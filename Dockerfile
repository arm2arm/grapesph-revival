# Reproducible CPU-only GRAPE-3 compatibility experiment.
# Pin base image digest for production publication once CI is established.
FROM debian:12-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc gfortran make libc6-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY Makefile ./
COPY src/ ./src/
RUN make all && make test

FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgfortran5 libquadmath0 && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/bin/grape3_demo /usr/local/bin/grape3_demo
RUN useradd --uid 10001 --create-home --shell /usr/sbin/nologin researcher \
    && mkdir -p /workspace/results && chown -R 10001:10001 /workspace
USER researcher
WORKDIR /workspace
CMD ["/usr/local/bin/grape3_demo", "results/demo.csv"]