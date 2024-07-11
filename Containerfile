ARG BASE_IMAGE
ARG BASE_UPDATE
ARG REQUIREMENTS
ARG PASS_ARGS
ARG SEC_BASH
ARG UID
ARG USERNAME
ARG INST_BASH
ARG CONF_BASH
ARG CHOWN_LIST

# 1. Stage
FROM ${BASE_IMAGE} AS build1
WORKDIR /build1

# 1. Update base image and install container requirements
RUN ${BASE_UPDATE}            \
    && ${REQUIREMENTS}        \
    && mkdir -p /scripts /opt

# 1. Security tweaks in base image
# 1. Create user and group
# Copy to invalidate the layer on script change.
COPY scripts/${SEC_BASH} /scripts
RUN ls -l scripts/${SEC_BASH}                           \
    && scripts/${SEC_BASH}                              \
    && groupadd -g ${UID} ${USERNAME}                   \
    && useradd -r -M -N -g ${UID} -u ${UID} ${USERNAME}

# 1. Install stuff
# Copy to invalidate the layer on script change. Delete self.
COPY ${INST_BASH} /scripts
RUN ${INST_BASH}

# 1. Configure stuff
# 1. Chown all the things
# 1. Remove the install scripts
# Copy to invalidate the layer on script change. Delete self.
COPY ${CONF_BASH} /scripts
RUN ${CONF_BASH}                                      \
    && chown -R ${USERNAME}:${USERNAME} ${CHOWN_LIST} \
    && rm -r /scripts

# 1. Stage
FROM ${BASE_IMAGE}
COPY --from=build1 /build1 /

ARG PORTS_LIST
ARG RUN_CMD

# 1. Go rootless
USER ${UID}

# 1. Expose ports
EXPOSE ${PORTS_LIST}

# 1. Add entrypoint
COPY --chown=${UID} --chmod=0755 ${RUN_CMD} /opt
ENTRYPOINT [ ${RUN_CMD} ]
