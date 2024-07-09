#!/bin/bash

# Usage - ./gpgbackup.sh -o /path/to/dir1 -o /path/to/file2 -o /path/to/dir3 -r recipient@example.com
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
MAX_BACKUPS=365

log() {
  local message="$1"
  echo "$message"
}

# Функция для обработки аргументов командной строки
process_args() {
  local OPTIND
  while getopts "c:o:r:n:p:m:" opt; do
    case $opt in
      c) CONFIG_FILE="$OPTARG" ;;
      o) BACKUP_SOURCES+=("$OPTARG") ;;
      r) GPG_RECIPIENT="$OPTARG" ;;
      n) BACKUP_NAME="$OPTARG" ;;
      p) REMOTE_PATH="$OPTARG" ;;
      m) MAX_BACKUPS="$OPTARG" ;;
      *) usage ;;
    esac
  done
}

# Функция для проверки наличия обязательных переменных
check_required_vars() {
  if [ -z "$BACKUP_DEST" ] || [ -z "$GPG_RECIPIENT" ] || [ -z "$RCLONE_ID" ] || [ ${#BACKUP_SOURCES[@]} -eq 0 ] || [ -z "$REMOTE_PATH" ]; then
    log "Missing required parameters. Please provide either a config file or all necessary parameters."
    usage
  fi
}

# Первичное чтение параметров командной строки
process_args "$@"

# Проверка наличия файла конфигурации, если существует, то загружаем переменные
if [ -n "$CONFIG_FILE" ]; then
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    log "Config file not found!"
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
  ARCHIVE_NAME="BACKUP_$TIMESTAMP.tar.gz"
else
  TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")
  ARCHIVE_NAME="${BACKUP_NAME}_$TIMESTAMP.tar.gz"
fi

# Создание архива
tar -czf "$BACKUP_DEST/$ARCHIVE_NAME" "${BACKUP_SOURCES[@]}"

# Шифрование архива
ENCRYPTED_FILENAME="$ARCHIVE_NAME.gpg"
gpg --output "$BACKUP_DEST/$ENCRYPTED_FILENAME" --encrypt --recipient "$GPG_RECIPIENT" "$BACKUP_DEST/$ARCHIVE_NAME"

# Удаление оригинального архива
rm "$BACKUP_DEST/$ARCHIVE_NAME"

rclone copy "$BACKUP_DEST/$ENCRYPTED_FILENAME" "${RCLONE_ID}":"${REMOTE_PATH}"

# Очистка временных файлов
rm "$BACKUP_DEST/$ENCRYPTED_FILENAME"

# Вывод информации о файлах в удаленной директории
log "Detailed information about files in remote directory (${RCLONE_ID}:${REMOTE_PATH}):"
rclone lsl "${RCLONE_ID}":"${REMOTE_PATH}" | sort -k3

# Проверка количества файлов в удаленной директории и удаление самого старого, если их больше 7
FILE_COUNT=$(rclone lsf --files-only "${RCLONE_ID}":"${REMOTE_PATH}" | wc -l)

if [ "$FILE_COUNT" -gt "$MAX_BACKUPS" ]; then
  OLDEST_FILE=$(rclone lsl "${RCLONE_ID}":"${REMOTE_PATH}" | sort -k3 | head -n 1 | awk '{print $NF}')
  log "Deleting oldest file: $OLDEST_FILE"
  rclone deletefile "${RCLONE_ID}":"${REMOTE_PATH}"/"$OLDEST_FILE"
fi
