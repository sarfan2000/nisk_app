FROM node:18-alpine

# Set the working directory directly inside the container
WORKDIR /usr/src/app

# Copy the dependency markers
COPY package*.json ./

# Install cleanly targeting production bounds
RUN npm install --production

# Move exactly the logic structure inward
COPY . .

# Expose backend REST port mapping
EXPOSE 5000

# Execute server boot
CMD ["node", "server.js"]
