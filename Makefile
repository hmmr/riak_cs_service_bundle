.PHONY: ensure-dirs build up down clean

RIAK_VSN       	    ?= 3.0.7
RIAK_CS_VSN    	    ?= 3.0.0pre8
STANCHION_VSN  	    ?= 3.0.0pre8
RIAK_CS_CONTROL_VSN ?= 3.0.0pre3

RIAK_PLATFORM_DIR      ?= $(shell pwd)/p/riak

N_RIAK_NODES     ?= 3
N_RCS_NODES      ?= 2
RCS_AUTH_V4      ?= on

DOCKER_SERVICE_NAME ?= rcs-tussle-one

build:
	@COMPOSE_FILE=docker-compose-scalable-build.yml \
	docker-compose build \
	    --build-arg RIAK_VSN=$(RIAK_VSN) \
	    --build-arg RIAK_CS_VSN=$(RIAK_CS_VSN) \
	    --build-arg STANCHION_VSN=$(STANCHION_VSN) \
	    --build-arg RIAK_CS_CONTROL_VSN=$(RIAK_CS_CONTROL_VSN)

up: build ensure-dirs
	@docker swarm init >/dev/null || :
	@COMPOSE_FILE=docker-compose-scalable-run.yml \
	 N_RIAK_NODES=$(N_RIAK_NODES) \
	 N_RCS_NODES=$(N_RCS_NODES) \
	 RIAK_PLATFORM_DIR=$(RIAK_PLATFORM_DIR) \
	    docker stack deploy -c docker-compose-scalable-run.yml $(DOCKER_SERVICE_NAME) \
	 && ./stage-two.py \
		$(DOCKER_SERVICE_NAME) \
		$(N_RIAK_NODES) \
		$(N_RCS_NODES) \
		$(RCS_AUTH_V4)

down:
	@COMPOSE_FILE=docker-compose-scalable-run.yml \
	    docker stack rm $(DOCKER_SERVICE_NAME)

ensure-dirs:
	@mkdir -p $(RIAK_PLATFORM_DIR){/data,/log}

clean:
	@sudo rm -rf $(RIAK_PLATFORM_DIR)