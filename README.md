# GDownloader Docker

Immagine Docker non ufficiale di [GDownloader](https://github.com/hstr0100/GDownloader), con la GUI Swing originale accessibile dal browser tramite noVNC. L'immagine è destinata esclusivamente a `linux/amd64` e include GDownloader, yt-dlp, Deno, FFmpeg e ffprobe. gallery-dl e spotDL non sono inclusi e risultano disabilitati nella configurazione iniziale.

Questa è un'immagine *fixed*: applicazione e dipendenze vengono aggiornate ricostruendo e ricreando l'immagine. GDownloader non si aggiorna automaticamente dentro il container.

## Requisiti operativi

Per eseguire il container occorre scegliere soltanto:

1. la porta host da collegare alla porta web `5800` del container;
2. una cartella persistente da montare in `/config`;
3. una cartella per i file scaricati da montare in `/output`.

Non serve un volume temporaneo separato. La porta VNC `5900` non viene pubblicata.

## Build

Da un checkout di questo repository:

```bash
./scripts/build.sh
```

La build usa `versions.env`, verifica i checksum degli artefatti e produce `gdownloader-docker:1.7.8-1` per `linux/amd64`.

## Avvio con Docker

Adattare i due percorsi host e, se necessario, il numero a sinistra di `5800:5800`:

```bash
docker run -d \
    --name=gdownloader \
    -p 5800:5800 \
    -v /docker/appdata/gdownloader:/config:rw \
    -v /home/user/Downloads:/output:rw \
    --restart unless-stopped \
    gdownloader-docker:1.7.8-1
```

Aprire `http://<IP-SERVER>:5800`. Per usare, ad esempio, la porta host 8080, sostituire il mapping con `-p 8080:5800` e aprire `http://<IP-SERVER>:8080`.

## Docker Compose

Il file [compose.yaml](compose.yaml) contiene la configurazione minima:

```yaml
services:
  gdownloader:
    image: gdownloader-docker:1.7.8-1
    container_name: gdownloader
    ports:
      - "5800:5800"
    volumes:
      - /docker/appdata/gdownloader:/config:rw
      - /home/user/Downloads:/output:rw
    restart: unless-stopped
```

Dopo aver corretto porta e percorsi:

```bash
docker compose up -d
```

## Portainer Stack

1. Rendere disponibile sul nodo Docker l'immagine `gdownloader-docker:1.7.8-1`, costruendola con `./scripts/build.sh` oppure caricandola da un registry privato.
2. In Portainer aprire **Stacks**, scegliere **Add stack** e incollare il contenuto di `compose.yaml` nel Web editor.
3. Modificare obbligatoriamente porta host, percorso di `/config` e percorso di `/output` in base al server.
4. Selezionare **Deploy the stack** e aprire `http://<IP-SERVER>:5800`.

Portainer non costruisce automaticamente questa immagine dal solo Compose: il tag indicato deve già esistere sul nodo o essere disponibile in un registry raggiungibile.

## Variabili opzionali

Nessuna variabile è obbligatoria. I valori predefiniti della base jlesage sono:

| Variabile | Default | Funzione |
| --- | --- | --- |
| `USER_ID` | `1000` | UID usato dal processo applicativo |
| `GROUP_ID` | `1000` | GID usato dal processo applicativo |
| `UMASK` | `0022` | Maschera dei permessi dei nuovi file |
| `TZ` | `Etc/UTC` | Fuso orario del container |
| `LANG` | `en_US.UTF-8` | Lingua/locale del container |
| `DISPLAY_WIDTH` | `1920` | Larghezza del desktop virtuale |
| `DISPLAY_HEIGHT` | `1080` | Altezza del desktop virtuale |

Per aggiungerle a `docker run`, usare per esempio `-e TZ=Europe/Rome`. In Compose si possono inserire sotto una sezione `environment:`.

## Persistenza e backup

`/config` contiene configurazione, log e stato di GDownloader; `/output` contiene i download. Ricreare il container con gli stessi mount conserva entrambi. Non montare la stessa cartella host nei due percorsi.

Per un backup coerente della configurazione, fermare il container e archiviare la cartella host:

```bash
docker stop gdownloader
tar -C /docker/appdata -czf gdownloader-config-backup.tgz gdownloader
docker start gdownloader
```

## Aggiornamento

L'aggiornamento manuale consiste nel modificare le versioni e i checksum in `versions.env`, ricostruire con `./scripts/build.sh` e ricreare il container usando gli stessi volumi. Prima dell'operazione fare un backup di `/config`.

La procedura tipica con Compose è:

```bash
./scripts/build.sh
docker compose up -d --force-recreate
```

L'assenza di auto-update è una limitazione intenzionale della prima versione: dipendenze e GDownloader restano riproducibili e cambiano solo con una nuova immagine.

## Sicurezza

Questa configurazione è pensata per essere esposta **solo nella rete locale**. La UI web non va pubblicata direttamente su Internet: il mapping predefinito ascolta su tutte le interfacce host e la base non abilita autenticazione per default. Per accesso remoto usare una VPN o un reverse proxy autenticato e protetto con TLS.

## Risoluzione dei problemi

- **Permessi:** verificare che UID/GID configurati possano scrivere nelle cartelle host di `/config` e `/output`. I log di avvio riportano chiaramente quale directory non è scrivibile.
- **Healthcheck:** eseguire `docker inspect --format '{{json .State.Health}}' gdownloader` e verificare che la porta interna `5800` risponda.
- **Log:** usare `docker logs gdownloader`; i log applicativi persistenti sono in `/config/logs/current.log`.
- **FFmpeg:** controllare con `docker exec gdownloader ffmpeg -version` e `docker exec gdownloader ffprobe -version`. La configurazione iniziale usa gli eseguibili di sistema inclusi nell'immagine.
- **UI non raggiungibile:** controllare `docker ps`, il mapping della porta e l'eventuale firewall del server.

## Sorgenti dei componenti inclusi

- [GDownloader 1.7.8](https://github.com/hstr0100/GDownloader/tree/v1.7.8)
- [yt-dlp 2026.07.04](https://github.com/yt-dlp/yt-dlp/tree/2026.07.04)
- [Deno 2.9.5](https://github.com/denoland/deno/tree/v2.9.5)
- [FFmpeg](https://ffmpeg.org/)
- [jlesage/baseimage-gui](https://github.com/jlesage/docker-baseimage-gui)

Le informazioni di licenza e redistribuzione sono in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). GDownloader è un progetto upstream di hstr0100; questo packaging Docker non è affiliato né supportato dal progetto originale.
