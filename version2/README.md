# Smartdisplay

This is a private DIY project to create something like a smart display. In it's current implementation, it just shows pictures from a specified storage and you can load new pictures by click and go back to the last picture by click.

# How it's working?

There is a python script called sd_cp.py which is providing an endpoint to download pictures. An HTML file is using this endpoint to download and show a picture on a frequently basis.

# Security

Since this is all running in my local network, there is no security implemented in any way. Please keep this in mind if you want to implement it yourself!

# Dependencies

* Python 3 installed on a server which has access to your pictures (contentprovider).
* A device(s) which can run docker (webserver).
* Some pictures.

# Install

* Adapt [sd_cp.py](contentprovider/sd_cp.py) by changing listed folder paths.
* Execute docker-compose with [docker-compose.yaml](webserver/docker-compose.yaml).
