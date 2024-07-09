#!/bin/bash

# Usage - ./gpgbackup.sh -o /path/to/dir1 -o /path/to/file2 -o /path/to/dir3 -r recipient@example.com -n my_backup -p /path/to/remotefolder
# Usage with config - ./gpgbackup.sh -c /path/to/backup.conf -o /path/to/dir1 -o /path/to/file2 -o /path/to/dir3

usage() {
  echo "Usage: $0 -o <directory_or_file_to_backup> [-o <another_directory_or_file_to_backup> ...] -r <gpg_recipient>"
  exit 1
}

# Параметры
BACKUP_DEST=""  # Путь для временного хранения бэкапа на сервере, без ключа
GPG_RECIPIENT=""  # Получатель GPG (email или ключ), ключ -r
RCLONE_ID="" # Rclone ID для копирования
BACKUP_SOURCES=() # Источники бэкапа
REMOTE_PATH="" # Путь для временных архивов
BACKUP_NAME=""  # Имя архива

# Функция для обработки аргументов командной строки
process_args() {
  local OPTIND
  while getopts "c:o:r:n:p:" opt; do
    case $opt in
      c) CONFIG_FILE="$OPTARG" ;;
      o) BACKUP_SOURCES+=("$OPTARG") ;;
      r) GPG_RECIPIENT="$OPTARG" ;;
      n) BACKUP_NAME="$OPTARG" ;;
      p) REMOTE_PATH="$OPTARG" ;;
      *) usage ;;
    esac
  done
}

# Функция для проверки наличия обязательных переменных
check_required_vars() {
  if [ -z "$BACKUP_DEST" ] || [ -z "$GPG_RECIPIENT" ] || [ -z "$RCLONE_ID" ] || [ ${#BACKUP_SOURCES[@]} -eq 0 ] || [ -z "$REMOTE_PATH" ]; then
    echo "Missing required parameters. Please provide either a config file or all necessary parameters."
    #usage
  fi
}

# Первичное чтение параметров командной строки
process_args "$@"

# Проверка наличия файла конфигурации, если существует, то загружаем переменные
if [ -n "$CONFIG_FILE" ]; then
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    #IFS=' ' read -r -a BACKUP_SOURCES <<< "$BACKUP_SOURCES"
  else
    echo "Config file not found!"
    exit 1
  fi
fi

# Повторное чтение параметров командной строки для перезаписи значений из конфигурационного файла
OPTIND=1
process_args "$@"

# Проверка наличия обязательных переменных
check_required_vars

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
rm "$BACKUP_DEST/$ENCRYPTED_FILENAME"