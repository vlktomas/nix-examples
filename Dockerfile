FROM nixorg/nix:latest

# Get nixpkgs
RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
RUN nix-channel --update

# Alternatively mount nixpkgs
#RUN mkdir -p /nix/var/nix/profiles/per-user/root/channels/nixpkgs

RUN mkdir -p /mnt
# You can copy project files into image so you don't have to specify mount argument
#COPY . /mnt/
WORKDIR /mnt/

# Use like this:
#
#docker build -t nix/project:dev . -f Dockerfile
#
#docker run --rm \
#    --name pipeline-job \
#    --mount type=bind,source="$(pwd)",target=/mnt \
#    # only if nixpkgs are not in container
#    #--mount type=bind,source=$HOME/.nix-defexpr/channels/nixpkgs,target=/nix/var/nix/profiles/per-user/root/channels/nixpkgs \
#    -it nix/project:dev -- nix-build ci.nix -A pipelineJob
#
# Note that in Docker you cannot do NixOS test, because it needs kvm system feature

