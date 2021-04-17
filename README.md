# Smartdisplay

This is a private DIY project to create something like a smart Display. In it's current implementation, it just shows pictures from a specified storage. Earlier implementations had more features which are not maintained anymore.

This project targets specifically following topics:

* Show pictures (located on a NAS) on a display (quite obvious ...).
* Play with and learn about technologies. This is very important especially about technical decission which have been made.

# How it's working?

Following picture gives a rough overview about how it's working:

![Overview](/overview.png)

Pictures are stored on some kind of storage. A docker container named "contentprovider" pulls randomly pictures from this storages. It's currently not specified how this access is working, in my scenario I have a NAS and a Raspberry Pi which runs docker and has a NFS connection to this NAS. This contentprovider reads it's configuration from a existing Redis instance in my local network (not included in this project), pulls a picture and pushes it to an existing MQ (also not included in this project).

A docker container named "pull_content" (which also gets it's configuration from the Redis instance) is listening to the specified MQ channel and writes new pictures to a docker volume. This volume is shared with a Nginx instance which is providing this picture to whoever is calling.

# Security

Since this is all running in my local network, there is no security implemented in any way. Please keep this in mind if you want to implement it yourself!

