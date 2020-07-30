FROM ubuntu
RUN mkdir -p /root/auraOctavePaciente
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y octave octave-statistics
WORKDIR /root/auraOctavePaciente
COPY . .
CMD [ "octave", "analyzer.sh" ]