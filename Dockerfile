# from https://v2.vuejs.org/v2/cookbook/dockerize-vuejs-app

# the app doesn't work on newer :(
FROM node:16-slim

RUN npm install -g http-server

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

EXPOSE 8080
CMD [ "http-server", "dist" ]
