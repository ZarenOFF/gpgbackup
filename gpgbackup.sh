#!/bin/bash

# Usage - ./gpgbackup.sh -o /path/to/dir1 -o /path/to/file2 -o /path/to/dir3 -r recipient@example.com

# Параметры
BACKUP_DEST="/backup/systembackup/"  # Путь для временного хранения бэкапа на сервере
GPG_RECIPIENT="put_your_recipient"  # Получатель GPG (email или ключ)
RCLONE_ID="rcloneid"


usage() {
  echo "Usage: $0 -o <directory_or_file_to_backup> [-o <another_directory_or_file_to_backup> ...] -r <gpg_recipient>"
  exit 1
}

BACKUP_SOURCES=()
REMOTE_PATH="/path_to_your_backups/"
BACKUP_NAME=""

while getopts "o:r:n:p:" opt; do
  case $opt in
    o) BACKUP_SOURCES+=("$OPTARG") ;;
    r) GPG_RECIPIENT="$OPTARG" ;;
	  n) BACKUP_NAME="$OPTARG" ;;
	  p) REMOTE_PATH="$OPTARG" ;;
    *) usage ;;
  esac
done

# Проверка наличия обязательных аргументов
if [ ${#BACKUP_SOURCES[@]} -eq 0 ]; then
  usage
fi

# Создание имени архива
if [ -z "$BACKUP_NAME" ];
then
  TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")
  ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"
else
  TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")
  ARCHIVE_NAME="${BACKUP_NAME}_$TIMESTAMP.tar.gz"
fi

# Создание архива для каждого источника
tar -czf "$BACKUP_DEST/$ARCHIVE_NAME" "${BACKUP_SOURCES[@]}"

# Шифрование архива
ENCRYPTED_FILENAME="$ARCHIVE_NAME.gpg"
gpg --output "$BACKUP_DEST/$ENCRYPTED_FILENAME" --encrypt --recipient "$GPG_RECIPIENT" "$BACKUP_DEST/$ARCHIVE_NAME"

# Удаление оригинального архива
rm "$BACKUP_DEST/$ARCHIVE_NAME"

rclone copy "$BACKUP_DEST/$ENCRYPTED_FILENAME" ${RCLONE_ID}:${REMOTE_PATH}

# Очистка временных файлов
#rm "$BACKUP_DEST/$ENCRYPTED_FILENAME"