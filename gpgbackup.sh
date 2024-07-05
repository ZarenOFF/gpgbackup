#!/bin/bash

# Usage - ./gpgbackup.sh -o /path/to/dir1 -o /path/to/file2 -o /path/to/dir3 -r recipient@example.com

# Параметры
BACKUP_DEST="/backup/systembackup/"  # Путь для временного хранения бэкапа на сервере
WEBDAV_URL="https://webdav.example.com/backup"  # URL WebDAV сервера
WEBDAV_USER="your_webdav_username"  # Имя пользователя WebDAV
WEBDAV_PASS_FILE="/root/.webdavpass"  # Файл с паролем WebDAV
GPG_RECIPIENT="put_your_recipient"  # Получатель GPG (email или ключ)

usage() {
  echo "Usage: $0 -o <directory_or_file_to_backup> [-o <another_directory_or_file_to_backup> ...] -r <gpg_recipient>"
  exit 1
}

BACKUP_SOURCES=()

while getopts "o:r:" opt; do
  case $opt in
    o) BACKUP_SOURCES+=("$OPTARG") ;;
    r) GPG_RECIPIENT="$OPTARG" ;;
    *) usage ;;
  esac
done

# Проверка наличия обязательных аргументов
if [ ${#BACKUP_SOURCES[@]} -eq 0 ]; then
  usage
fi

# Создание архива для каждого источника
TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")
ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"
tar -czf "$BACKUP_DEST/$ARCHIVE_NAME" "${BACKUP_SOURCES[@]}"

# Шифрование архива
ENCRYPTED_FILENAME="$ARCHIVE_NAME.gpg"
gpg --output "$BACKUP_DEST/$ENCRYPTED_FILENAME" --encrypt --recipient "$GPG_RECIPIENT" "$BACKUP_DEST/$ARCHIVE_NAME"

# Удаление оригинального архива
rm "$BACKUP_DEST/$ARCHIVE_NAME"

# Загрузка на WebDAV
#WEBDAV_PASS=$(cat "$WEBDAV_PASS_FILE")
#cadaver <<EOF
#open $WEBDAV_URL
#login $WEBDAV_USER $WEBDAV_PASS
#put "$BACKUP_DEST/$ENCRYPTED_FILENAME"
#quit
#EOF

# Очистка временных файлов
#rm "$BACKUP_DEST/$ENCRYPTED_FILENAME"