# 3x-ui + Caddy + VLESS + XHTTP + TLS — полная схема проксирования

## Архитектура

**Сервер (`server/`):**
- **Caddy** — reverse proxy, выпуск/обновление TLS-сертификатов
- **3x-ui** — панель управления Xray (VLESS inbounds)
- **Lampac** — маскировочный сайт

**Клиент (`client/`):**
- **tproxy.sh** — прозрачный прокси (TPROXY) для Android
- **Xray / sing-box** — прокси-клиент

## Быстрый старт

1. **[Настройка сервера →](server/README.md)** — VPS, Docker, 3x-ui, Caddy
2. **[Настройка клиента →](client/README.md)** — Android, tproxy.sh, Xray

## Благодарности

- [Akiyamov](https://github.com/Akiyamov/xray-vps-setup) — xray-vps-setup
- [ampetelin](https://github.com/ampetelin/3x-ui-aio) — 3x-ui-aio
- [MHSanaei](https://github.com/MHSanaei/3x-ui) — 3x-ui
- [Lampac NextGen](https://github.com/lampac-nextgen/lampac)
- [CHIZI-0618](https://github.com/CHIZI-0618/) — AndroidTProxyShell

## полезное


```bash
docker ps #список контейнеров
docker compose up -d    # start
docker compose down     # stop
docker compose logs -f  # logs
docker system prune -a
docker compose logs --tail 1000 lampac #Показать последние 1000 строк лога
docker volume ls
docker exec -it lampac bash
docker compose down && docker compose up -d && docker compose logs -f
docker system prune -a --volumes - Очистить все данные (контейнеры, образы, тома)
```


docker exec -it 3xui_app /app/x-ui setting -webBasePath /admin-izj0/
docker restart 3xui_app