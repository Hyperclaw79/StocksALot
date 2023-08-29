# Build stage
FROM node:alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Production stage
FROM node:alpine AS production

WORKDIR /app

COPY --from=build /app .

ENV HOST=0.0.0.0
EXPOSE 4173

CMD ["npm", "run", "preview","--", "--host", "0.0.0.0"]
