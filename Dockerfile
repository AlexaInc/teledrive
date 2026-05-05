FROM node:18.16.0 as build
ARG REACT_APP_TG_API_ID
ARG REACT_APP_TG_API_HASH

WORKDIR /apps

COPY yarn.lock .
COPY package.json .
COPY api/package.json api/package.json
COPY web/package.json web/package.json
RUN yarn install --network-timeout 1000000
COPY . .
# The React build will use the ARGs above
RUN yarn workspaces run build

FROM node:18.16.0-slim
WORKDIR /apps
COPY --from=build /apps .

# Runtime environment variables for the API server
ENV PORT=7860
EXPOSE 7860

CMD ["yarn", "start"]
