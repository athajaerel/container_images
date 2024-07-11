# 1. Get base image
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# 1. Update base image
ARG BASE_UPDATE
RUN ${BASE_UPDATE}

# 1. Install container requirements
ARG REQUIREMENTS
RUN ${REQUIREMENTS}

# Pass through some arguments to the bash scripts
ARG PASS_ARGS

# 1. Security tweaks in base image
# Copy to invalidate the layer on script change.
RUN mkdir -p /scripts
ARG SEC_BASH
COPY ${SEC_BASH} /scripts
RUN ${SEC_BASH}

# 1. Create user and group
ARG UID
ARG USERNAME
RUN groupadd -g ${UID} ${USERNAME}                      \
    && useradd -r -M -N -g ${UID} -u ${UID} ${USERNAME}

# 1. Install stuff
# Copy to invalidate the layer on script change. Delete self.
ARG INST_BASH
COPY ${INST_BASH} /scripts
RUN ${INST_BASH}

# 1. Configure stuff
# Copy to invalidate the layer on script change. Delete self.
ARG CONF_BASH
COPY ${CONF_BASH} /scripts
RUN ${CONF_BASH}

# 1. Chown all the things
ARG CHOWN_LIST
RUN chown -R ${USERNAME}:${USERNAME} ${CHOWN_LIST}

# 1. Remove the install scripts
RUN rm -r /scripts

# 1. Go rootless
USER ${UID}

# 1. Expose ports
ARG PORTS_LIST
EXPOSE ${PORTS_LIST}

# 1. Add entrypoint
ARG RUN_CMD
RUN mkdir -p /opt
COPY --chown=${UID} --chmod=0755 ${RUN_CMD} /opt
ENTRYPOINT [ ${RUN_CMD} ]
