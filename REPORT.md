# Отчёт по ДЗ 3

Проверено: 2026-11-22 18:47:26 MSK.

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

## level-4

[Отдельный лог](logs/level-4.log)

<details>
<summary>Полный вывод</summary>

```text
$ docker build -t hw3-single-1795362032-18484-2964:latest .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile:
#1 transferring dockerfile: 384B 0.0s done
#1 DONE 0.2s

#2 [internal] load metadata for docker.io/library/python:3.13-slim
#2 DONE 3.0s

#3 [internal] load .dockerignore
#3 transferring context: 95B done
#3 DONE 0.1s

#4 [internal] load build context
#4 transferring context: 5.95kB 0.0s done
#4 DONE 0.2s

#5 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#5 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 0.1s done
#5 DONE 0.5s

#5 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 0B / 11.92MB 0.2s
#5 sha256:f7a79299dedd5c817d47e3f61cf6eecae73b92cb193a1ef52180a46b0161c50a 0B / 248B 0.2s
#5 sha256:0069ea31add00b9f63dbb3f0bcee44990654c5e2c17ccfeaeae47e74edf44498 0B / 1.29MB 0.2s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 0B / 29.86MB 0.2s
#5 sha256:0069ea31add00b9f63dbb3f0bcee44990654c5e2c17ccfeaeae47e74edf44498 1.05MB / 1.29MB 0.9s
#5 sha256:f7a79299dedd5c817d47e3f61cf6eecae73b92cb193a1ef52180a46b0161c50a 248B / 248B 1.0s done
#5 sha256:0069ea31add00b9f63dbb3f0bcee44990654c5e2c17ccfeaeae47e74edf44498 1.29MB / 1.29MB 1.0s done
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 1.05MB / 11.92MB 1.5s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 2.10MB / 11.92MB 2.3s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 2.10MB / 29.86MB 2.3s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 3.15MB / 11.92MB 4.1s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 4.19MB / 29.86MB 4.2s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 4.19MB / 11.92MB 4.4s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 5.24MB / 11.92MB 5.0s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 6.29MB / 29.86MB 5.4s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 6.29MB / 11.92MB 6.0s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 7.34MB / 11.92MB 6.6s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 8.39MB / 11.92MB 7.1s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 8.39MB / 29.86MB 7.1s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 9.44MB / 11.92MB 7.4s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 10.49MB / 11.92MB 7.7s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 10.49MB / 29.86MB 7.7s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 11.53MB / 11.92MB 8.3s
#5 sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 11.92MB / 11.92MB 8.5s done
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 13.63MB / 29.86MB 8.6s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 15.73MB / 29.86MB 8.9s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 17.83MB / 29.86MB 9.2s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 19.92MB / 29.86MB 10.1s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 22.02MB / 29.86MB 11.6s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 24.12MB / 29.86MB 12.2s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 26.21MB / 29.86MB 13.8s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 28.31MB / 29.86MB 14.7s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 29.86MB / 29.86MB 15.2s
#5 sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 29.86MB / 29.86MB 15.4s done
#5 extracting sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41
#5 extracting sha256:37fb86c2a767b88d500c6872195f88078f64765fe0d2f9cc375cc2efbd4c0a41 1.7s done
#5 extracting sha256:0069ea31add00b9f63dbb3f0bcee44990654c5e2c17ccfeaeae47e74edf44498
#5 extracting sha256:0069ea31add00b9f63dbb3f0bcee44990654c5e2c17ccfeaeae47e74edf44498 0.3s done
#5 DONE 18.1s

#5 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#5 extracting sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565
#5 extracting sha256:faa890a31e98e11bc3138d9549c86441024fdb24bd555bb0bca17dc9a6c5b565 1.7s done
#5 extracting sha256:f7a79299dedd5c817d47e3f61cf6eecae73b92cb193a1ef52180a46b0161c50a
#5 extracting sha256:f7a79299dedd5c817d47e3f61cf6eecae73b92cb193a1ef52180a46b0161c50a 0.1s done
#5 DONE 19.9s

#6 [2/6] WORKDIR /app
#6 DONE 1.3s

#7 [3/6] COPY app/requirements.txt .
#7 DONE 0.9s

#8 [4/6] RUN pip install --no-cache-dir -r requirements.txt
#8 6.034 Collecting redis==5.2.1 (from -r requirements.txt (line 1))
#8 6.412   Downloading redis-5.2.1-py3-none-any.whl.metadata (9.1 kB)
#8 6.598 Downloading redis-5.2.1-py3-none-any.whl (261 kB)
#8 7.039 Installing collected packages: redis
#8 7.419 Successfully installed redis-5.2.1
#8 7.420 WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager, possibly rendering your system unusable. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv. Use the --root-user-action option if you know what you are doing and want to suppress this warning.
#8 7.422 
#8 7.422 [notice] A new release of pip is available: 26.2.2 -> 26.3
#8 7.422 [notice] To update, run: pip install --upgrade pip
#8 DONE 7.9s

#9 [5/6] RUN useradd --create-home --uid 1000 --user-group app     && mkdir -p /data     && chown app:app /data
#9 DONE 1.0s

#10 [6/6] COPY app/app.py .
#10 DONE 0.2s

#11 exporting to image
#11 exporting layers
#11 exporting layers 1.4s done
#11 exporting manifest sha256:52f56c8c45cc332993c4cefbcdf149c554af81cad3c6eb8e73422e8b88ede31a 0.1s done
#11 exporting config sha256:5ed08a6999419dc26f267402f8ada390093c171b436ea80f815a81c9a25a1f38 0.1s done
#11 exporting attestation manifest sha256:1b6d4eba6ff1dc8b70e9da25e60de88b4f968e818ba2d16e9e72c7dfc26df1af
#11 exporting attestation manifest sha256:1b6d4eba6ff1dc8b70e9da25e60de88b4f968e818ba2d16e9e72c7dfc26df1af 0.1s done
#11 exporting manifest list sha256:ccac578f7103b62849f69b707324c29513c356d675fd24cbf6f4fb66c060720f
#11 exporting manifest list sha256:ccac578f7103b62849f69b707324c29513c356d675fd24cbf6f4fb66c060720f 0.1s done
#11 naming to docker.io/library/hw3-single-1795362032-18484-2964:latest 0.0s done
#11 unpacking to docker.io/library/hw3-single-1795362032-18484-2964:latest
#11 unpacking to docker.io/library/hw3-single-1795362032-18484-2964:latest 4.3s done
#11 DONE 6.3s
$ docker run -d --name hw3-single-1795362032-18484-2964 -p 127.0.0.1::8000 -e GREETING="Привет, Docker!" -e STORAGE=sqlite hw3-single-1795362032-18484-2964:latest
a6fe9fd761a45400ad3cf49fa201b7dd86a3c78df671fdfa9ec9649ec5ed0d2e
$ curl -fsS -X GET http://127.0.0.1:64462/
{"greeting": "Привет, Docker!", "count": 0, "hostname": "a6fe9fd761a4", "storage": "sqlite"}
OK: count=0, greeting и storage совпали
$ curl -fsS -X POST http://127.0.0.1:64462/increment
{"greeting": "Привет, Docker!", "count": 1, "hostname": "a6fe9fd761a4", "storage": "sqlite"}
OK: count=1, greeting и storage совпали
$ docker logs hw3-single-1795362032-18484-2964
2026-11-22 15:41:18,948 listening port=8000 storage=sqlite
2026-11-22 15:41:19,681 http 172.17.0.1 "GET /readyz HTTP/1.1" 200 -
2026-11-22 15:41:19,757 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-22 15:41:20,889 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
hw3-single-1795362032-18484-2964
Untagged: hw3-single-1795362032-18484-2964:latest
Deleted: sha256:ccac578f7103b62849f69b707324c29513c356d675fd24cbf6f4fb66c060720f
Уровень 4: OK

```

</details>

## level-6

[Отдельный лог](logs/level-6.log)

<details>
<summary>Полный вывод</summary>

```text
Compose-проект: hw3_sqlite_1795362032-18484-2964; APP_PORT=0; GREETING=Привет, Docker!
$ APP_PORT=0 GREETING=Привет\,\ Docker\! docker compose --env-file /dev/null -p hw3_sqlite_1795362032-18484-2964 -f compose.sqlite.yaml up -d --build --wait --wait-timeout 90
 Image hw3_sqlite_1795362032-18484-2964-app Building 
#1 [internal] load local bake definitions
#1 reading from stdin 516B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 384B done
#2 DONE 0.1s

#3 [internal] load metadata for docker.io/library/python:3.13-slim
#3 DONE 0.8s

#4 [internal] load .dockerignore
#4 transferring context: 95B done
#4 DONE 0.1s

#5 [internal] load build context
#5 transferring context: 94B done
#5 DONE 0.1s

#6 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 0.1s done
#6 DONE 0.1s

#7 [2/6] WORKDIR /app
#7 CACHED

#8 [3/6] COPY app/requirements.txt .
#8 CACHED

#9 [4/6] RUN pip install --no-cache-dir -r requirements.txt
#9 CACHED

#10 [5/6] RUN useradd --create-home --uid 1000 --user-group app     && mkdir -p /data     && chown app:app /data
#10 CACHED

#11 [6/6] COPY app/app.py .
#11 CACHED

#12 exporting to image
#12 exporting layers 0.0s done
#12 exporting manifest sha256:fce24615ad4a15a668c8b75f9dac16b19560f90ea987c8e759cb1f9040115ef0 0.1s done
#12 exporting config sha256:5abfb6b45ffcd3e3a21b84fc9cb7d4933429def18d8f4664f634dc4c997e4a13 0.1s done
#12 exporting attestation manifest sha256:fb1d723c2095878f023133f6ac8c09150116c7c854121f34d4defcc0687ebde2 0.1s done
#12 exporting manifest list sha256:5c716de500aca49726df8e25b9bd8a7bbf895b19cbc53efbe8f9d781d27d9bff
#12 exporting manifest list sha256:5c716de500aca49726df8e25b9bd8a7bbf895b19cbc53efbe8f9d781d27d9bff 0.1s done
#12 naming to docker.io/library/hw3_sqlite_1795362032-18484-2964-app:latest 0.0s done
#12 unpacking to docker.io/library/hw3_sqlite_1795362032-18484-2964-app:latest
#12 unpacking to docker.io/library/hw3_sqlite_1795362032-18484-2964-app:latest 3.4s done
#12 DONE 3.9s

#13 resolving provenance for metadata file
#13 DONE 0.0s
 Image hw3_sqlite_1795362032-18484-2964-app Built 
 Network hw3_sqlite_1795362032-18484-2964_default Creating 
 Volume hw3_sqlite_1795362032-18484-2964_sqlite_data Creating 
 Volume hw3_sqlite_1795362032-18484-2964_sqlite_data Creating 
 Network hw3_sqlite_1795362032-18484-2964_default Creating 
 Volume hw3_sqlite_1795362032-18484-2964_sqlite_data Created 
 Volume hw3_sqlite_1795362032-18484-2964_sqlite_data Created 
 Network hw3_sqlite_1795362032-18484-2964_default Created 
 Network hw3_sqlite_1795362032-18484-2964_default Created 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Creating 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Created 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Starting 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Started 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Waiting 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Healthy 
$ APP_PORT=0 GREETING=Привет\,\ Docker\! docker compose --env-file /dev/null -p hw3_sqlite_1795362032-18484-2964 -f compose.sqlite.yaml ps -q app
$ curl -fsS -X GET http://127.0.0.1:32769/
{"greeting": "Привет, Docker!", "count": 0, "hostname": "3da4312cd46c", "storage": "sqlite"}
OK: count=0, greeting и storage совпали
$ curl -fsS -X POST http://127.0.0.1:32769/increment
{"greeting": "Привет, Docker!", "count": 1, "hostname": "3da4312cd46c", "storage": "sqlite"}
OK: count=1, greeting и storage совпали
$ curl -fsS -X POST http://127.0.0.1:32769/increment
{"greeting": "Привет, Docker!", "count": 2, "hostname": "3da4312cd46c", "storage": "sqlite"}
OK: count=2, greeting и storage совпали
$ curl -fsS -X POST http://127.0.0.1:32769/increment
{"greeting": "Привет, Docker!", "count": 3, "hostname": "3da4312cd46c", "storage": "sqlite"}
OK: count=3, greeting и storage совпали
$ APP_PORT=0 GREETING=Привет\,\ Docker\! docker compose --env-file /dev/null -p hw3_sqlite_1795362032-18484-2964 -f compose.sqlite.yaml down
 Container hw3_sqlite_1795362032-18484-2964-app-1 Stopping 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Stopped 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Removing 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Removed 
 Network hw3_sqlite_1795362032-18484-2964_default Removing 
 Network hw3_sqlite_1795362032-18484-2964_default Removed 
$ APP_PORT=0 GREETING=Привет\,\ Docker\! docker compose --env-file /dev/null -p hw3_sqlite_1795362032-18484-2964 -f compose.sqlite.yaml up -d --wait --wait-timeout 90
 Network hw3_sqlite_1795362032-18484-2964_default Creating 
 Network hw3_sqlite_1795362032-18484-2964_default Creating 
 Network hw3_sqlite_1795362032-18484-2964_default Created 
 Network hw3_sqlite_1795362032-18484-2964_default Created 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Creating 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Created 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Starting 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Started 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Waiting 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Healthy 
$ APP_PORT=0 GREETING=Привет\,\ Docker\! docker compose --env-file /dev/null -p hw3_sqlite_1795362032-18484-2964 -f compose.sqlite.yaml ps -q app
$ curl -fsS -X GET http://127.0.0.1:32770/
{"greeting": "Привет, Docker!", "count": 3, "hostname": "d201a0bf8cb0", "storage": "sqlite"}
OK: count=3, greeting и storage совпали
$ APP_PORT=0 GREETING=Привет\,\ Docker\! docker compose --env-file /dev/null -p hw3_sqlite_1795362032-18484-2964 -f compose.sqlite.yaml logs --no-color
app-1  | 2026-11-22 15:41:50,424 listening port=8000 storage=sqlite
app-1  | 2026-11-22 15:42:01,077 http 127.0.0.1 "GET /readyz HTTP/1.1" 200 -
app-1  | 2026-11-22 15:42:02,914 http 172.18.0.1 "GET /readyz HTTP/1.1" 200 -
app-1  | 2026-11-22 15:42:02,984 http 172.18.0.1 "GET / HTTP/1.1" 200 -
$ APP_PORT=0 GREETING=Привет\,\ Docker\! docker compose --env-file /dev/null -p hw3_sqlite_1795362032-18484-2964 -f compose.sqlite.yaml down -v --remove-orphans
 Container hw3_sqlite_1795362032-18484-2964-app-1 Stopping 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Stopped 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Removing 
 Container hw3_sqlite_1795362032-18484-2964-app-1 Removed 
 Volume hw3_sqlite_1795362032-18484-2964_sqlite_data Removing 
 Network hw3_sqlite_1795362032-18484-2964_default Removing 
 Volume hw3_sqlite_1795362032-18484-2964_sqlite_data Removed 
 Network hw3_sqlite_1795362032-18484-2964_default Removed 
Untagged: hw3_sqlite_1795362032-18484-2964-app:latest
Deleted: sha256:5c716de500aca49726df8e25b9bd8a7bbf895b19cbc53efbe8f9d781d27d9bff
Уровень 6: OK, после удаления контейнера сохранился count=3

```

</details>

## check-1

[Отдельный лог](logs/check-1.log)

<details>
<summary>Полный вывод</summary>

```text
Docker Compose version v5.7.0

1. Новый проект hw3-check-20021-26705-18497
 Image redis:7.4-alpine Pulling 
 4a603bc2424c Pulling fs layer 0B
 ad83137ff0b2 Pulling fs layer 0B
 710f3da1112f Pulling fs layer 0B
 6c0bde7286d0 Pulling fs layer 0B
 0e50696bc150 Pulling fs layer 0B
 f55179448640 Pulling fs layer 0B
 4f4fb700ef54 Pulling fs layer 0B
 4a603bc2424c Downloading 600B
 4a603bc2424c Downloading 600B
 4a603bc2424c Downloading 600B
 4a603bc2424c Downloading 600B
 4a603bc2424c Downloading 600B
 4a603bc2424c Download complete 0B
 ad83137ff0b2 Downloading 200.3kB
 ad83137ff0b2 Downloading 200.3kB
 ad83137ff0b2 Downloading 200.3kB
 ad83137ff0b2 Downloading 200.3kB
 ad83137ff0b2 Downloading 200.3kB
 ad83137ff0b2 Download complete 0B
 6c0bde7286d0 Download complete 0B
 0e50696bc150 Downloading 99B
 710f3da1112f Downloading 1.049MB
 0e50696bc150 Download complete 0B
 f55179448640 Downloading 1.049MB
 f55179448640 Downloading 1.049MB
 710f3da1112f Downloading 1.049MB
 710f3da1112f Downloading 1.049MB
 f55179448640 Downloading 1.049MB
 f55179448640 Downloading 1.049MB
 710f3da1112f Downloading 1.049MB
 f55179448640 Downloading 1.049MB
 710f3da1112f Downloading 1.049MB
 4f4fb700ef54 Download complete 0B
 f55179448640 Downloading 1.049MB
 710f3da1112f Downloading 2.097MB
 f55179448640 Downloading 2.097MB
 710f3da1112f Downloading 2.097MB
 f55179448640 Downloading 2.097MB
 710f3da1112f Downloading 2.097MB
 710f3da1112f Downloading 2.097MB
 f55179448640 Downloading 2.097MB
 f55179448640 Downloading 2.097MB
 710f3da1112f Downloading 3.146MB
 5864e364268f Download complete 0B
 f55179448640 Downloading 3.146MB
 710f3da1112f Downloading 3.146MB
 f55179448640 Downloading 3.146MB
 710f3da1112f Download complete 0B
 f55179448640 Downloading 3.146MB
 710f3da1112f Extracting 1B
 dfed3a5d50b9 Download complete 0B
 f55179448640 Downloading 3.146MB
 710f3da1112f Extracting 1B
 f55179448640 Downloading 3.146MB
 710f3da1112f Extracting 1B
 f55179448640 Downloading 3.146MB
 710f3da1112f Extracting 1B
 f55179448640 Downloading 3.146MB
 710f3da1112f Extracting 1B
 f55179448640 Downloading 3.146MB
 710f3da1112f Pull complete 0B
 f55179448640 Downloading 3.146MB
 ad83137ff0b2 Extracting 1B
 6c0bde7286d0 Pull complete 0B
 f55179448640 Downloading 3.146MB
 ad83137ff0b2 Extracting 1B
 f55179448640 Downloading 4.194MB
 ad83137ff0b2 Extracting 1B
 f55179448640 Downloading 4.194MB
 f55179448640 Downloading 4.194MB
 ad83137ff0b2 Pull complete 0B
 f55179448640 Downloading 4.194MB
 f55179448640 Downloading 4.194MB
 f55179448640 Downloading 4.194MB
 f55179448640 Downloading 4.194MB
 f55179448640 Downloading 4.194MB
 f55179448640 Downloading 4.194MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 5.243MB
 f55179448640 Downloading 6.291MB
 f55179448640 Downloading 6.291MB
 f55179448640 Downloading 6.291MB
 f55179448640 Downloading 6.291MB
 f55179448640 Downloading 6.291MB
 f55179448640 Downloading 6.291MB
 f55179448640 Downloading 6.291MB
 f55179448640 Downloading 7.34MB
 f55179448640 Downloading 7.34MB
 f55179448640 Downloading 8.389MB
 f55179448640 Downloading 8.389MB
 f55179448640 Downloading 8.389MB
 f55179448640 Downloading 9.437MB
 f55179448640 Downloading 9.437MB
 f55179448640 Downloading 9.437MB
 f55179448640 Downloading 10.49MB
 f55179448640 Downloading 10.49MB
 f55179448640 Downloading 10.49MB
 f55179448640 Downloading 10.49MB
 f55179448640 Downloading 11.53MB
 f55179448640 Downloading 11.53MB
 f55179448640 Downloading 11.53MB
 f55179448640 Downloading 11.53MB
 f55179448640 Downloading 11.53MB
 f55179448640 Downloading 11.53MB
 f55179448640 Download complete 0B
 f55179448640 Extracting 1B
 f55179448640 Extracting 1B
 f55179448640 Extracting 1B
 f55179448640 Extracting 1B
 f55179448640 Extracting 1B
 f55179448640 Pull complete 0B
 0e50696bc150 Extracting 1B
 0e50696bc150 Pull complete 0B
 4f4fb700ef54 Extracting 1B
 4f4fb700ef54 Pull complete 0B
 4a603bc2424c Pull complete 0B
 Image redis:7.4-alpine Pulled 
 Image hw3-check-20021-26705-18497-app Building 
#1 [internal] load local bake definitions
#1 reading from stdin 506B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 384B done
#2 DONE 0.1s

#3 [internal] load metadata for docker.io/library/python:3.13-slim
#3 DONE 0.9s

#4 [internal] load .dockerignore
#4 transferring context: 95B done
#4 DONE 0.2s

#5 [internal] load build context
#5 transferring context: 94B done
#5 DONE 0.1s

#6 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 0.1s done
#6 DONE 0.2s

#7 [3/6] COPY app/requirements.txt .
#7 CACHED

#8 [4/6] RUN pip install --no-cache-dir -r requirements.txt
#8 CACHED

#9 [5/6] RUN useradd --create-home --uid 1000 --user-group app     && mkdir -p /data     && chown app:app /data
#9 CACHED

#10 [2/6] WORKDIR /app
#10 CACHED

#11 [6/6] COPY app/app.py .
#11 CACHED

#12 exporting to image
#12 exporting layers
#12 exporting layers 0.0s done
#12 exporting manifest sha256:697108f9e5d157888b502eb8781aca59819a10ac5c6991183c2bda02e5646ea8 0.1s done
#12 exporting config sha256:292006902a119a1275c799685fe7ef30f38fc4e1f26afa27ee75851441e1918b
#12 exporting config sha256:292006902a119a1275c799685fe7ef30f38fc4e1f26afa27ee75851441e1918b 0.1s done
#12 exporting attestation manifest sha256:4461062a0aca83cea18f25edb9b0371b1b0f769c62e27cfc1358a43a3fddf5be
#12 exporting attestation manifest sha256:4461062a0aca83cea18f25edb9b0371b1b0f769c62e27cfc1358a43a3fddf5be 0.1s done
#12 exporting manifest list sha256:eec0d39787130574ed093f5ad6a037a9e281a0eba944b7a91372679e2a18d19a 0.1s done
#12 naming to docker.io/library/hw3-check-20021-26705-18497-app:latest
#12 naming to docker.io/library/hw3-check-20021-26705-18497-app:latest 0.0s done
#12 unpacking to docker.io/library/hw3-check-20021-26705-18497-app:latest
#12 unpacking to docker.io/library/hw3-check-20021-26705-18497-app:latest 24.7s done
#12 DONE 25.7s

#13 resolving provenance for metadata file
#13 DONE 0.0s
 Image hw3-check-20021-26705-18497-app Built 
 Network hw3-check-20021-26705-18497_default Creating 
 Network hw3-check-20021-26705-18497_default Creating 
 Volume hw3-check-20021-26705-18497_redis_data Creating 
 Volume hw3-check-20021-26705-18497_redis_data Creating 
 Volume hw3-check-20021-26705-18497_redis_data Created 
 Volume hw3-check-20021-26705-18497_redis_data Created 
 Network hw3-check-20021-26705-18497_default Created 
 Network hw3-check-20021-26705-18497_default Created 
 Container hw3-check-20021-26705-18497-redis-1 Creating 
 Container hw3-check-20021-26705-18497-redis-1 Created 
 Container hw3-check-20021-26705-18497-app-1 Creating 
 Container hw3-check-20021-26705-18497-app-1 Created 
 Container hw3-check-20021-26705-18497-redis-1 Starting 
 Container hw3-check-20021-26705-18497-redis-1 Started 
 Container hw3-check-20021-26705-18497-redis-1 Waiting 
 Container hw3-check-20021-26705-18497-redis-1 Healthy 
 Container hw3-check-20021-26705-18497-app-1 Starting 
 Container hw3-check-20021-26705-18497-app-1 Started 
app и redis готовы: http://127.0.0.1:32771
GET / -> count=0
POST /increment -> count=1
POST /increment -> count=2
POST /increment -> count=3
POST /increment -> count=4
POST /increment -> count=5
GET / -> count=5

2. Ограничения процесса app
UID: 1000
read_only=true, memory=268435456 байт, CPU=1000000000 nanoCPU

3. Пересоздание только app
 Container hw3-check-20021-26705-18497-app-1 Recreate 
 Container hw3-check-20021-26705-18497-app-1 Recreated 
 Container hw3-check-20021-26705-18497-app-1 Starting 
 Container hw3-check-20021-26705-18497-app-1 Started 
app и redis готовы: http://127.0.0.1:32772
GET / -> count=5

4. Полный down и up без удаления volume
 Container hw3-check-20021-26705-18497-app-1 Stopping 
 Container hw3-check-20021-26705-18497-app-1 Stopped 
 Container hw3-check-20021-26705-18497-app-1 Removing 
 Container hw3-check-20021-26705-18497-app-1 Removed 
 Container hw3-check-20021-26705-18497-redis-1 Stopping 
 Container hw3-check-20021-26705-18497-redis-1 Stopped 
 Container hw3-check-20021-26705-18497-redis-1 Removing 
 Container hw3-check-20021-26705-18497-redis-1 Removed 
 Network hw3-check-20021-26705-18497_default Removing 
 Network hw3-check-20021-26705-18497_default Removed 
 Network hw3-check-20021-26705-18497_default Creating 
 Network hw3-check-20021-26705-18497_default Creating 
 Network hw3-check-20021-26705-18497_default Created 
 Network hw3-check-20021-26705-18497_default Created 
 Container hw3-check-20021-26705-18497-redis-1 Creating 
 Container hw3-check-20021-26705-18497-redis-1 Created 
 Container hw3-check-20021-26705-18497-app-1 Creating 
 Container hw3-check-20021-26705-18497-app-1 Created 
 Container hw3-check-20021-26705-18497-redis-1 Starting 
 Container hw3-check-20021-26705-18497-redis-1 Started 
 Container hw3-check-20021-26705-18497-redis-1 Waiting 
 Container hw3-check-20021-26705-18497-redis-1 Healthy 
 Container hw3-check-20021-26705-18497-app-1 Starting 
 Container hw3-check-20021-26705-18497-app-1 Started 
app и redis готовы: http://127.0.0.1:32773
GET / -> count=5

5. Остановка и повторный запуск Redis
 Container hw3-check-20021-26705-18497-redis-1 Stopping 
 Container hw3-check-20021-26705-18497-redis-1 Stopped 
GET /healthz -> HTTP 200
GET /readyz -> HTTP 503
GET / -> HTTP 503
POST /increment -> HTTP 503
 Container hw3-check-20021-26705-18497-redis-1 Starting 
 Container hw3-check-20021-26705-18497-redis-1 Started 
app и redis готовы: http://127.0.0.1:32773
GET / -> count=5
POST /increment -> count=6

6. Согласованная резервная копия
 Container hw3-check-20021-26705-18497-app-1 Stopping 
 Container hw3-check-20021-26705-18497-app-1 Stopped 
 Container hw3-check-20021-26705-18497-redis-1 Stopping 
 Container hw3-check-20021-26705-18497-redis-1 Stopped 
Архив: /home/ser/hw3/backups/hw3-check-20021-26705-18497.tar

7. Удаление исходного тестового проекта с volumes
 Container hw3-check-20021-26705-18497-app-1 Stopping 
 Container hw3-check-20021-26705-18497-app-1 Stopped 
 Container hw3-check-20021-26705-18497-app-1 Removing 
 Container hw3-check-20021-26705-18497-app-1 Removed 
 Container hw3-check-20021-26705-18497-redis-1 Stopping 
 Container hw3-check-20021-26705-18497-redis-1 Stopped 
 Container hw3-check-20021-26705-18497-redis-1 Removing 
 Container hw3-check-20021-26705-18497-redis-1 Removed 
 Network hw3-check-20021-26705-18497_default Removing 
 Volume hw3-check-20021-26705-18497_redis_data Removing 
 Volume hw3-check-20021-26705-18497_redis_data Removed 
 Image hw3-check-20021-26705-18497-app:latest Removing 
 Network hw3-check-20021-26705-18497_default Removed 
 Image hw3-check-20021-26705-18497-app:latest Removed 

8. Проверка восстановления из архива
 Network hw3-check-20021-26705-18497-restore_default Creating 
 Network hw3-check-20021-26705-18497-restore_default Creating 
 Volume hw3-check-20021-26705-18497-restore_redis_data Creating 
 Volume hw3-check-20021-26705-18497-restore_redis_data Creating 
 Volume hw3-check-20021-26705-18497-restore_redis_data Created 
 Volume hw3-check-20021-26705-18497-restore_redis_data Created 
 Network hw3-check-20021-26705-18497-restore_default Created 
 Network hw3-check-20021-26705-18497-restore_default Created 
 Container hw3-check-20021-26705-18497-restore-redis-1 Creating 
 Container hw3-check-20021-26705-18497-restore-redis-1 Created 
 Image hw3-check-20021-26705-18497-restore-app Building 
#1 [internal] load local bake definitions
#1 reading from stdin 522B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 384B done
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/python:3.13-slim
#3 DONE 1.8s

#4 [internal] load .dockerignore
#4 transferring context: 95B done
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 94B done
#5 DONE 0.1s

#6 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 0.1s done
#6 DONE 0.1s

#7 [4/6] RUN pip install --no-cache-dir -r requirements.txt
#7 CACHED

#8 [5/6] RUN useradd --create-home --uid 1000 --user-group app     && mkdir -p /data     && chown app:app /data
#8 CACHED

#9 [2/6] WORKDIR /app
#9 CACHED

#10 [3/6] COPY app/requirements.txt .
#10 CACHED

#11 [6/6] COPY app/app.py .
#11 CACHED

#12 exporting to image
#12 exporting layers
#12 exporting layers done
#12 exporting manifest sha256:cd801029cc08aa6e8a82e3df5d820b501709824606000c2071e9ea5843d08c4f 0.1s done
#12 exporting config sha256:40f9f4e8d5cca8418ad427317afd37b140ab3742294e0887ce2abe578663515a 0.1s done
#12 exporting attestation manifest sha256:7eda7d9682924e7cebca06403871152503043aeacbd66d696c9c6273b6067dea 0.1s done
#12 exporting manifest list sha256:e23466283ac43d4de2d15fe8f5fe1dbacf6092b3e7814683e0ce4304934bff30
#12 exporting manifest list sha256:e23466283ac43d4de2d15fe8f5fe1dbacf6092b3e7814683e0ce4304934bff30 0.1s done
#12 naming to docker.io/library/hw3-check-20021-26705-18497-restore-app:latest 0.0s done
#12 unpacking to docker.io/library/hw3-check-20021-26705-18497-restore-app:latest
#12 unpacking to docker.io/library/hw3-check-20021-26705-18497-restore-app:latest 4.5s done
#12 DONE 5.0s

#13 resolving provenance for metadata file
#13 DONE 0.0s
 Image hw3-check-20021-26705-18497-restore-app Built 
 Container hw3-check-20021-26705-18497-restore-app-1 Creating 
 Container hw3-check-20021-26705-18497-restore-app-1 Created 
 Container hw3-check-20021-26705-18497-restore-redis-1 Starting 
 Container hw3-check-20021-26705-18497-restore-redis-1 Started 
 Container hw3-check-20021-26705-18497-restore-redis-1 Waiting 
 Container hw3-check-20021-26705-18497-restore-redis-1 Healthy 
 Container hw3-check-20021-26705-18497-restore-app-1 Starting 
 Container hw3-check-20021-26705-18497-restore-app-1 Started 
app и redis готовы: http://127.0.0.1:32774
GET / -> count=6
POST /increment -> count=7
 Container hw3-check-20021-26705-18497-restore-app-1 Stopping 
 Container hw3-check-20021-26705-18497-restore-app-1 Stopped 
 Container hw3-check-20021-26705-18497-restore-app-1 Removing 
 Container hw3-check-20021-26705-18497-restore-app-1 Removed 
 Container hw3-check-20021-26705-18497-restore-redis-1 Stopping 
 Container hw3-check-20021-26705-18497-restore-redis-1 Stopped 
 Container hw3-check-20021-26705-18497-restore-redis-1 Removing 
 Container hw3-check-20021-26705-18497-restore-redis-1 Removed 
 Network hw3-check-20021-26705-18497-restore_default Removing 
 Volume hw3-check-20021-26705-18497-restore_redis_data Removing 
 Volume hw3-check-20021-26705-18497-restore_redis_data Removed 
 Image hw3-check-20021-26705-18497-restore-app:latest Removing 
 Network hw3-check-20021-26705-18497-restore_default Removed 
 Image hw3-check-20021-26705-18497-restore-app:latest Removed 

OK: все проверки пройдены, тестовые контейнеры и volumes удалены.
Резервная копия сохранена: /home/ser/hw3/backups/hw3-check-20021-26705-18497.tar

```

</details>

## check-2

[Отдельный лог](logs/check-2.log)

<details>
<summary>Полный вывод</summary>

```text
Docker Compose version v5.7.0

1. Новый проект hw3-check-23626-15408-24236
 Image hw3-check-23626-15408-24236-app Building 
#1 [internal] load local bake definitions
#1 reading from stdin 506B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 384B done
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/python:3.13-slim
#3 DONE 4.2s

#4 [internal] load .dockerignore
#4 transferring context: 32B 0.0s
#4 transferring context: 95B 0.1s done
#4 DONE 0.6s

#5 [internal] load build context
#5 transferring context: 94B 0.0s done
#5 DONE 0.1s

#6 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 0.1s done
#6 DONE 0.2s

#7 [3/6] COPY app/requirements.txt .
#7 CACHED

#8 [4/6] RUN pip install --no-cache-dir -r requirements.txt
#8 CACHED

#9 [5/6] RUN useradd --create-home --uid 1000 --user-group app     && mkdir -p /data     && chown app:app /data
#9 CACHED

#10 [2/6] WORKDIR /app
#10 CACHED

#11 [6/6] COPY app/app.py .
#11 CACHED

#12 exporting to image
#12 exporting layers done
#12 exporting manifest sha256:bb54bba6133f9905cd7ebccb76186d271d2cdfe869b1bb5984ccfcd37f905e57 0.1s done
#12 exporting config sha256:ca052e3508c9b96f84c9d5a4d6a3c7819baba7edf36cbf0ecee4221d97108493
#12 exporting config sha256:ca052e3508c9b96f84c9d5a4d6a3c7819baba7edf36cbf0ecee4221d97108493 0.1s done
#12 exporting attestation manifest sha256:a30de4946f045e59ce4b6ce84b769dc6509bcd2f0b64ce987fb6abb4712db429
#12 exporting attestation manifest sha256:a30de4946f045e59ce4b6ce84b769dc6509bcd2f0b64ce987fb6abb4712db429 0.1s done
#12 exporting manifest list sha256:854ec0dfbff2397d918c0e389002796683d2f89420eb019a7e5d9bd015e97cf6 0.1s done
#12 naming to docker.io/library/hw3-check-23626-15408-24236-app:latest
#12 naming to docker.io/library/hw3-check-23626-15408-24236-app:latest 0.0s done
#12 unpacking to docker.io/library/hw3-check-23626-15408-24236-app:latest
#12 unpacking to docker.io/library/hw3-check-23626-15408-24236-app:latest 3.4s done
#12 DONE 3.9s

#13 resolving provenance for metadata file
#13 DONE 0.0s
 Image hw3-check-23626-15408-24236-app Built 
 Network hw3-check-23626-15408-24236_default Creating 
 Network hw3-check-23626-15408-24236_default Creating 
 Volume hw3-check-23626-15408-24236_redis_data Creating 
 Volume hw3-check-23626-15408-24236_redis_data Creating 
 Volume hw3-check-23626-15408-24236_redis_data Created 
 Volume hw3-check-23626-15408-24236_redis_data Created 
 Network hw3-check-23626-15408-24236_default Created 
 Network hw3-check-23626-15408-24236_default Created 
 Container hw3-check-23626-15408-24236-redis-1 Creating 
 Container hw3-check-23626-15408-24236-redis-1 Created 
 Container hw3-check-23626-15408-24236-app-1 Creating 
 Container hw3-check-23626-15408-24236-app-1 Created 
 Container hw3-check-23626-15408-24236-redis-1 Starting 
 Container hw3-check-23626-15408-24236-redis-1 Started 
 Container hw3-check-23626-15408-24236-redis-1 Waiting 
 Container hw3-check-23626-15408-24236-redis-1 Healthy 
 Container hw3-check-23626-15408-24236-app-1 Starting 
 Container hw3-check-23626-15408-24236-app-1 Started 
app и redis готовы: http://127.0.0.1:32775
GET / -> count=0
POST /increment -> count=1
POST /increment -> count=2
POST /increment -> count=3
POST /increment -> count=4
POST /increment -> count=5
GET / -> count=5

2. Ограничения процесса app
UID: 1000
read_only=true, memory=268435456 байт, CPU=1000000000 nanoCPU

3. Пересоздание только app
 Container hw3-check-23626-15408-24236-app-1 Recreate 
 Container hw3-check-23626-15408-24236-app-1 Recreated 
 Container hw3-check-23626-15408-24236-app-1 Starting 
 Container hw3-check-23626-15408-24236-app-1 Started 
app и redis готовы: http://127.0.0.1:32776
GET / -> count=5

4. Полный down и up без удаления volume
 Container hw3-check-23626-15408-24236-app-1 Stopping 
 Container hw3-check-23626-15408-24236-app-1 Stopped 
 Container hw3-check-23626-15408-24236-app-1 Removing 
 Container hw3-check-23626-15408-24236-app-1 Removed 
 Container hw3-check-23626-15408-24236-redis-1 Stopping 
 Container hw3-check-23626-15408-24236-redis-1 Stopped 
 Container hw3-check-23626-15408-24236-redis-1 Removing 
 Container hw3-check-23626-15408-24236-redis-1 Removed 
 Network hw3-check-23626-15408-24236_default Removing 
 Network hw3-check-23626-15408-24236_default Removed 
 Network hw3-check-23626-15408-24236_default Creating 
 Network hw3-check-23626-15408-24236_default Creating 
 Network hw3-check-23626-15408-24236_default Created 
 Network hw3-check-23626-15408-24236_default Created 
 Container hw3-check-23626-15408-24236-redis-1 Creating 
 Container hw3-check-23626-15408-24236-redis-1 Created 
 Container hw3-check-23626-15408-24236-app-1 Creating 
 Container hw3-check-23626-15408-24236-app-1 Created 
 Container hw3-check-23626-15408-24236-redis-1 Starting 
 Container hw3-check-23626-15408-24236-redis-1 Started 
 Container hw3-check-23626-15408-24236-redis-1 Waiting 
 Container hw3-check-23626-15408-24236-redis-1 Healthy 
 Container hw3-check-23626-15408-24236-app-1 Starting 
 Container hw3-check-23626-15408-24236-app-1 Started 
app и redis готовы: http://127.0.0.1:32777
GET / -> count=5

5. Остановка и повторный запуск Redis
 Container hw3-check-23626-15408-24236-redis-1 Stopping 
 Container hw3-check-23626-15408-24236-redis-1 Stopped 
GET /healthz -> HTTP 200
GET /readyz -> HTTP 503
GET / -> HTTP 503
POST /increment -> HTTP 503
 Container hw3-check-23626-15408-24236-redis-1 Starting 
 Container hw3-check-23626-15408-24236-redis-1 Started 
app и redis готовы: http://127.0.0.1:32777
GET / -> count=5
POST /increment -> count=6

6. Согласованная резервная копия
 Container hw3-check-23626-15408-24236-app-1 Stopping 
 Container hw3-check-23626-15408-24236-app-1 Stopped 
 Container hw3-check-23626-15408-24236-redis-1 Stopping 
 Container hw3-check-23626-15408-24236-redis-1 Stopped 
Архив: /home/ser/hw3/backups/hw3-check-23626-15408-24236.tar

7. Удаление исходного тестового проекта с volumes
 Container hw3-check-23626-15408-24236-app-1 Stopping 
 Container hw3-check-23626-15408-24236-app-1 Stopped 
 Container hw3-check-23626-15408-24236-app-1 Removing 
 Container hw3-check-23626-15408-24236-app-1 Removed 
 Container hw3-check-23626-15408-24236-redis-1 Stopping 
 Container hw3-check-23626-15408-24236-redis-1 Stopped 
 Container hw3-check-23626-15408-24236-redis-1 Removing 
 Container hw3-check-23626-15408-24236-redis-1 Removed 
 Volume hw3-check-23626-15408-24236_redis_data Removing 
 Network hw3-check-23626-15408-24236_default Removing 
 Volume hw3-check-23626-15408-24236_redis_data Removed 
 Image hw3-check-23626-15408-24236-app:latest Removing 
 Network hw3-check-23626-15408-24236_default Removed 
 Image hw3-check-23626-15408-24236-app:latest Removed 

8. Проверка восстановления из архива
 Network hw3-check-23626-15408-24236-restore_default Creating 
 Volume hw3-check-23626-15408-24236-restore_redis_data Creating 
 Network hw3-check-23626-15408-24236-restore_default Creating 
 Volume hw3-check-23626-15408-24236-restore_redis_data Creating 
 Volume hw3-check-23626-15408-24236-restore_redis_data Created 
 Volume hw3-check-23626-15408-24236-restore_redis_data Created 
 Network hw3-check-23626-15408-24236-restore_default Created 
 Network hw3-check-23626-15408-24236-restore_default Created 
 Container hw3-check-23626-15408-24236-restore-redis-1 Creating 
 Container hw3-check-23626-15408-24236-restore-redis-1 Created 
 Image hw3-check-23626-15408-24236-restore-app Building 
#1 [internal] load local bake definitions
#1 reading from stdin 522B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 384B 0.0s done
#2 DONE 0.1s

#3 [internal] load metadata for docker.io/library/python:3.13-slim
#3 DONE 1.1s

#4 [internal] load .dockerignore
#4 transferring context: 95B done
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 94B done
#5 DONE 0.1s

#6 [1/6] FROM docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
#6 resolve docker.io/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90 0.1s done
#6 DONE 0.1s

#7 [3/6] COPY app/requirements.txt .
#7 CACHED

#8 [4/6] RUN pip install --no-cache-dir -r requirements.txt
#8 CACHED

#9 [5/6] RUN useradd --create-home --uid 1000 --user-group app     && mkdir -p /data     && chown app:app /data
#9 CACHED

#10 [2/6] WORKDIR /app
#10 CACHED

#11 [6/6] COPY app/app.py .
#11 CACHED

#12 exporting to image
#12 exporting layers done
#12 exporting manifest sha256:867b75faea97e9d261eb323e2dc07f9f37d01ca04261faceb1cfb63627252aad 0.0s done
#12 exporting config sha256:21f614d5dfdf2ada174c482c4582090b60f4183af531bf3935d110df85468915
#12 exporting config sha256:21f614d5dfdf2ada174c482c4582090b60f4183af531bf3935d110df85468915 0.1s done
#12 exporting attestation manifest sha256:f30125acf409ea8f840e96f14e3717ba14aee3efc915301d37ab1c75819f8660
#12 exporting attestation manifest sha256:f30125acf409ea8f840e96f14e3717ba14aee3efc915301d37ab1c75819f8660 0.1s done
#12 exporting manifest list sha256:08e90812f7d82af85d8f9b62a42beb4edd24ca3af14941d5aea6eccc7375c25c 0.1s done
#12 naming to docker.io/library/hw3-check-23626-15408-24236-restore-app:latest
#12 naming to docker.io/library/hw3-check-23626-15408-24236-restore-app:latest 0.0s done
#12 unpacking to docker.io/library/hw3-check-23626-15408-24236-restore-app:latest
#12 unpacking to docker.io/library/hw3-check-23626-15408-24236-restore-app:latest 3.1s done
#12 DONE 3.5s

#13 resolving provenance for metadata file
#13 DONE 0.0s
 Image hw3-check-23626-15408-24236-restore-app Built 
 Container hw3-check-23626-15408-24236-restore-app-1 Creating 
 Container hw3-check-23626-15408-24236-restore-app-1 Created 
 Container hw3-check-23626-15408-24236-restore-redis-1 Starting 
 Container hw3-check-23626-15408-24236-restore-redis-1 Started 
 Container hw3-check-23626-15408-24236-restore-redis-1 Waiting 
 Container hw3-check-23626-15408-24236-restore-redis-1 Healthy 
 Container hw3-check-23626-15408-24236-restore-app-1 Starting 
 Container hw3-check-23626-15408-24236-restore-app-1 Started 
app и redis готовы: http://127.0.0.1:32778
GET / -> count=6
POST /increment -> count=7
 Container hw3-check-23626-15408-24236-restore-app-1 Stopping 
 Container hw3-check-23626-15408-24236-restore-app-1 Stopped 
 Container hw3-check-23626-15408-24236-restore-app-1 Removing 
 Container hw3-check-23626-15408-24236-restore-app-1 Removed 
 Container hw3-check-23626-15408-24236-restore-redis-1 Stopping 
 Container hw3-check-23626-15408-24236-restore-redis-1 Stopped 
 Container hw3-check-23626-15408-24236-restore-redis-1 Removing 
 Container hw3-check-23626-15408-24236-restore-redis-1 Removed 
 Network hw3-check-23626-15408-24236-restore_default Removing 
 Volume hw3-check-23626-15408-24236-restore_redis_data Removing 
 Volume hw3-check-23626-15408-24236-restore_redis_data Removed 
 Image hw3-check-23626-15408-24236-restore-app:latest Removing 
 Network hw3-check-23626-15408-24236-restore_default Removed 
 Image hw3-check-23626-15408-24236-restore-app:latest Removed 

OK: все проверки пройдены, тестовые контейнеры и volumes удалены.
Резервная копия сохранена: /home/ser/hw3/backups/hw3-check-23626-15408-24236.tar

```

</details>
