#! /usr/bin/env nix-shell
#! nix-shell -i bash -E "with (import ./nixpkgs.nix {}).pkgs; runCommand \"dummy\" { buildInputs = [ nix nixops ]; } \"\""

DEPLOYMENT_NAME="helloanswer"
NIX_PATH="nixpkgs=$(nix-instantiate -E '(import ./nixpkgs.nix {}).outPath' --eval | tr -d '"')"

# process arguments
if [ "$1" = "deploy-test" ]; then
    # deploy test with VirtualBox
    DEPLOYMENT_VBOX_NAME=${DEPLOYMENT_NAME}-vbox
    # delete deployment if exists
    nixops info -d ${DEPLOYMENT_VBOX_NAME} --no-eval --plain &> /dev/null
    if [ $? -eq 0 ]; then
        nixops destroy -d ${DEPLOYMENT_VBOX_NAME}
        nixops delete -d ${DEPLOYMENT_VBOX_NAME}
    fi
    nixops create ./cd-vbox.nix -d ${DEPLOYMENT_VBOX_NAME}
    nixops deploy -d ${DEPLOYMENT_VBOX_NAME} --force-reboot
    nixops ssh -d ${DEPLOYMENT_VBOX_NAME} server -- client-wrapped | grep "Hello World!"
    nixops destroy -d ${DEPLOYMENT_VBOX_NAME} --confirm
    nixops delete -d ${DEPLOYMENT_VBOX_NAME}
    exit 0
fi

# run CI pipeline
nix-build ci.nix -A pipelineJob --max-jobs auto

# deploy
# check if deployment exists
nixops info -d ${DEPLOYMENT_NAME} --no-eval --plain &> /dev/null
if [ $? -ne 0 ]; then
    nixops create ./cd-nixos.nix -d ${DEPLOYMENT_NAME}
fi
nixops deploy -d ${DEPLOYMENT_NAME}
