# Makefile

IMAGE_NAME := atricore/josso-pxy:latest
IMAGE_GZ := result

all: build load run

build:
# Build docker image
	nix build .#nginx # Build the nginx flake

load: build
# Delete any containers using the specified image
	-docker ps -a --filter ancestor=$(IMAGE_NAME) --format="{{.ID}}" | xargs -r docker rm -f
	# Delete the specified image if it exists
	-docker rmi $(IMAGE_NAME)
	gunzip -c $(IMAGE_GZ) | docker load # Load the tar.gz file into Docker

run: load
# Run the image, bind the network to the host to be able to reach JOSSO
	docker run --rm --name josso-pxy \
		-p 443:443 \
		--network host \
    	$(IMAGE_NAME)

clean:
	docker rm -f my-container || true # Remove the container
	rm -f result # Remove the tar.gz file
