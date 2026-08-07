#!/usr/bin/env bash
# Безопасное обновление Foundation.
#
# Что делает: скачивает свежую версию служебной части (скиллы, устав, инструкции)
# и обновляет ТОЛЬКО её.
#
# Чего не делает НИКОГДА: не трогает личные файлы —
#   PROFILE.md, SOUL.md, MEMORY.md, memory/, knowledge/, workspace/
#
# Запуск: bash update.sh
#
# Тело обёрнуто в функцию main специально: так bash читает файл целиком ДО выполнения,
# и скрипт может безопасно обновить сам себя в конце работы.

set -euo pipefail

main() {
  SKLAD="${FOUNDATION_SOURCE_URL:-https://github.com/megapolisagent/FOUNDATION.git}"
  TMP=".obnovlenie-tmp"

  # Папки, которые обновляются целиком.
  SLUZHEBNYE_PAPKI=("skills" "instructions")

  # Служебные файлы, которые обновляются.
  # README.md сознательно НЕ обновляем — см. UPDATE.md.
  SLUZHEBNYE_FAYLY=("HOME.md" "AGENTS.md" "ROUTING.md" "update.sh")

  # Личные файлы — список для проверки, что мы их не задели.
  LICHNYE=("PROFILE.md" "SOUL.md" "MEMORY.md" "memory" "knowledge" "workspace")

  echo "Обновляю Foundation. Личные файлы не трогаю."
  echo

  if [ ! -f "HOME.md" ]; then
    echo "Не вижу файла HOME.md — похоже, это не корень дома."
    echo "Перейди в папку дома и запусти скрипт оттуда."
    exit 1
  fi

  SLEPOK_DO="$(sled_lichnyh "${LICHNYE[@]}")"

  if [ -e "$TMP" ]; then
    echo "Папка $TMP уже существует. Удали её вручную и запусти снова."
    exit 1
  fi

  echo "Скачиваю свежую версию из репозитория-источника..."
  git clone --quiet --depth 1 "$SKLAD" "$TMP"

  echo "Обновляю служебную часть:"

  for papka in "${SLUZHEBNYE_PAPKI[@]}"; do
    if [ -d "$TMP/$papka" ]; then
      mkdir -p "$papka"
      cp -R "$TMP/$papka/." "$papka/"
      echo "   $papka"
    fi
  done

  for fayl in "${SLUZHEBNYE_FAYLY[@]}"; do
    if [ -f "$TMP/$fayl" ]; then
      cp "$TMP/$fayl" "$fayl"
      echo "   $fayl"
    fi
  done

  rm -rf "$TMP"

  SLEPOK_POSLE="$(sled_lichnyh "${LICHNYE[@]}")"

  echo
  if [ "$SLEPOK_DO" = "$SLEPOK_POSLE" ]; then
    echo "Проверка пройдена: личные файлы не изменились."
  else
    echo "ВНИМАНИЕ: личные файлы изменились — такого быть не должно."
    echo "Ничего не удаляй и сообщи об этом до того, как продолжишь."
    exit 1
  fi

  echo
  echo "Готово. Закрой этот чат и открой новый — агент подхватит обновления."
}

# Слепок содержимого личных файлов: список «контрольная сумма - файл».
sled_lichnyh() {
  for p in "$@"; do
    if [ -e "$p" ]; then
      find "$p" -type f -exec shasum {} \; 2>/dev/null | sort
    fi
  done
}

main "$@"
