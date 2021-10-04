REPO       ?= vdaas
NAME        = vald
VALDREPO    = github.com/$(REPO)/$(NAME)

PYTHON = python3

VALD_DIR    = vald-origin

PWD    := $(eval PWD := $(shell pwd))$(PWD)
GOPATH := $(eval GOPATH := $(shell go env GOPATH))$(GOPATH)

PROTO_ROOT  = $(VALD_DIR)/apis/proto
PB2DIR_ROOT = src

SHADOW_ROOT = vald

PROTOS = \
	v1/filter/ingress/ingress_filter.proto \
	v1/payload/payload.proto
PROTOS := $(PROTOS:%=$(PROTO_ROOT)/%)
SHADOWS = $(PROTOS:$(PROTO_ROOT)/%.proto=$(SHADOW_ROOT)/%.proto)
PB2PYS  = $(PROTOS:$(PROTO_ROOT)/%.proto=$(PB2DIR_ROOT)/$(SHADOW_ROOT)/%_pb2.py)

PROTO_PATHS = \
	$(PWD) \
	$(PWD)/$(VALD_DIR) \
	$(PWD)/$(PROTO_ROOT) \
	$(GOPATH)/src \
	$(GOPATH)/src/github.com/googleapis/googleapis \
	$(GOPATH)/src/github.com/envoyproxy/protoc-gen-validate

red    = /bin/echo -e "\x1b[31m\#\# $1\x1b[0m"
green  = /bin/echo -e "\x1b[32m\#\# $1\x1b[0m"
yellow = /bin/echo -e "\x1b[33m\#\# $1\x1b[0m"
blue   = /bin/echo -e "\x1b[34m\#\# $1\x1b[0m"
pink   = /bin/echo -e "\x1b[35m\#\# $1\x1b[0m"
cyan   = /bin/echo -e "\x1b[36m\#\# $1\x1b[0m"

.PHONY: all
## execute clean and proto
all: clean proto

.PHONY: clean
## clean
clean:
	rm -rf $(PB2DIR_ROOT)/google $(PB2DIR_ROOT)/vald $(PB2DIR_ROOT)/validate
	rm -rf $(SHADOW_ROOT)
	rm -rf $(VALD_DIR)

.PHONY: proto
## build proto
proto: \
	$(PB2PYS) \
	$(PB2PY_VALIDATE) \
	$(PB2PY_GOOGLEAPIS) \
	$(PB2PY_GOOGLERPCS)

$(PROTOS): $(VALD_DIR)
$(SHADOWS): $(PROTOS)
$(SHADOW_ROOT)/%.proto: $(PROTO_ROOT)/%.proto
	mkdir -p $(dir $@)
	cp $< $@
	sed -i -e 's:^import "apis/proto/:import "$(SHADOW_ROOT)/:' $@
	sed -i -e 's:^import "github.com/envoyproxy/protoc-gen-validate/:import ":' $@
	sed -i -e 's:^import "github.com/googleapis/googleapis/:import ":' $@

$(PB2DIR_ROOT):
	mkdir -p $@

$(PB2PYS): proto/deps $(PB2DIR_ROOT) $(SHADOWS)
$(PB2DIR_ROOT)/$(SHADOW_ROOT)/%_pb2.py: $(SHADOW_ROOT)/%.proto
	@$(call green, "generating pb2.py files...")
	$(PYTHON) \
		-m grpc_tools.protoc \
		$(PROTO_PATHS:%=-I %) \
		--python_out=$(PWD)/$(PB2DIR_ROOT) \
		--grpc_python_out=$(PWD)/$(PB2DIR_ROOT) \
		$<

$(PB2PY_VALIDATE): $(GOPATH)/src/github.com/envoyproxy/protoc-gen-validate
	@$(call green, "generating pb2.py files...")
	(cd $(GOPATH)/src/github.com/envoyproxy/protoc-gen-validate; \
		$(PYTHON) \
			-m grpc_tools.protoc \
			$(PROTO_PATHS:%=-I %) \
			-I $(GOPATH)/src/github.com/envoyproxy/protoc-gen-validate \
REPO       ?= vdaas
			--python_out=$(PWD)/$(PB2DIR_ROOT) \
			--grpc_python_out=$(PWD)/$(PB2DIR_ROOT) \
			validate/validate.proto)

$(PB2PY_GOOGLEAPIS): $(GOPATH)/src/github.com/googleapis/googleapis
	@$(call green, "generating pb2.py files...")
	(cd $(GOPATH)/src/github.com/googleapis/googleapis; \
		$(PYTHON) \
			-m grpc_tools.protoc \
			$(PROTO_PATHS:%=-I %) \
			-I $(GOPATH)/src/github.com/googleapis/googleapis \
			--python_out=$(PWD)/$(PB2DIR_ROOT) \
			--grpc_python_out=$(PWD)/$(PB2DIR_ROOT) \
			google/api/annotations.proto)

$(PB2PY_GOOGLERPCS): $(GOPATH)/src/github.com/googleapis/googleapis
	@$(call green, "generating pb2.py files...")
	(cd $(GOPATH)/src/github.com/googleapis/googleapis; \
		$(PYTHON) \
			-m grpc_tools.protoc \
			$(PROTO_PATHS:%=-I %) \
			-I $(GOPATH)/src/github.com/googleapis/googleapis \
			--python_out=$(PWD)/$(PB2DIR_ROOT) \
			--grpc_python_out=$(PWD)/$(PB2DIR_ROOT) \
			google/rpc/status.proto)

$(VALD_DIR):
	git clone --depth 1 https://$(VALDREPO) $(VALD_DIR)

.PHONY: proto/deps
## install proto deps
proto/deps: \
	$(GOPATH)/src/github.com/googleapis/googleapis \
	$(GOPATH)/src/github.com/envoyproxy/protoc-gen-validate

$(GOPATH)/src/github.com/googleapis/googleapis:
	git clone \
		--depth 1 \
		https://github.com/googleapis/googleapis \
		$(GOPATH)/src/github.com/googleapis/googleapis

$(GOPATH)/src/github.com/envoyproxy/protoc-gen-validate:
	git clone \
		--depth 1 \
		https://github.com/envoyproxy/protoc-gen-validate \
		$(GOPATH)/src/github.com/envoyproxy/protoc-gen-validate
