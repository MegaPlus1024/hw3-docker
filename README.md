# ДЗ 3. Docker

Приложение со счётчиком. Исходные `app.py` и `requirements.txt` взяты из
[шаблона](https://github.com/null-ref-exc/hw_3_template) без изменений.
[Условие задания](https://github.com/Nikfilk2030/missing_semester_hse_cs/tree/main/2026/amcs/year_1/hw_3).

## Файлы

- `Dockerfile` — образ приложения на Python 3.13.
- `compose.sqlite.yaml` — один сервис и volume для этапа на 6 баллов.
- `compose.yaml` — итоговый вариант с приложением и Redis.
- `.env.example` — пример приветствия и внешнего порта.
- `scripts/check.sh` — проверка сохранения данных, сбоя Redis и восстановления из копии.
- `scripts/collect_logs.sh` — проверка этапов 4 и 6, затем два запуска `check.sh` и запись отчёта.
- `REPORT.md` — отчёт о фактически выполненных проверках.

Нужны Docker Engine с Compose, Bash и curl. В Windows команды выполняются
в Ubuntu/WSL с доступом к работающему Docker Desktop. Python и Redis на
компьютер устанавливать не нужно: они находятся в образах.

## Все проверки одной командой

Из корня проекта:

```bash
chmod +x scripts/*.sh
./scripts/collect_logs.sh
```

Сначала проверяется один контейнер, затем Compose с SQLite, затем дважды
запускается проверка итогового варианта с Redis. Для проверок создаются
отдельные проекты с пустыми volumes и свободными портами. Настройки из
пользовательского `.env` в тестах не используются.

После полного успешного выполнения будут записаны:

- `logs/level-4.log` — запуск одного контейнера и его логи;
- `logs/level-6.log` — сохранение SQLite после удаления контейнера;
- `logs/check-1.log` и `logs/check-2.log` — два последовательных запуска;
- `REPORT.md` — результаты и полный вывод двух запусков;
- `backups/` — архивы данных Redis.

Если проверка падает, скрипт печатает этап и возвращает ненулевой код.
Предыдущий успешный отчёт при этом не заменяется. Архивы данных в Git
не добавляются, а `REPORT.md` и логи добавляются.

## 4 балла: один контейнер

```bash
docker build -t hw3-app .
container=$(docker run -d -p 127.0.0.1:8080:8000 \
    -e GREETING="Привет, Docker!" -e STORAGE=sqlite hw3-app)
```

После запуска сервера:

```bash
curl --max-time 5 -fsS http://127.0.0.1:8080/
curl --max-time 5 -fsS -X POST http://127.0.0.1:8080/increment
curl --max-time 5 -fsS http://127.0.0.1:8080/
docker logs "$container"
docker rm -f "$container"
```

В новом контейнере GET возвращает `count: 0`, POST — `count: 1`, следующий
GET — `count: 1`. Без volume SQLite находится внутри контейнера.
`collect_logs.sh` выполняет эти действия автоматически и сохраняет вывод.

## 6 баллов: Compose и SQLite

Создать настройки и при необходимости поменять значения:

```bash
cp .env.example .env
```

| Переменная | Значение в примере | Что меняется |
| --- | --- | --- |
| `GREETING` | `Привет, Docker!` | Приветствие в JSON |
| `APP_PORT` | `8080` | Порт на компьютере |

Внутри контейнера порт остаётся `8000`. Для ручных примеров ниже
используется внешний порт `8080`. Если поменять `APP_PORT`, нужно поменять
его и в адресах запросов. Без `.env` используются `8080` и `Hello, Docker!`.

```bash
docker compose -p hw3-sqlite -f compose.sqlite.yaml up -d --build --wait --wait-timeout 60
curl --max-time 5 -fsS -X POST http://127.0.0.1:8080/increment
curl --max-time 5 -fsS http://127.0.0.1:8080/
docker compose -p hw3-sqlite -f compose.sqlite.yaml down
docker compose -p hw3-sqlite -f compose.sqlite.yaml up -d --wait --wait-timeout 60
curl --max-time 5 -fsS http://127.0.0.1:8080/
docker compose -p hw3-sqlite -f compose.sqlite.yaml down
```

Значение последнего GET должно совпасть со значением до `down`.
Именованный volume `sqlite_data` хранит `/data/counter.db` отдельно от контейнера.
Последний `down` освобождает порт для следующего этапа и сохраняет данные.

## 8 баллов: приложение и Redis

```bash
docker compose up -d --build --wait --wait-timeout 60
curl --max-time 5 -fsS http://127.0.0.1:8080/
curl --max-time 5 -fsS -X POST http://127.0.0.1:8080/increment
curl --max-time 5 -fsS -X POST http://127.0.0.1:8080/increment
curl --max-time 5 -fsS -X POST http://127.0.0.1:8080/increment
curl --max-time 5 -fsS http://127.0.0.1:8080/
```

Записать полученное значение `N`, затем проверить сохранение:

```bash
docker compose down
docker compose up -d --wait --wait-timeout 60
curl --max-time 5 -fsS http://127.0.0.1:8080/
```

Должно вернуться то же `N`. Здесь нужен `down` без `-v`, иначе volume будет удалён.
Redis сохраняет данные в `/data` с включённым AOF (`--appendonly yes`).

Проверка сбоя хранилища:

```bash
docker compose stop redis
curl --max-time 5 -i http://127.0.0.1:8080/healthz
curl --max-time 5 -i http://127.0.0.1:8080/readyz
curl --max-time 5 -i -X POST http://127.0.0.1:8080/increment
docker compose start redis
curl --retry 30 --retry-delay 1 --retry-max-time 60 --max-time 3 \
    --connect-timeout 2 -fsS http://127.0.0.1:8080/readyz
curl --max-time 5 -fsS http://127.0.0.1:8080/
curl --max-time 5 -fsS -X POST http://127.0.0.1:8080/increment
```

При остановленном Redis `/healthz` должен вернуть 200, а `/readyz` и POST — 503.
После запуска Redis GET возвращает `N`, POST — `N + 1`. Приложение при этом
перезапускать не требуется.

У обоих сервисов есть healthcheck. Приложение обращается к
`redis://redis:6379/0` по имени сервиса. На компьютере опубликован только
порт приложения, доступный по `127.0.0.1`.

## 10 баллов: ограничения и автоматическая проверка

В итоговом варианте приложение работает с UID 1000, корневая файловая
система доступна только для чтения. Лимиты: 256 MiB памяти и одно ядро CPU.
Запись данных выполняет Redis в свой volume.

Отдельный запуск проверки:

```bash
./scripts/check.sh
```

Скрипт проверяет:

1. Пустое хранилище: `0`, пять POST: `5`.
2. UID, режим файловой системы и ограничения ресурсов контейнера.
3. Пересоздание только приложения: значение остаётся `5`.
4. `down` и `up` с сохранением volume: значение остаётся `5`.
5. Остановку Redis: 200 для `/healthz`, 503 для `/readyz`, GET и POST.
6. Запуск Redis без перезапуска приложения: GET возвращает `5`, POST — `6`.
7. Остановку приложения и Redis, копирование всего `/data` в tar-архив.
8. Удаление исходного тестового проекта вместе с volumes.
9. Восстановление архива в новый проект: GET возвращает `6`, POST — `7`.

При завершении `trap` удаляет тестовые контейнеры, сети и volumes.
Обычный проект и его данные проверка не затрагивает. Резервная копия
остаётся снаружи контейнеров в `backups/`.

HTTP-запросы ограничены по времени. Ожидание готовности ограничено
60 секундами. Для разбора JSON используется Python из контейнера приложения.

Команда `./scripts/collect_logs.sh` выполняет эту проверку два раза подряд
и прикладывает реальный вывод к отчёту.

## Сдача

После успешного `./scripts/collect_logs.sh` добавить исходники, Dockerfile,
Compose-файлы, скрипты, README, `REPORT.md` и `logs/` в свой репозиторий.
Для приватного репозитория предоставить доступ преподавателям.

Ссылка на репозиторий сдаётся в [форму](https://forms.gle/GGvhkaSxikbJi44t9).
По условию достаточно одного итогового коммита.
