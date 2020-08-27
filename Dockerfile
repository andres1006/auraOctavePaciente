FROM node:14.7
RUN mkdir -p /root/auraOctavePaciente
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y octave octave-statistics
WORKDIR /root/auraOctavePaciente
COPY package.json .
RUN npm install
COPY . .
EXPOSE 15000
CMD [ "npm", "start" ]