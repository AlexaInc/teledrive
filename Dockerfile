FROM node:18-bullseye-slim as build
# We use fixed placeholders that entrypoint.sh will replace
ENV REACT_APP_TG_API_ID=999123456789
ENV REACT_APP_TG_API_HASH=REPLACE_ME_API_HASH_PLACEHOLDER

# Memory optimizations to prevent OOM
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV GENERATE_SOURCEMAP=false

# Install build deps for Debian
RUN apt-get update && apt-get install -y git python3 make g++ openssl

WORKDIR /apps
RUN git clone --depth 1 https://github.com/AlexaInc/teledrive.git .

RUN yarn install --network-timeout 1000000 --ignore-engines
RUN yarn workspaces run build

FROM node:18-bullseye-slim
WORKDIR /apps
COPY --from=build /apps .

# Runtime environment variables
ENV PORT=7860
EXPOSE 7860

RUN chmod +x /apps/entrypoint.sh

ENTRYPOINT ["/apps/entrypoint.sh"]
