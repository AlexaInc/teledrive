FROM node:18.16.0 as build
# We use fixed placeholders that entrypoint.sh will replace
ENV REACT_APP_TG_API_ID=999123456789
ENV REACT_APP_TG_API_HASH=REPLACE_ME_API_HASH_PLACEHOLDER

WORKDIR /apps

# Copy only package files first for better caching
COPY yarn.lock .
COPY package.json .
COPY api/package.json api/package.json
COPY web/package.json web/package.json

RUN yarn install --network-timeout 1000000

# Copy the rest of the files (including entrypoint.sh)
COPY . .

RUN yarn workspaces run build

FROM node:18.16.0-slim
WORKDIR /apps
# Copy only necessary files from build stage
COPY --from=build /apps .

# Runtime environment variables
ENV PORT=7860
EXPOSE 7860

RUN chmod +x /apps/entrypoint.sh

ENTRYPOINT ["/apps/entrypoint.sh"]
