#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
root=$PWD
project="hw3-check-$$-$RANDOM-$RANDOM"
restore_project="$project-restore"
backup="$root/backups/$project.tar"
current_project=$project
first_created=0
second_created=0
stage="проверка Docker"
n=5

dc() {
    APP_PORT=0 GREETING=test docker compose --ansi never --env-file /dev/null \
        -f "$root/compose.yaml" -p "$current_project" "$@"
}

step() {
    stage=$1
    printf '\n%s\n' "$stage"
}

fail() {
    echo "Ошибка: $*" >&2
    exit 1
}

cleanup() {
    code=$?
    trap - EXIT INT TERM
    set +e
    if (( code != 0 )); then
        echo "Проверка прервана на этапе: $stage" >&2
        if (( first_created || second_created )); then
            dc logs --no-color --tail 30 >&2
        fi
    fi
    docker rm -f "$project-backup" "$project-restore-data" >/dev/null 2>&1
    if (( first_created )); then
        current_project=$project
        dc down -v --rmi local --remove-orphans --timeout 10 || code=1
    fi
    if (( second_created )); then
        current_project=$restore_project
        dc down -v --rmi local --remove-orphans --timeout 10 || code=1
    fi
    exit "$code"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

wait_ready() {
    local end=$((SECONDS + 60))
    local app redis app_health redis_health
    app=$(dc ps -aq app)
    redis=$(dc ps -aq redis)
    url="http://$(dc port app 8000)"
    while (( SECONDS < end )); do
        app_health=$(docker inspect -f '{{.State.Health.Status}}' "$app")
        redis_health=$(docker inspect -f '{{.State.Health.Status}}' "$redis")
        if [[ "$app_health" == healthy && "$redis_health" == healthy ]]; then
            if curl -fsS --connect-timeout 2 --max-time 3 "$url/readyz" >/dev/null; then
                echo "app и redis готовы: $url"
                return
            fi
        fi
        sleep 1
    done
    fail "сервисы не готовы за 60 секунд"
}

check_count() {
    local expected=$1 method=${2:-GET} path=/ body
    if [[ "$method" == POST ]]; then
        path=/increment
    fi
    body=$(curl -fsS --connect-timeout 2 --max-time 5 -X "$method" "$url$path")
    printf '%s' "$body" | dc exec -T app python -c '
import json
import sys
data = json.load(sys.stdin)
assert data["count"] == int(sys.argv[1]), data
assert data["storage"] == "redis", data
assert data["greeting"] == "test", data
' "$expected"
    echo "$method $path -> count=$expected"
}

check_status() {
    local method=$1 path=$2 expected=$3 code
    code=$(curl -sS --connect-timeout 2 --max-time 5 -o /dev/null \
        -w '%{http_code}' -X "$method" "$url$path")
    [[ "$code" == "$expected" ]] || fail "$method $path: HTTP $code вместо $expected"
    echo "$method $path -> HTTP $code"
}

redis_volume() {
    docker inspect -f '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Name}}{{end}}{{end}}' \
        "$(dc ps -aq redis)"
}

command -v docker >/dev/null || fail "не установлен Docker"
command -v curl >/dev/null || fail "не установлен curl"
docker compose version
docker info >/dev/null
mkdir -p backups

step "1. Новый проект $project"
first_created=1
dc up -d --build
wait_ready
check_count 0
for ((i = 1; i <= n; i++)); do
    check_count "$i" POST
done
check_count "$n"

step "2. Ограничения процесса app"
dc exec -T app python -c 'import os; uid = os.getuid(); print("UID:", uid); assert uid != 0'
app_id=$(dc ps -q app)
read -r readonly memory cpus <<< "$(docker inspect -f \
    '{{.HostConfig.ReadonlyRootfs}} {{.HostConfig.Memory}} {{.HostConfig.NanoCpus}}' "$app_id")"
[[ "$readonly" == true ]] || fail "корневая файловая система доступна для записи"
(( memory > 0 && memory <= 268435456 )) || fail "неверный лимит памяти: $memory"
(( cpus > 0 && cpus <= 1000000000 )) || fail "неверный лимит CPU: $cpus"
echo "read_only=$readonly, memory=$memory байт, CPU=$cpus nanoCPU"

step "3. Пересоздание только app"
redis_id=$(dc ps -q redis)
dc up -d --no-deps --force-recreate app
wait_ready
[[ "$(dc ps -q app)" != "$app_id" ]] || fail "app не пересоздан"
[[ "$(dc ps -q redis)" == "$redis_id" ]] || fail "Redis был пересоздан вместе с app"
check_count "$n"

step "4. Полный down и up без удаления volume"
dc down --timeout 10
dc up -d
wait_ready
check_count "$n"

step "5. Остановка и повторный запуск Redis"
app_id=$(dc ps -q app)
app_started=$(docker inspect -f '{{.State.StartedAt}}' "$app_id")
dc stop --timeout 10 redis
check_status GET /healthz 200
check_status GET /readyz 503
check_status GET / 503
check_status POST /increment 503
dc start redis
wait_ready
[[ "$(dc ps -q app)" == "$app_id" ]] || fail "изменился контейнер app"
[[ "$(docker inspect -f '{{.State.StartedAt}}' "$app_id")" == "$app_started" ]] \
    || fail "app был перезапущен"
check_count "$n"
check_count "$((n + 1))" POST

step "6. Согласованная резервная копия"
dc stop --timeout 10 app
dc stop --timeout 10 redis
[[ "$(docker inspect -f '{{.State.ExitCode}}' "$(dc ps -aq redis)")" == 0 ]] \
    || fail "Redis не завершился штатно"
volume=$(redis_volume)
[[ -n "$volume" ]] || fail "не найден volume Redis"
docker run --rm --name "$project-backup" --network none --user 0 \
    --mount "type=volume,source=$volume,target=/data,readonly" \
    --entrypoint tar redis:7.4-alpine -C /data -cpf - . > "$backup"
[[ -s "$backup" ]] || fail "резервная копия пуста"
echo "Архив: $backup"

step "7. Удаление исходного тестового проекта с volumes"
dc down -v --rmi local --remove-orphans --timeout 10
first_created=0
if docker volume inspect "$volume" >/dev/null 2>&1; then
    fail "исходный volume не удалён"
fi

step "8. Проверка восстановления из архива"
current_project=$restore_project
second_created=1
dc create redis
volume=$(redis_volume)
[[ -n "$volume" ]] || fail "не найден новый volume Redis"
docker run --rm -i --name "$project-restore-data" --network none --user 0 \
    --mount "type=volume,source=$volume,target=/data" \
    --entrypoint tar redis:7.4-alpine -C /data -xpf - < "$backup"
dc up -d --build
wait_ready
check_count "$((n + 1))"
check_count "$((n + 2))" POST
dc down -v --rmi local --remove-orphans --timeout 10
second_created=0

printf '\nOK: все проверки пройдены, тестовые контейнеры и volumes удалены.\n'
echo "Резервная копия сохранена: $backup"
