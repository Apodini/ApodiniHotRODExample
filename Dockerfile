#
# This source file is part of the Apodini HotROD example open source project
#
# SPDX-FileCopyrightText: 2022 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
#
# SPDX-License-Identifier: MIT
#

# ================================
# Build image
# ================================
FROM swiftlang/swift:nightly-5.5-focal as build

# Build a specific service
ARG service

# Install OS updates
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# Copy all source files
COPY Package.swift Package.resolved ./
COPY Sources Sources

# Build everything, with optimizations
RUN swift build --product $service -c release

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build --product $service -c release --show-bin-path)/$service" ./service

# Copy resources from the resources directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d "$(swift build --package-path /build -c release --show-bin-path)/ApodiniHotRODExample_frontend.resources" ] \
    && mv "$(swift build --package-path /build -c release --show-bin-path)/ApodiniHotRODExample_frontend.resources" ./ \
    && chmod -R a-w ApodiniHotRODExample_frontend.resources \
    || echo No resources to copy

# ================================
# Run image
# ================================
FROM swiftlang/swift:nightly-5.5-focal-slim as run

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -r /var/lib/apt/lists/*

# Create a apodini user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app apodini

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=apodini:apodini /staging /app

# Ensure all further commands run as the apodini user
USER apodini:apodini

# Start the Apodini service when the image is run.
# The port can be adapted using the `--port` argument.
ENTRYPOINT ["./service"]
