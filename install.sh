#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Example install script — served so it can be run with:
#   curl -fsSL https://example.com/install.sh | bash
# ---------------------------------------------------------------------------

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}==> Starting installation...${NC}"

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"
echo -e "${BLUE}==> Detected: ${OS} (${ARCH})${NC}"

echo -e "${BLUE}==> System info:${NC}"
echo "  user:     $(whoami)"
echo "  cwd:      $(pwd)"
echo "  home:     ${HOME:-unknown}"
echo "  hostname: $(hostname)"
echo "  shell:    ${SHELL:-unknown}"
echo "  date:     $(date)"
echo "  kernel:   $(uname -r)"

# Do your setup work here
echo -e "${GREEN}==> All done! 🎉${NC}"