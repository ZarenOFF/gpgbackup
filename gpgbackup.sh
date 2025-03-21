#!/bin/bash
exec >> /var/log/gpgbackup.log 2>&1

usage() {
  echo "Usage: $0 [-o <another_directory_or_file_to_backup> -o ...] -r <gpg_recipient> -n <backup_name> -p <remote_path> -m <backups_count> -i <rclone_id> -d <backup_destination>"
  echo "Or using with config:"
  echo "Usage: $0 -c <config_path>"
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

######################################################################METHODS######################################################################

log() {
  local message="$1"
  local timestamp=$(date +"%d.%m.%Y %H:%M:%S")
  echo "[$timestamp] - $message"
}

log_command() {
     local description="$1"
     shift
     "$@" 2>&1 | while IFS= read -r line; do
       log "$line"
     done
     local status=${PIPESTATUS[0]}
     if [ "$status" -eq 0 ]; then
       log "$description succeeded"
     else
       log "$description failed with status $status"
     fi
     return "$status"
   }

# Функция для обработки аргументов командной строки
process_args() {
  local OPTIND
  while getopts "c:o:r:n:p:m:i:d:" opt; do
    case $opt in
      c) CONFIG_FILE="$OPTARG" ;;
      d) BACKUP_DEST="$OPTARG" ;;
      o) BACKUP_SOURCES+=("$OPTARG") ;;
      r) GPG_RECIPIENT="$OPTARG" ;;
      n) BACKUP_NAME="$OPTARG" ;;
      p) REMOTE_PATH="$OPTARG" ;;
      m) MAX_BACKUPS="$OPTARG" ;;
      i) RCLONE_ID="$OPTARG" ;;
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

######################################################################METHODS END######################################################################

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

log "Starting backup \"${BACKUP_SOURCES[*]}\" to the remote \"$RCLONE_ID\" with recipient \"$GPG_RECIPIENT\" and remote path \"$REMOTE_PATH\""

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
log_command "Creating archive" tar -czf "$BACKUP_DEST/$ARCHIVE_NAME" "${BACKUP_SOURCES[@]}"

# Шифрование архива
ENCRYPTED_FILENAME="$ARCHIVE_NAME.gpg"
log_command "Encrypting archive" gpg --output "$BACKUP_DEST/$ENCRYPTED_FILENAME" --encrypt --recipient "$GPG_RECIPIENT" "$BACKUP_DEST/$ARCHIVE_NAME"

# Удаление оригинального архива
rm "$BACKUP_DEST/$ARCHIVE_NAME"

log_command "Copying encrypted archive to remote server" rclone copy "$BACKUP_DEST/$ENCRYPTED_FILENAME" "${RCLONE_ID}":"${REMOTE_PATH}"

# Очистка временных файлов
rm "$BACKUP_DEST/$ENCRYPTED_FILENAME"

# Вывод информации о файлах в удаленной директории
log "Detailed information about files in remote directory (${RCLONE_ID}:${REMOTE_PATH}):"
log_command "Listing files in remote directory" bash -c "rclone lsl \"${RCLONE_ID}:${REMOTE_PATH}\" | sort -k2"

# Проверка количества файлов в удаленной директории и удаление самого старого, если их больше 7
FILE_COUNT=$(rclone lsf --files-only "${RCLONE_ID}":"${REMOTE_PATH}" | wc -l)

log "Current number of files in remote directory is $FILE_COUNT, maximum allowed is $MAX_BACKUPS"

if [ "$FILE_COUNT" -gt "$MAX_BACKUPS" ]; then
  EXCESS_FILE_COUNT=$((FILE_COUNT - MAX_BACKUPS))
  log "Deleting $EXCESS_FILE_COUNT oldest files to maintain the limit of $MAX_BACKUPS backups"
  rclone lsl "${RCLONE_ID}:${REMOTE_PATH}" | sort -k2 | head -n "$EXCESS_FILE_COUNT" | awk '{print $NF}' | while read -r OLDEST_FILE; do
    log_command "Deleting oldest file: $OLDEST_FILE" rclone deletefile "${RCLONE_ID}:${REMOTE_PATH}/$OLDEST_FILE"
  done
fi
