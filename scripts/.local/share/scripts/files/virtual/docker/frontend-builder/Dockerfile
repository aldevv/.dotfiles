FROM node:16-bullseye-slim AS deps

WORKDIR /src
COPY package*.json ./
RUN npm install
COPY . .
RUN node_modules/@angular/cli/bin/ng build --prod

FROM scratch
COPY --from=deps /src/dist .
