# Setting Up Remote Repository with Rclone on Ubuntu

### Introduction

Rclone is a command-line program to manage files on cloud storage. This guide will walk you through setting up Yandex Disk as an example.

### Prerequisites

- **Ubuntu** installed on your machine.
- **Yandex Disk** account. You can sign up at [Yandex Disk](https://disk.yandex.com/).

### Installation

#### Step 1: Install Rclone

First, install `rclone` by following these steps:

1. **Update the package list:**

   ```sh
   sudo apt update
   ```

2. **Install Rclone:**

   ```sh
   sudo apt install rclone
   ```

### Configuration

#### Option 1: Configure Rclone with GUI

1. **Start the Rclone configuration process:**

   ```sh
   rclone config
   ```

2. **Follow the prompts to set up Yandex Disk:**

    - **New remote:** Type `n` and press Enter.
    - **Name:** Give your remote a name, e.g., `yandex`.
    - **Storage:** Type `yandex` and press Enter.
    - **OAuth client ID:** Press Enter to skip.
    - **OAuth client secret:** Press Enter to skip.
    - **Edit advanced config:** Type `n` and press Enter.
    - **Use auto config:** Type `y` and press Enter.

3. **Authorize Rclone:**

    - A browser window will open, prompting you to log in to your Yandex account and authorize `rclone`.

4. **Finish the configuration:**

    - **Save configuration:** Type `y` and press Enter.
    - **Quit configuration:** Type `q` and press Enter.

#### Option 2: Configure Rclone without GUI (Using Windows)

1. **Install Rclone on Windows:**

   Download and install `rclone` from the [official website](https://rclone.org/downloads/).

2. **Configure Rclone on Windows:**

   Open a command prompt and run:

   ```sh
   rclone config
   ```

   Follow the same steps as in Option 1 to set up Yandex Disk.

3. **Locate the Rclone Config File on Windows:**

   The configuration file is located at:

   ```
   %APPDATA%\rclone\rclone.conf
   ```

4. **Copy the Config File to Your Unix System:**

   Transfer the `rclone.conf` file to your Unix system. You can use tools like `scp` or a USB drive. For example, using `scp`:

   ```sh
   scp %APPDATA%\rclone\rclone.conf username@unix_system:/home/username/.config/rclone/
   ```

5. **Place the Config File in the Correct Directory on Unix:**

   Ensure the configuration file is placed in the following directory on your Unix system:

   ```
   /home/username/.config/rclone/rclone.conf
   ```

### Basic Commands

#### List Files

To list files in your Yandex Disk remote, use:

```sh
rclone ls yandex:
```

#### Upload Files

To upload files to your Yandex Disk remote, use:

```sh
rclone copy /path/to/local/file yandex:/path/on/yandex/disk
```

#### Download Files

To download files from your Yandex Disk remote, use:

```sh
rclone copy yandex:/path/on/yandex/disk /path/to/local/destination
```

### Example Usage

#### Uploading a File

```sh
rclone copy /home/user/Documents/example.txt yandex:/Backups/Documents
```

#### Downloading a File

```sh
rclone copy yandex:/Backups/Documents/example.txt /home/user/Downloads
```

### Additional Resources

- [Rclone Documentation](https://rclone.org/docs/)
