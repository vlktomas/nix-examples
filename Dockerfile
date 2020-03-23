FROM nixorg/nix:latest

# Get nixpkgs
RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
RUN nix-channel --update

# Alternatively mount nixpkgs
#RUN mkdir -p /nix/var/nix/profiles/per-user/root/channels/nixpkgs
# You can copy nixpkgs into image so you don't have to specify mount argument
#COPY $HOME/.nix-defexpr/channels/nixpkgs /nix/var/nix/profiles/per-user/root/channels/nixpkgs

RUN mkdir -p /mnt
# Similary you can copy project files
#COPY . /mnt/
WORKDIR /mnt/

