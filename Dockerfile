FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7-stable
ARG GODOT_SHA256=0b1a6c54c2c619c12e169fe9241edda4b81080b519451cec2984bf0d2c6cb73c
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip libstdc++6 libfontconfig1 libasound2 \
    && curl --fail --location --retry 3 --max-time 120 \
      "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" -o /tmp/godot.zip \
    && echo "${GODOT_SHA256}  /tmp/godot.zip" | sha256sum --check --strict \
    && unzip -q /tmp/godot.zip -d /tmp \
    && mv "/tmp/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot \
    && chmod 755 /usr/local/bin/godot \
    && rm -f /tmp/godot.zip \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 vcommander

WORKDIR /app
COPY project.godot export_presets.cfg ./
COPY scripts/ scripts/
COPY scenes/ scenes/
COPY data/ data/
COPY assets/ assets/
COPY tools/run_private_server.gd tools/run_private_server.gd
RUN godot --headless --path . --editor --quit > /tmp/godot-import.log 2>&1 \
    && cat /tmp/godot-import.log \
    && ! grep -E 'SCRIPT ERROR:|ERROR:' /tmp/godot-import.log \
    && rm /tmp/godot-import.log

USER vcommander
ENV PORT=10000
ENV PVP_MAX_ROOMS=1
EXPOSE 10000
CMD ["godot", "--headless", "--path", ".", "--script", "tools/run_private_server.gd", "--", "--listen=0.0.0.0"]
