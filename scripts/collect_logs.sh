#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

token="$(date +%s)-$$-$RANDOM"
single="hw3-single-$token"
image="hw3-single-$token:latest"
project="hw3_sqlite_$token"
log_dir="logs/run-$token"
report_tmp=""
stage="проверка Docker"
greeting="Привет, Docker!"

compose() {
    printf '$ APP_PORT=0 GREETING=%q docker compose --env-file /dev/null -p %q -f compose.sqlite.yaml' \
        "$greeting" "$project" >&2
    printf ' %q' "$@" >&2
    printf '\n' >&2
    APP_PORT=0 GREETING="$greeting" docker compose --env-file /dev/null \
        -p "$project" -f compose.sqlite.yaml "$@"
}

cleanup() {
    code=$?
    trap - EXIT
    docker rm -f "$single" >/dev/null 2>&1 || true
    compose down -v --remove-orphans >/dev/null 2>&1 || true
    docker image rm "$image" "${project}-app:latest" >/dev/null 2>&1 || true
    if [[ -n "$report_tmp" ]]; then
        rm -f -- "$report_tmp"
    fi
    if (( code != 0 )); then
        printf 'Ошибка на этапе: %s\n' "$stage" >&2
        if [[ -d "$log_dir" ]]; then
            printf 'Вывод этого запуска: %s\n' "$log_dir" >&2
        fi
    fi
    exit "$code"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

command -v docker >/dev/null || { echo "Не установлен Docker" >&2; exit 1; }
command -v curl >/dev/null || { echo "Не установлен curl" >&2; exit 1; }
docker compose version
docker info >/dev/null
mkdir -p "$log_dir"

set_url() {
    address=$(docker port "$current_container" 8000/tcp)
    url="http://127.0.0.1:${address##*:}"
}

wait_ready() {
    deadline=$((SECONDS + 60))
    until curl -fsS --connect-timeout 2 --max-time 3 "$url/readyz" >/dev/null 2>&1; do
        if (( SECONDS >= deadline )); then
            echo "Приложение не готово за 60 секунд" >&2
            return 1
        fi
        sleep 1
    done
}

check_count() {
    method=$1
    path=$2
    expected=$3
    printf '$ curl -fsS -X %s %s%s\n' "$method" "$url" "$path"
    body=$(curl -fsS --connect-timeout 2 --max-time 5 -X "$method" "$url$path")
    printf '%s\n' "$body"
    docker exec -i "$current_container" python -c '
import json
import sys

data = json.load(sys.stdin)
expected = int(sys.argv[1])
if data.get("count") != expected:
    raise SystemExit(f"Ожидался count={expected}, получено {data}")
if data.get("greeting") != sys.argv[2] or data.get("storage") != "sqlite":
    raise SystemExit(f"Неверное приветствие или хранилище: {data}")
print(f"OK: count={expected}, greeting и storage совпали")
' "$expected" "$greeting" <<< "$body"
}

level4() {
    printf '$ docker build -t %s .\n' "$image"
    docker build -t "$image" .
    printf '$ docker run -d --name %s -p 127.0.0.1::8000 -e GREETING="%s" -e STORAGE=sqlite %s\n' \
        "$single" "$greeting" "$image"
    docker run -d --name "$single" -p 127.0.0.1::8000 \
        -e GREETING="$greeting" -e STORAGE=sqlite "$image"
    current_container=$single
    set_url
    wait_ready
    check_count GET / 0
    check_count POST /increment 1
    printf '$ docker logs %s\n' "$single"
    docker logs "$single"
    docker rm -f "$single"
    docker image rm "$image"
    echo "Уровень 4: OK"
}

level6() {
    printf 'Compose-проект: %s; APP_PORT=0; GREETING=%s\n' "$project" "$greeting"
    compose up -d --build --wait --wait-timeout 90
    current_container=$(compose ps -q app)
    set_url
    wait_ready
    check_count GET / 0
    for n in 1 2 3; do
        check_count POST /increment "$n"
    done
    compose down
    compose up -d --wait --wait-timeout 90
    current_container=$(compose ps -q app)
    set_url
    wait_ready
    check_count GET / 3
    compose logs --no-color
    compose down -v --remove-orphans
    docker image rm "${project}-app:latest"
    echo "Уровень 6: OK, после удаления контейнера сохранился count=3"
}

stage="уровень 4: один контейнер"
level4 2>&1 | tee "$log_dir/level-4.log"

stage="уровень 6: Compose и SQLite"
level6 2>&1 | tee "$log_dir/level-6.log"

stage="первая проверка уровней 8 и 10"
./scripts/check.sh 2>&1 | tee "$log_dir/check-1.log"

stage="вторая проверка уровней 8 и 10"
./scripts/check.sh 2>&1 | tee "$log_dir/check-2.log"

stage="сохранение отчёта"
report_tmp=$(mktemp .report.XXXXXX)
{
    printf '# Отчёт по ДЗ 3\n\n'
    printf 'Проверено: %s.\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    cat <<'TEXT'
Упаковал приложение в Docker. Исходники приложения не менял.

В обычном контейнере передал приветствие через переменную окружения,
проверил счётчик 0 → 1 и посмотрел логи.

Для SQLite сделал отдельный Compose-файл и именованный volume.
После трёх POST удалил контейнер через `down`, запустил заново — счётчик остался 3.
Приветствие и внешний порт настраиваются через переменные окружения.

В основном `compose.yaml` работают приложение и Redis. У Redis включён AOF,
данные лежат в именованном volume. У обоих сервисов есть healthcheck.
Приложение работает не от root, с read-only файловой системой,
лимитами 256 MiB памяти и одного ядра CPU.

`./scripts/check.sh` успешно прошёл два раза подряд. Проверены сохранение
счётчика, пересоздание приложения, отключение и возврат Redis,
резервное копирование и восстановление. Тестовые проекты удалены со своими volumes.

В каждом запуске использовал отдельный Compose-проект и N = 5.
Основные команды и результаты:

| Команда или действие | Результат |
| --- | --- |
| Пять `POST /increment` | Счётчик вырос с 0 до 5 |
| `docker compose up -d --no-deps --force-recreate app` | Redis не пересоздан, GET вернул 5 |
| `docker compose down`, затем `docker compose up -d` | GET вернул 5 |
| `docker compose stop --timeout 10 redis` | `/healthz` вернул 200, `/readyz`, GET и POST вернули 503 |
| `docker compose start redis` | Тот же контейнер app без перезапуска, GET вернул 5, POST вернул 6 |
| Остановка сервисов и `tar` всего `/data` | Резервная копия записана во внешний файл |
| `docker compose down -v --rmi local --remove-orphans --timeout 10` | Исходный проект и его volume удалены |
| Восстановление архива в новый проект | GET вернул 6, POST вернул 7 |

Фактические имена проектов, порты, ответы и пути архивов записаны ниже.
Все проверки выполнены командой `./scripts/collect_logs.sh`.
Ниже полный вывод двух запусков и логи предыдущих уровней.
TEXT
    for name in level-4 level-6 check-1 check-2; do
        printf '\n## %s\n\n[Отдельный лог](logs/%s.log)\n\n' "$name" "$name"
        printf '<details>\n<summary>Полный вывод</summary>\n\n```text\n'
        cat "$log_dir/$name.log"
        printf '\n```\n\n</details>\n'
    done
} > "$report_tmp"

cp "$log_dir/level-4.log" "$log_dir/level-6.log" \
    "$log_dir/check-1.log" "$log_dir/check-2.log" logs/
mv -- "$report_tmp" REPORT.md
report_tmp=""
rm -r -- "$log_dir"
echo "Готово: REPORT.md и четыре файла в logs/. Все проверки прошли."
