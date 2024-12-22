from flask import Flask, send_file, send_from_directory, redirect, url_for, request, Response, jsonify
from flask_cors import CORS
from exif import Image
import base64
import pathlib
import random
import os

app = Flask(__name__)
CORS(app)

picture_dir_list = []
picture_list = []

# Exif Orientation Enum
# Source: https://exif.readthedocs.io/en/latest/api_reference.html?highlight=orientation#orientation
#
#BOTTOM_LEFT = 4
#
#    The 0th row is at the visual bottom of the image and the 0th column is the visual left-hand side.
#
#BOTTOM_RIGHT = 3
#
#    The 0th row is at the visual bottom of the image and the 0th column is the visual right-hand side.
#
#LEFT_BOTTOM = 8
#
#    The 0th row is the visual left-hand side of the image and the 0th column is the visual bottom.
#
#LEFT_TOP = 5
#
#    The 0th row is the visual left-hand side of the image and the 0th column is the visual top.
#
#RIGHT_BOTTOM = 7
#
#    The 0th row is the visual right-hand side of the image and the 0th column is the visual bottom.
#
#RIGHT_TOP = 6
#
#    The 0th row is the visual right-hand side of the image and the 0th column is the visual bottom.
#
#TOP_LEFT = 1
#
#    The 0th row is at the visual top of the image and the 0th column is the visual left-hand side.
#
#TOP_RIGHT = 2
#
#    The 0th row is at the visual top of the image and the 0th column is the visual right-hand side.

# FIXME check for exif existence
@app.route('/random_picture')
def data_collector():
    picture_path = get_random_picture_from_list(picture_list)
    with open(picture_path, 'rb') as binary_file:
        binary_file_data = binary_file.read()
        base64_encoded_data = base64.b64encode(binary_file_data)
        base64_message = base64_encoded_data.decode('utf-8')
    with open(picture_path, 'rb') as image_file:
        exif_image = Image(image_file)
    return jsonify({'filename': picture_path.name,
                    'path': str(picture_path.absolute()),
                    'extension': picture_path.suffix,
                    'content_base64': base64_message,
                    'exif_has_exif': exif_image.has_exif,
                    'exif_orientation': exif_image.get("orientation"),
                    'exif_make': exif_image.get("make"),
                    'exif_model': exif_image.get("model"),
                    'exif_datetime_original': exif_image.get("datetime_original"),
                   })

def initialize():
    print("Current working directory:", os.getcwd())
    picture_paths_file = os.path.join(os.getcwd(), 'picture_paths.txt')
    
    print("Add picture paths to list ...")
    with open(picture_paths_file, 'r') as file:
        for line in file:
            path = line.strip()
            if path:  # Check if the line is not empty
                picture_dir_list.append(path)
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
