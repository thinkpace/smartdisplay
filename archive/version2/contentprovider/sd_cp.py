from flask import Flask, send_file, send_from_directory, redirect, url_for, request, Response, jsonify
from flask_cors import CORS
import base64
import pathlib
import random

app = Flask(__name__)
CORS(app)

picture_dir_list = []
picture_list = []

@app.route('/random_picture')
def data_collector():
    picture_path = get_random_picture_from_list(picture_list)
    with open(picture_path, 'rb') as binary_file:
        binary_file_data = binary_file.read()
        base64_encoded_data = base64.b64encode(binary_file_data)
        base64_message = base64_encoded_data.decode('utf-8')
    return jsonify({ 'filename': picture_path.name, 'path': str(picture_path.absolute()),  'extension': picture_path.suffix, 'content_base64': base64_message })

def initialize():
    print("Add picture paths to list ...")
    picture_dir_list.append('/path/to/pictures/folder1')
    picture_dir_list.append('/path/to/pictures/folder2')
    picture_dir_list.append('/path/to/pictures/folder3')
    picture_dir_list.append('/path/to/pictures/folder4')
    print('... done')

    print("Initialize picture_list ...")
    picture_list = get_picture_list()
    print("... initialized!")

def get_picture_list():
    for picture_dir in picture_dir_list:
        print("Glob " + picture_dir + " *.jpg ...")
        picture_list.extend(pathlib.Path(picture_dir).glob('**/*.jpg'))
        print("Glob " + picture_dir + " *.JPG ...")
        picture_list.extend(pathlib.Path(picture_dir).glob('**/*.JPG'))
        print("Finished glob")

    return picture_list

def get_random_picture_from_list(list):
    while True:
        picture = pathlib.Path(random.choice(list))
        if '@' not in picture.as_posix():
            break
    return picture

if __name__ == "__main__":
    initialize()
    app.run(host="0.0.0.0", port="4999", debug=False)
