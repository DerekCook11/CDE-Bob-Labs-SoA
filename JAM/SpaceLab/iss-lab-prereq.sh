#!/usr/bin/env bash
#
# ModResorts Java Modernization Lab - RHEL Prerequisite Setup
#
# Purpose:
#   Prepare a mostly-vanilla Red Hat Enterprise Linux VM for the
#   IBM Bob ModResorts Java modernization workshop.
#
# What this script does:
#   - Verifies RHEL / dnf availability
#   - Installs common OS utilities when possible
#   - Ensures a Java 17 JDK is available
#   - Ensures Maven >= 3.8.6 (installs Maven 3.9.16 under ~/tools if needed)
#   - Adds Maven to ~/.bashrc for future sessions
#   - Checks Maven Central connectivity
#   - Checks that TCP port 9080 is currently free
#   - Prints a final PASS/WARN/FAIL summary
#
# What this script does NOT install:
#   - Docker / Podman
#   - Kubernetes / OpenShift
#   - Node.js / React
#   - Databases
#   - CI/CD tooling
#   - IBM Bob (expected to already be installed)
#
# Usage:
#   chmod +x modresorts-lab-prereq.sh
#   ./modresorts-lab-prereq.sh
#

set -uo pipefail

MAVEN_VERSION="3.9.16"
MAVEN_MIN_VERSION="3.8.6"
MAVEN_BASE="$HOME/tools"
MAVEN_HOME="$MAVEN_BASE/apache-maven-$MAVEN_VERSION"
MAVEN_TGZ="apache-maven-$MAVEN_VERSION-bin.tar.gz"
MAVEN_URL_PRIMARY="https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/$MAVEN_TGZ"
MAVEN_URL_ARCHIVE="https://archive.apache.org/dist/maven/maven-3/3.9.16/binaries/$MAVEN_TGZ"

PASS=0
WARN=0
FAIL=0

green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
blue='\033[0;34m'
reset='\033[0m'

pass() { echo -e "${green}[PASS]${reset} $*"; PASS=$((PASS+1)); }
warn() { echo -e "${yellow}[WARN]${reset} $*"; WARN=$((WARN+1)); }
fail() { echo -e "${red}[FAIL]${reset} $*"; FAIL=$((FAIL+1)); }
info() { echo -e "${blue}[INFO]${reset} $*"; }

version_ge() {
  # Returns success when version $1 >= version $2
  [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have_cmd sudo; then
    sudo "$@"
  else
    return 127
  fi
}

echo
echo "=============================================================="
echo " ModResorts Java Modernization Lab - Prerequisite Setup"
echo "=============================================================="
echo

# ------------------------------------------------------------
# 1. OS / package manager
# ------------------------------------------------------------
info "Checking operating system..."

if [ -r /etc/os-release ]; then
  . /etc/os-release
  echo "Detected OS: ${PRETTY_NAME:-unknown}"
else
  warn "Could not read /etc/os-release."
fi

if have_cmd dnf; then
  pass "dnf package manager is available."
else
  fail "dnf was not found. This script is intended for RHEL-family systems."
fi

# ------------------------------------------------------------
# 2. Required OS packages
# ------------------------------------------------------------
echo
info "Checking required OS utilities..."

REQUIRED_PACKAGES=(
  "java-17-openjdk-devel"
  "curl"
  "unzip"
  "git"
  "tar"
  "gzip"
  "which"
  "iproute"
)

MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
  if rpm -q "$pkg" >/dev/null 2>&1; then
    pass "$pkg is installed."
  else
    MISSING_PACKAGES+=("$pkg")
  fi
done

if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then
  echo
  info "Missing packages: ${MISSING_PACKAGES[*]}"
  info "Attempting to install them with dnf..."

  if run_privileged dnf install -y "${MISSING_PACKAGES[@]}"; then
    pass "Required OS packages installed."
  else
    warn "Could not install all OS packages automatically."
    echo "       Ask the VM administrator to run:"
    echo "       sudo dnf install -y ${MISSING_PACKAGES[*]}"
  fi
fi

# ------------------------------------------------------------
# 3. Java 17 JDK
# ------------------------------------------------------------
echo
info "Checking Java 17 JDK..."

if have_cmd java; then
  JAVA_VERSION_OUTPUT="$(java -version 2>&1 | head -n1)"
  echo "java:  $JAVA_VERSION_OUTPUT"
else
  fail "java command not found."
fi

if have_cmd javac; then
  JAVAC_VERSION="$(javac -version 2>&1 | awk '{print $2}')"
  echo "javac: $JAVAC_VERSION"

  JAVA_MAJOR="${JAVAC_VERSION%%.*}"
  if [ "$JAVA_MAJOR" = "17" ]; then
    pass "Java 17 JDK is available."
  else
    warn "javac is version $JAVAC_VERSION; this lab is standardized on Java 17."
    echo "       java-17-openjdk-devel should be installed and selected."
  fi
else
  fail "javac not found. A JDK is required, not just a JRE."
fi

# ------------------------------------------------------------
# 4. Maven
# ------------------------------------------------------------
echo
info "Checking Maven..."

CURRENT_MAVEN_VERSION=""

if have_cmd mvn; then
  CURRENT_MAVEN_VERSION="$(mvn -version 2>/dev/null | awk '/Apache Maven/ {print $3; exit}')"
  if [ -n "$CURRENT_MAVEN_VERSION" ]; then
    echo "Current Maven: $CURRENT_MAVEN_VERSION"
  fi
fi

NEED_MAVEN_INSTALL=1
if [ -n "$CURRENT_MAVEN_VERSION" ] && version_ge "$CURRENT_MAVEN_VERSION" "$MAVEN_MIN_VERSION"; then
  pass "Maven $CURRENT_MAVEN_VERSION meets the minimum requirement ($MAVEN_MIN_VERSION)."
  NEED_MAVEN_INSTALL=0
else
  if [ -n "$CURRENT_MAVEN_VERSION" ]; then
    warn "Maven $CURRENT_MAVEN_VERSION is below the required minimum $MAVEN_MIN_VERSION."
  else
    warn "Maven was not found."
  fi
fi

if [ "$NEED_MAVEN_INSTALL" -eq 1 ]; then
  if ! have_cmd curl || ! have_cmd tar; then
    fail "curl and tar are required to install Maven $MAVEN_VERSION."
  else
    info "Installing Maven $MAVEN_VERSION under $MAVEN_HOME ..."
    mkdir -p "$MAVEN_BASE"

    TMP_DIR="$(mktemp -d)"
    MAVEN_ARCHIVE_PATH="$TMP_DIR/$MAVEN_TGZ"

    if curl -fL --retry 2 --connect-timeout 10 "$MAVEN_URL_PRIMARY" -o "$MAVEN_ARCHIVE_PATH"; then
      pass "Downloaded Maven $MAVEN_VERSION from Apache CDN."
    else
      warn "Primary Apache Maven download failed; trying Apache archive..."
      if curl -fL --retry 2 --connect-timeout 10 "$MAVEN_URL_ARCHIVE" -o "$MAVEN_ARCHIVE_PATH"; then
        pass "Downloaded Maven $MAVEN_VERSION from Apache archive."
      else
        fail "Could not download Maven $MAVEN_VERSION."
        rm -rf "$TMP_DIR"
        MAVEN_ARCHIVE_PATH=""
      fi
    fi

    if [ -n "${MAVEN_ARCHIVE_PATH:-}" ] && [ -f "$MAVEN_ARCHIVE_PATH" ]; then
      rm -rf "$MAVEN_HOME"
      tar -xzf "$MAVEN_ARCHIVE_PATH" -C "$MAVEN_BASE"

      if [ -x "$MAVEN_HOME/bin/mvn" ]; then
        export MAVEN_HOME
        export PATH="$MAVEN_HOME/bin:$PATH"
        pass "Maven $MAVEN_VERSION installed under $MAVEN_HOME."

        # Persist Maven for future interactive shells.
        BASHRC="$HOME/.bashrc"
        BEGIN_MARKER="# >>> ModResorts Lab Maven >>>"
        END_MARKER="# <<< ModResorts Lab Maven <<<"

        if [ -f "$BASHRC" ]; then
          # Remove prior block created by this script.
          sed -i "/$BEGIN_MARKER/,/$END_MARKER/d" "$BASHRC"
        else
          touch "$BASHRC"
        fi

        cat >> "$BASHRC" <<EOF

$BEGIN_MARKER
export MAVEN_HOME="$MAVEN_HOME"
export PATH="\$MAVEN_HOME/bin:\$PATH"
$END_MARKER
EOF
        pass "Maven environment added to $BASHRC."
      else
        fail "Maven extraction completed, but mvn executable was not found."
      fi
    fi

    rm -rf "$TMP_DIR"
  fi
fi

if have_cmd mvn; then
  echo
  mvn -version | sed 's/^/  /'
fi

# ------------------------------------------------------------
# 5. Maven Central / outbound HTTPS
# ------------------------------------------------------------
echo
info "Checking outbound HTTPS access to Maven Central..."

if have_cmd curl && curl -fsI --connect-timeout 10 https://repo.maven.apache.org/maven2/ >/dev/null; then
  pass "Maven Central is reachable."
else
  fail "Maven Central is not reachable."
  echo "       Maven, JUnit, Mockito, JaCoCo, Spring Test, and Liberty plugin"
  echo "       dependencies may not download during the lab."
fi

# ------------------------------------------------------------
# 6. Port 9080
# ------------------------------------------------------------
echo
info "Checking Liberty HTTP port 9080..."

if have_cmd ss; then
  if ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq '(^|:|\])9080$'; then
    warn "TCP port 9080 is already in use."
    ss -ltn 2>/dev/null | grep ':9080' || true
  else
    pass "TCP port 9080 is currently available."
  fi
else
  warn "ss command is unavailable; could not check port 9080."
fi

# ------------------------------------------------------------
# 7. Disk space
# ------------------------------------------------------------
echo
info "Checking disk space..."

AVAILABLE_MB="$(df -Pm "$HOME" | awk 'NR==2 {print $4}')"
if [ -n "${AVAILABLE_MB:-}" ] && [ "$AVAILABLE_MB" -ge 2048 ]; then
  pass "At least 2 GB of free disk space is available in the home filesystem."
else
  warn "Less than 2 GB may be available. Maven/Liberty downloads need free space."
fi

# ------------------------------------------------------------
# 8. Bob check (best effort)
# ------------------------------------------------------------
echo
info "Checking IBM Bob command availability (best effort)..."

if have_cmd bob; then
  pass "A 'bob' command is available on PATH."
else
  warn "No 'bob' CLI command was found. This is OK if Bob is accessed through its IDE/UI."
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------
echo
echo "=============================================================="
echo " Prerequisite Summary"
echo "=============================================================="
echo -e " PASS: ${green}$PASS${reset}"
echo -e " WARN: ${yellow}$WARN${reset}"
echo -e " FAIL: ${red}$FAIL${reset}"
echo

echo "Lab baseline:"
echo "  - Java 17 JDK"
echo "  - Maven >= $MAVEN_MIN_VERSION (recommended $MAVEN_VERSION)"
echo "  - curl, unzip, git, tar, gzip"
echo "  - outbound HTTPS to Maven Central"
echo "  - TCP port 9080 available"
echo "  - IBM Bob already installed / accessible"
echo

if [ "$FAIL" -eq 0 ]; then
  echo -e "${green}READY:${reset} No blocking prerequisite failures were detected."
  echo
  echo "For future shells, either open a new terminal or run:"
  echo "  source ~/.bashrc"
  exit 0
else
  echo -e "${red}NOT READY:${reset} Resolve the FAIL items above before the workshop."
  exit 1
fi
