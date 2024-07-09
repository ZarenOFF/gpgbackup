
# GPG Backup Script

This script creates encrypted backups of specified directories or files with `gpg`, uploads them to a remote server using `rclone`, and manages the number of backups by deleting the oldest ones if a specified limit is exceeded.

## Preparation

First of all you need to configure `gpg` and `rclone` to use this script. You can find guides **[here](https://github.com/ZarenOFF/gpgbackup/tree/master/docs)**.

After this you need to clone this repository and add execute permission to the script
```bash
git clone https://github.com/ZarenOFF/gpgbackup.git
cd gpgbackup
chmod +x gpgbackup.sh
```

## Usage

### Command Line Arguments

```bash
./gpgbackup.sh [-o <another_directory_or_file_to_backup> -o ...] -r <gpg_recipient> -n <backup_name> -p <remote_path> -m <backups_count> -i <rclone_id> -d <backup_destination>
```

### Using Configuration File

```bash
./gpgbackup.sh -c <config_path>
```

### Parameters

- `-o <directory_or_file_to_backup>`: Specify directories or files to backup. Multiple sources can be specified by repeating the `-o` option.
- `-r <gpg_recipient>`: GPG recipient (email or key) for encryption.
- `-n <backup_name>`: Name of the backup.
- `-p <remote_path>`: Remote path for storing backups.
- `-m <backups_count>`: Maximum number of backups to keep on the remote server.
- `-i <rclone_id>`: `rclone` ID for copying the backups.
- `-c <backup_path>`: Path to the configuration file.

## Configuration File

The configuration file should be a shell script that sets the following variables:

```bash
# Configuration file example

# Path for temporary storage of backup on the server
BACKUP_DEST="/path/temp_backups/"

# GPG recipient (email or key)
GPG_RECIPIENT="your_recipient@example.com"

# `rclone` ID for copying
RCLONE_ID="your_rclone_id"

# Remote path for storing backups
REMOTE_PATH="/path_to_your_backups/"

# Folders and files to backup
BACKUP_SOURCES=("/path/folder1" "/path/folder2")

# Maximum number of backups to keep on the remote server
MAX_BACKUPS=14
```

## Script Details

### Workflow

1. **Process Arguments**: The script processes command line arguments to set variables or load a configuration file.
2. **Check Required Variables**: Ensures all required variables are set.
3. **Create Archive**: Creates a compressed archive of the specified directories or files.
4. **Encrypt Archive**: Encrypts the archive using GPG.
5. **Upload Archive**: Uploads the encrypted archive to the remote server using `rclone`.
6. **Clean Up**: Removes temporary files.
7. **List Remote Files**: Lists files in the remote directory.
8. **Manage Backups**: Deletes the oldest backup if the number of backups exceeds the specified limit.

### Example

```bash
./gpgbackup.sh -o /path/to/dir1 -o /path/to/dir2 -r recipient@example.com -n my_backup -p /remote/backup/path -m 7 -i my_rclone_id  -d /backups
```

This command will:
- Backup `/path/to/dir1` and `/path/to/dir2`
- Encrypt the backup for `recipient@example.com`
- Name the backup `my_backup`
- Store the backup in `/remote/backup/path` on the remote server
- Keep a maximum of 7 backups on the remote server
- Use `my_rclone_id` for `rclone` operations
- Use `/backups` folder for creating archives

## Logging

All logs are written to `/var/log/gpgbackup.log`. The log includes timestamps and the status of each operation.

## Error Handling

If any required parameter is missing, the script will log an error message and display the usage instructions.

## License

This script is provided "as is", without warranty of any kind. Use at your own risk.
