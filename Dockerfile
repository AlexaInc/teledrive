FROM node:18.16.0 as build
# We use fixed placeholders that entrypoint.sh will replace
ENV REACT_APP_TG_API_ID=999123456789
ENV REACT_APP_TG_API_HASH=REPLACE_ME_API_HASH_PLACEHOLDER

RUN apt-get update && apt-get install -y git

WORKDIR /apps
RUN git clone https://github.com/AlexaInc/teledrive.git .

RUN yarn install --network-timeout 1000000
RUN yarn workspaces run build

FROM node:18.16.0-slim
WORKDIR /apps
# This copies everything from the build stage, including entrypoint.sh and build artifacts
COPY --from=build /apps .

# Runtime environment variables
ENV PORT=7860
EXPOSE 7860

RUN chmod +x /apps/entrypoint.sh

ENTRYPOINT ["/apps/entrypoint.sh"]
