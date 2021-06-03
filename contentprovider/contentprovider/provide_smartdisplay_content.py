#!/usr/bin/env python

import pika
import json
import base64
import time
import pathlib
import random
import sys
import redis

r = redis.Redis(host='redis.home.familiebaus.de', port=6379)

hostname = r.get('smartdisplay:mq-hostname').decode()
print("MQ-Host: " + hostname)
queue_name = r.get('smartdisplay:mq-queuename').decode()
print("MQ-Queuename: " + queue_name)
sleep_time = int(r.get('smartdisplay:time-between-pictures').decode())
print("Sleep time: " + str(sleep_time))
sleep_time_nfs = int(r.get('smartdisplay:time-wait-for-nfs').decode())
print("Sleep time NFS: " + str(sleep_time_nfs))

print("Used picture paths:")
picture_dir_list = []
for i in range(0, r.llen('smartdisplay:picture-dir-list')):
    picture_dir = r.lindex('smartdisplay:picture-dir-list', i).decode()
    print(picture_dir)
    picture_dir_list.append(picture_dir)

print("Starting, wait for NFS mounts ...")
time.sleep(sleep_time_nfs)
print("... done")

def get_picture_list():
    picture_list = []

    for picture_dir in picture_dir_list:
        print("Glob " + picture_dir + " *.jpg ...")
        picture_list.extend(pathlib.Path(picture_dir).glob('**/*.jpg'))
        print("Glob " + picture_dir + " *.JPG ...")
        picture_list.extend(pathlib.Path(picture_dir).glob('**/*.JPG'))
        print("Finished glob")

    for picture_dir in picture_list:
        print("Check " + picture_dir.as_posix())
        if '@' in picture_dir.as_posix():
            print("Remove " + picture_dir.as_posix())
            picture_list.remove(picture_dir)

    return picture_list

def get_random_picture_from_list(list):
    while True:
        picture = pathlib.Path(random.choice(list))
        if '@' not in picture.as_posix():
            break
    return picture

def create_message(picture):
    with open(picture, 'rb') as binary_file:
        binary_file_data = binary_file.read()
        base64_encoded_data = base64.b64encode(binary_file_data)
        base64_message = base64_encoded_data.decode('utf-8')
    return { 'filename': picture.name, 'path': str(picture.absolute()),  'extension': picture.suffix, 'content_base64': base64_message }

print("Initialize picture_list ...")
picture_list = get_picture_list()
print("... initialized!")

while True:
    mq_conn = pika.BlockingConnection(pika.ConnectionParameters(host=hostname))
    channel = mq_conn.channel()
    queue = channel.queue_declare(queue=queue_name)

    if queue.method.message_count == 0:
        print("Push content to queue ...")
        picture_path = get_random_picture_from_list(picture_list)
        message = create_message(picture_path)
        channel.basic_publish(exchange='', routing_key=queue_name, body=json.dumps(message))
        print("... done")

    mq_conn.close()
    print("Sleep " + str(sleep_time) + " seconds ...")
    time.sleep(sleep_time)

