#!/usr/bin/env python

import pika, sys, os
import json
import base64
import redis

r = redis.Redis(host='redis.home.familiebaus.de', port=6379)

hostname = r.get('smartdisplay:mq-hostname').decode()
queue_name = r.get('smartdisplay:mq-queuename').decode()
output_path = "/data/picture.jpg"

def main():
    channel = mq_conn.channel()
    channel.queue_declare(queue=queue_name)
    channel.basic_consume(queue=queue_name, on_message_callback=handle_new_message, auto_ack=True)
    channel.start_consuming()

def handle_new_message(channel, method, properties, body):
    message = json.loads(body.decode())
    with open(output_path, 'wb') as picture:
        base64_img_bytes = message['content_base64'].encode('utf-8')
        picture.write(base64.decodebytes(base64_img_bytes))
        print('New picture "' + output_path + '" written')

mq_conn = pika.BlockingConnection(pika.ConnectionParameters(host=hostname))

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        try:
            mq_conn.close()
            sys.exit(0)
        except SystemExit:
            os._exit(0)

