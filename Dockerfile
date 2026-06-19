ARG BUILDER_IMAGE
ARG TARGETARCH

FROM ${BUILDER_IMAGE} as builder

WORKDIR /build
COPY . .

RUN mkdir /artifacts
RUN make GOARCH=${TARGETARCH} PREFIX=/artifacts cmds

RUN mkdir /toolkit
RUN git clone --branch datadog --depth 1 \
    https://github.com/DataDog/nvidia-container-toolkit /toolkit/nct && \
    cd /toolkit/nct && \
    make PREFIX=/toolkit cmds


FROM registry.ddbuild.io/images/nvidia-cuda-base:12.9.0

ENV NVIDIA_DISABLE_REQUIRE="true"
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=utility

USER root

COPY --from=builder   /toolkit/nvidia-cdi-hook                  /usr/bin/nvidia-cdi-hook
COPY --from=builder   /artifacts/compute-domain-controller      /usr/bin/compute-domain-controller
COPY --from=builder   /artifacts/compute-domain-kubelet-plugin  /usr/bin/compute-domain-kubelet-plugin
COPY --from=builder   /artifacts/compute-domain-daemon          /usr/bin/compute-domain-daemon
COPY --from=builder   /artifacts/gpu-kubelet-plugin             /usr/bin/gpu-kubelet-plugin
COPY --from=builder   /artifacts/webhook                        /usr/bin/webhook

COPY scripts/bind_to_driver.sh                               /usr/bin/bind_to_driver.sh
COPY scripts/unbind_from_driver.sh                           /usr/bin/unbind_from_driver.sh
COPY hack/kubelet-plugin-prestart.sh                         /usr/bin/kubelet-plugin-prestart.sh
COPY templates /templates
