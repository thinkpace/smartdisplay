# Smartdisplay

Smartdisplay is a personal DIY project aimed at creating a smart display that showcases pictures from a network storage. The project consists of a server component, which provides an endpoint to serve pictures, and a client component, which displays these pictures on a screen.

# Overview

It consists of two main components: the Python server and the Godot-based client.

## Python Server

The server component is responsible for serving pictures from a network storage. It provides an endpoint that the client can use to fetch the pictures. The server is built using Python and can be set up using Ansible scripts provided in the repository.

## Godot Client

The Godot client is a graphical application that displays the pictures fetched from the server. It is built using the Godot game engine and includes various scenes and scripts to manage slide transitions, animations, and user input. The client can be configured to connect to the server and display the pictures on a screen.

In my personal setup, client is running on a Raspberry Pi connected to a touchscreen.

# Drawbacks

Please note there is no kind of authentication implemented in Python Server, furtermore it's running with Flask internal Development Server without using an external Application Server. Ensure to only run this in a secure environment.

# Assets

Due to licensing issues, I didn't add any assets to the repository. Most of used assets are created by [LimeZu](https://limezu.itch.io/).

# Requirements

To run this project, you will need the following:

## Server

* Python 3
* Ansible
* A bunch of picture to show

## Client (build)

* Godot Engine 4.3 or higher

## Client (run)

* A device to run the client (e.g. Raspberry Pi with a touchscreen)

# Setup

## On your Workstation

1. Clone this repository and cd into it.

2. Add server or group with name `smartdisplay_server` for target server and `smartdisplay_godot_client` for target client.

### Building the Godot Client

1. Open the project in the Godot editor.

2. Go to `Project` -> `Export...`.

3. Configure the export settings for your target platform (e.g., Linux, Windows, etc.).

4. Click on `Add...` to create a new export preset.

5. Set the necessary options for the export preset, such as the output path and executable name. Output path must be `ansible/roles/install-godot-client/files/smartdisplay.arm32` to export the binary to the correct folder.

6. Click on `Export Project` to build the client.

### Run Ansible

1. Edit `ansible/roles/install-server/vars/main.yml` and adapt `smartdisplay_client_path` if you would like to change installation directory.

2. Copy and edit the sample configuration files:
    ```sh
    cp ansible/roles/install-server/vars/main_sample.yml ansible/roles/install-server/vars/main.yml
    cp ansible/roles/install-server/files/picture_paths_sample.txt ansible/roles/install-server/files/picture_paths.txt
    ```

3. Edit `main.yml` and `picture_paths.txt` to match your setup.

4. Run the Ansible playbook to set up the server and client:
    ```sh
    ansible-playbook -i /path/to/your/ansible/inventory ansible/ansible_playbook.yml
    ```

## On your Server

1. cd into your installation directory.

2. Create a virtual environment:
    ```sh
    python3 -m venv .venv
    ```

3. Activate the virtual environment:
    ```sh
    source .venv/bin/activate
    ```

4. Install the required Python packages:
    ```sh
    pip3 install -r requirements.txt
    ```

5. Start the server:
    ```sh
    python3 server.py
    ```

## Running the Client

1. Run the binary (default: /usr/local/bin/smartdisplay.arm32) once and close it again using <kbd>ESC</kbd>.

2. This will create default config file in Godot app userdata directory. See [Godot docs](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html) for details, in my case it's located at
    ```
    ~/.local/share/godot/app_userdata/smartdisplay-godot-client/smartdisplay.cfg
    ```

3. Open `smartdisplay.cfg` and update `picture_provider_url` in section `[Smartdisplay]`.

4. That's it! Run the application and enjoy your pictures.

# Old versions

* [archive/version2](archive/version2): This version is basically just a python script which provides an endpoint to provide pictures and an HTML file which is using this endpoint to show pictures.
* [archive/version1](archive/version1): This version is using quite a lot of technologie to implement such a simple thing like a smart display. I'm not using it anymore, but it was fun to create it and learn all those things.
* There were earlier versions available but those have never been published.
