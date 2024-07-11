ARG BASE_IMAGE
ARG BASE_UPDATE
ARG CHOWN_LIST
ARG CONF_BASH
ARG INST_BASH
ARG PASS_ARGS
ARG PORTS_LIST
ARG REQUIREMENTS
ARG RUN_CMD
ARG SEC_BASH
ARG UID
ARG USERNAME

# 1. Get base image
FROM ${BASE_IMAGE}

# 1. Update base image, install container requirements and apply
#    security tweaks in base image
RUN ${BASE_UPDATE}          \
    && ${REQUIREMENTS}      \
    && mkdir -p scripts opt

# Copy to invalidate the layer on script change.
# 1. Create user and group
COPY --chmod=0755 scripts/${SEC_BASH} scripts/
RUN scripts/${SEC_BASH} \
    && groupadd -g ${UID} ${USERNAME} \
    && useradd -r -M -N -g ${UID} -u ${UID} ${USERNAME}

# 1. Install stuff
# Copy to invalidate the layer on script change.
COPY --chmod=0755 scripts/${INST_BASH} scripts/
RUN scripts/${INST_BASH}

# 1. Configure stuff
# 1. Chown all the things
# 1. Remove the install scripts
# Copy to invalidate the layer on script change.
COPY --chmod=0755 scripts/${CONF_BASH} scripts/
RUN scripts/${CONF_BASH}                              \
    && chown -R ${USERNAME}:${USERNAME} ${CHOWN_LIST} \
    && rm -r scripts

# 1. Go rootless
USER ${UID}

# 1. Expose ports
EXPOSE ${PORTS_LIST}

# 1. Add entrypoint
COPY --chown=${UID} --chmod=0755 ${RUN_CMD} opt/
ENTRYPOINT [ ${RUN_CMD} ]
