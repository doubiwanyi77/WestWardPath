SKYNET_ROOT ?= /home/zp/skynet

.PHONY: check deps down run run-service run-gate service-node gate-node

check:
	@test -x "$(SKYNET_ROOT)/skynet" || (echo "找不到 skynet: $(SKYNET_ROOT)/skynet" && exit 1)

deps:
	docker compose up -d

down:
	docker compose down

run-service service-node: check
	"$(SKYNET_ROOT)/skynet" config.service_node

run-gate gate-node: check
	"$(SKYNET_ROOT)/skynet" config.gate_node

# `make run service-node` 只启动服务节点，避免先跑旧的 config/main
ifeq ($(filter service-node,$(MAKECMDGOALS)),service-node)
run: service-node
else ifeq ($(filter gate-node,$(MAKECMDGOALS)),gate-node)
run: gate-node
else
run: check
	"$(SKYNET_ROOT)/skynet" config
endif
