all: kerberos foreman cobbler

include Makefile.kerberos
include Makefile.foreman
include Makefile.cobbler

# ^^ To add a new image project, add to "all" target and add an include.

cname='Dreamtrack Cloud CA'
country=GB
alt_names=www.dreamtrack.net,web.dreamtrack.net
scn=cloud.dreamtrack.net
email=admin@dreamtrack.net
org='Dreamtrack Corp.'

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
	scripts/upload.bash \
		"$(upload)" \
		"${remote}" \
		"${image}"  \
		"${tag}"
endef

BOTAN_RNG=--format=base64 100
BOTAN_KEYGEN=--algo=Ed25519 --params=Ed25519
BOTAN_GENSS=${cak_file} "${cname}" --ca --days=3650 --path-limit=2 \
	--country=${country} --organization="${org}"

#BOTAN_GENPK=${SK} "${scn}" --dns="${alt_names}" \
#	--email="${email}" --country=${country} --organization="${org}"

# ??? https://stackoverflow.com/a/54776239

certs:
	mkdir -p certs

cap_file = 'certs/ca-password.txt'
vpath %-password.txt certs
ca-password.txt: certs
	chmod -f 0600 $(cap_file) || true
	botan rng $(BOTAN_RNG) \
		| dd status=none of=$(cap_file)
	@# Remove end-of-line mark
	truncate -s -1 $(cap_file)
	chmod 0400 $(cap_file)

cak_file = 'certs/ca.key'
vpath %.key certs
ca.key: ca-password.txt
	#echo cap_file=$(cap_file)
	chmod -f 0600 ${cak_file} || true
	$(eval ca_pw=$(shell more $(cap_file)))
	echo ca_pw=$(ca_pw)
	botan keygen $(BOTAN_KEYGEN) --passphrase="${ca_pw}" \
		| dd status=none of=$(cak_file)
	# Check private key is valid
	openssl pkey -check -in ${cak_file} -passin=pass:$(ca_pw) -noout
	chmod 0400 ${cak_file}

OSSL_KEY_HASH=-pubout -in ${cak_file} -passin=file:${cap_file} \
	-noout -text
OSSL_CRT_HASH=-pubkey -in ${cac_file} -noout -text

cac_file = 'certs/ca.crt'
cak_sh_file = '/dev/shm/cak_hash'
cac_sh_file = '/dev/shm/cac_hash'
cac_akid_file = '/dev/shm/cak_akid'
cac_skid_file = '/dev/shm/cac_skid'
vpath %.crt certs
ca.crt: ca.key
	chmod -f 0600 ${cac_file} || true
	$(eval ca_pw=$(shell more $(cap_file)))
	botan gen_self_signed $(BOTAN_GENSS) --key-pass="${ca_pw}" \
		| dd status=none of=${cac_file}
	openssl pkey ${OSSL_KEY_HASH} \
		| sed '1d' \
		| xargs \
		| sha256sum - \
		| dd status=none of=${cak_sh_file}
	openssl x509 ${OSSL_CRT_HASH} \
		| grep -A3 pub: \
		| xargs \
		| sha256sum - \
		| dd status=none of=${cac_sh_file}
	$(eval cak_sh=$(shell more ${cak_sh_file}))
	$(eval cac_sh=$(shell more ${cac_sh_file}))
ifeq (${cak_sh},${cac_sh})
	echo Key and cert match.
else
	echo Certificate generation failed, try creating manually.
endif
	botan cert_info ${cac_file} \
		| grep "Authority keyid" \
		| cut -d: -f2 \
		| dd status=none of=${cac_akid_file}
	botan cert_info ${cac_file} \
		| grep "Subject keyid" \
		| cut -d: -f2 \
		| dd status=none of=${cac_skid_file}
	$(eval ca_akid=$(shell more ${cac_akid_file}))
	$(eval ca_skid=$(shell more ${cac_skid_file}))
ifeq (${ca_akid},${ca_skid})
	echo Certificate is self-signed.
else
	echo Certificate generation failed, try creating manually.
endif
	chmod 0444 ${cac_file}

.PHONY: clean
clean:
	rm -rf ./certs
	@# delete image(s) from buildah?
