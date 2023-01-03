test-all: test-linux test-swift

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.7 \
		bash -c 'apt-get update && apt-get -y install make && make test-swift'

test-swift:
	swift test \
		--parallel

format:
	swift format --in-place --recursive .

.PHONY: format test-all test-linux test-swift
