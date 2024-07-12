all: kerberos foreman cobbler

include Makefile.kerberos
include Makefile.foreman
include Makefile.cobbler

# ^^ To add a new image project, add to "all" target and add an include.

licence = IDGAF
maintainer = Adam J. Richardson
repo = https://github.com/dreamtrack-net/container_images
# rename img_repo or similar
remote = ghcr.io
uid = 900
username = _$@

secure = scripts/$@_secure.bash
install = scripts/$@_install.bash
config = scripts/$@_config.bash
run = scripts/$@_run.bash

pass_args = $(foreach a,$(args),$(a))

lblpfx=org.opencontainers.image

tag_date=$(shell /usr/bin/date +'%F')
tag_time=$(shell /usr/bin/date +'%T' | /usr/bin/tr ':' '-')
tag=${tag_date}T${tag_time}Z

define upload-image =
	buildah login ${remote}
	buildah push ${image}:latest
	buildah push ${image}:${tag_date}
	buildah push ${image}:${tag}
endef

define buildah-bud =
	buildah bud --http-proxy=false              \
	--compress=true --layers=true --format=oci  \
	-t ${image}:latest -t ${image}:${tag_date}  \
	-t ${image}:${tag}                          \
	--build-arg=BASE_IMAGE=${base_image}        \
	--build-arg=BASE_UPDATE="${base_update}"    \
	--build-arg=REQUIREMENTS="${requirements}"  \
	--build-arg=SEC_BASH="${secure}"            \
	--build-arg=INST_BASH="${install}"          \
	--build-arg=CONF_BASH="${config}"           \
	--build-arg=UID="${uid}"                    \
	--build-arg=USERNAME="${username}"          \
	--build-arg=CHOWN_LIST="${chown_list}"      \
	--build-arg=PORTS_LIST="${ports_list}"      \
	--build-arg=RUN_CMD="${run}"                \
	--build-arg=PASS_ARGS="${pass_args}"        \
	--label=description="${desc}"               \
	--label=maintainer="${maintainer}"          \
	--label=${lblpfx}.base.name="${base_image}" \
	--label=${lblpfx}.created="${tag}"          \
	--label=${lblpfx}.description="${desc}"     \
	--label=${lblpfx}.licenses="${licence}"     \
	--label=${lblpfx}.source="${repo}"          \
	--label=${lblpfx}.title="${title}"          \
	--label=name="${title}"                     \
	--label=summary="${desc}"                   \
	--label=build-date="${tag_date}"            \
	--label=release="${tag_date}"
	@# --log-level debug
	@# Add "upload=y" to make invocation to upload
	$(if $(findstring(y,$(upload))),$(upload-image))
endef

clean:
	echo clean
	@# delete image(s) from buildah?
