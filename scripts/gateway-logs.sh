#!/usr/bin/env sh

sudo docker compose logs gateway --follow $@
