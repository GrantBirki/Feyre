# Multi-stage docker buld

FROM python:3.9.4-slim as build

WORKDIR /wheels

# pyodbc install and drivers
RUN apt update && apt install curl -y && apt install gnupg -y
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt update && ACCEPT_EULA=Y apt install msodbcsql17 -y
RUN apt install gcc -y && apt install g++ -y
RUN apt -y install unixodbc-dev

COPY requirements.txt /opt/feyre/requirements.txt
RUN pip3 wheel -r /opt/feyre/requirements.txt
# End of build stage

# -----------------------------------------------------------------------

# Main docker image to be built
FROM python:3.9.4-slim

# pyodbc install and drivers
RUN apt update && apt install curl gnupg nano -y
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt update && ACCEPT_EULA=Y apt install msodbcsql17 -y
RUN apt install gcc -y && apt install g++ -y
RUN apt -y install unixodbc-dev

# testing - ping command and redis if you want to use redis
# RUN apt install iputils-ping redis -y

# create nonroot user
RUN adduser nonroot
RUN mkdir /home/app/ && chown -R nonroot:nonroot /home/app
WORKDIR /home/app

COPY --from=build /wheels /wheels
COPY --chown=nonroot:nonroot requirements.txt /home/app/
RUN pip3 install -r requirements.txt -f /wheels \
  && rm -rf /wheels \
  && rm -rf /root/.cache/pip/* \
  && rm requirements.txt

USER nonroot

# Feyre.py
COPY --chown=nonroot:nonroot . .

ENTRYPOINT [ "python" ]
