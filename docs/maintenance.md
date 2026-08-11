# Manutenzione e aggiornamenti

Questa procedura aggiorna i componenti dell'immagine senza introdurre auto-update nel container. [`versions.env`](../versions.env) è la fonte autorevole per pin, image revision e checksum: i comandi sotto leggono quel file e non duplicano versioni correnti nella documentazione.

## Ambito e prerequisiti

Servono Docker con supporto alla build `linux/amd64`, `curl`, Git e uno strumento SHA-256. Su Linux usare `sha256sum`; su macOS, se `sha256sum` non è installato, usare `shasum -a 256`.

Prima di iniziare:

1. creare una branch dedicata e verificare che il worktree sia pulito;
2. leggere [`AGENTS.md`](../AGENTS.md) e [`architecture.md`](architecture.md);
3. annotare il tag immagine attualmente in produzione;
4. assicurarsi che l'immagine precedente sia ancora disponibile localmente o nel registry;
5. fermare il container e fare un backup coerente della cartella host montata in `/config`;
6. non spostare, cancellare o riutilizzare per altri scopi la cartella host montata in `/output`.

Un aggiornamento non cambia il target: tutti gli artefatti devono restare compatibili con `linux/amd64`.

## Fonti ammesse

Usare soltanto release e distribuzioni ufficiali:

- [GDownloader releases](https://github.com/hstr0100/GDownloader/releases);
- [yt-dlp releases](https://github.com/yt-dlp/yt-dlp/releases);
- [Deno releases](https://github.com/denoland/deno/releases);
- [jlesage/docker-baseimage-gui releases](https://github.com/jlesage/docker-baseimage-gui/releases);
- repository Ubuntu configurati dalla base jlesage per FFmpeg e ffprobe.

Non sostituire questi artefatti con mirror non verificati. Prima di cambiare un URL, confrontarlo con il [`Dockerfile`](../Dockerfile) e controllare che il nome dell'asset sia ancora quello pubblicato dall'upstream.

## Preparare i nuovi pin

Caricare i valori correnti:

```bash
source versions.env
```

Scegliere una release stabile ufficiale per ciascun componente da aggiornare. Modificare soltanto le variabili pertinenti in `versions.env`, dopo aver scaricato e verificato l'asset corretto.

### GDownloader

L'asset previsto è lo ZIP portable amd64. Impostare temporaneamente `GDOWNLOADER_VERSION` alla release candidata oppure sostituire il valore nel comando:

```bash
curl -fL -o /tmp/gdownloader.zip \
  "https://github.com/hstr0100/GDownloader/releases/download/v${GDOWNLOADER_VERSION}/gdownloader-${GDOWNLOADER_VERSION}-linux_portable_amd64.zip"
sha256sum /tmp/gdownloader.zip
```

Aggiornare `GDOWNLOADER_VERSION` e `GDOWNLOADER_SHA256`. Prima della build ispezionare lo ZIP e verificare che esistano ancora:

- `bin/GDownloader`;
- `lib/runtime/portable.lock`;
- `lib/app/GDownloader.cfg`;
- l'icona `lib/GDownloader.png`.

Un cambiamento di questi percorsi richiede l'aggiornamento coordinato del Dockerfile e dei test. Controllare inoltre le release notes per cambiamenti al formato di configurazione o ai requisiti Java.

### yt-dlp

L'asset ammesso è il binario Linux standalone per x86_64:

```bash
curl -fL -o /tmp/yt-dlp_linux \
  "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux"
sha256sum /tmp/yt-dlp_linux
```

Aggiornare `YTDLP_VERSION` e `YTDLP_SHA256`. Dopo la build verificare che `/usr/local/bin/yt-dlp --version` restituisca esattamente la release scelta e che GDownloader registri l'eseguibile di sistema nei log.

### Deno

Usare esclusivamente l'archivio x86_64 GNU/Linux:

```bash
curl -fL -o /tmp/deno.zip \
  "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip"
sha256sum /tmp/deno.zip
```

Aggiornare `DENO_VERSION` e `DENO_SHA256`. Dopo la build controllare `deno --version` e verificare che il runtime riporti `x86_64-unknown-linux-gnu`.

### FFmpeg e ffprobe

FFmpeg e ffprobe non hanno un pin separato in `versions.env`: provengono dai pacchetti Ubuntu disponibili durante la build. La loro versione può cambiare aggiornando il tag `BASE_IMAGE` oppure quando i repository Ubuntu associati al tag forniscono un pacchetto diverso.

Dopo ogni rebuild verificare entrambi:

```bash
source versions.env
image_tag="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
docker run --rm --platform linux/amd64 --entrypoint ffmpeg "$image_tag" -version
docker run --rm --platform linux/amd64 --entrypoint ffprobe "$image_tag" -version
```

Controllare anche che GDownloader individui `/usr/bin/ffmpeg` e che un piccolo download con transcodifica completi correttamente.

### Base image jlesage

Aggiornare `BASE_IMAGE` soltanto a un tag ufficiale jlesage basato su una versione Ubuntu compatibile. Leggere le release notes della base e verificare in particolare:

- sistema di init e ordine degli script `cont-init.d`;
- disponibilità di `add-pkg`, `take-ownership` e `/opt/base/sbin/su-exec`;
- variabili `USER_ID`, `GROUP_ID`, `UMASK`, `TZ` e dimensioni display;
- Openbox, TigerVNC, noVNC, nginx e health check HTTP;
- comportamento della clipboard WebSocket/VNC.

Un cambio della base richiede sempre l'intera suite e l'accettazione GUI, anche se gli altri pin non cambiano.

## Image revision

`CONTAINER_REVISION` distingue revisioni del packaging che mantengono la stessa versione di GDownloader.

- Incrementarla per correzioni a Dockerfile, rootfs, configurazione o documentazione che richiedono una nuova immagine.
- Riportarla a `1` quando cambia `GDOWNLOADER_VERSION`, salvo una diversa convenzione approvata esplicitamente.
- Non usarla al posto dei pin di yt-dlp o Deno: quei componenti mantengono le proprie variabili di versione.

## Licenze e notice

Per ogni nuova release confrontare licenza, notice e componenti redistribuiti. Aggiornare [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) quando cambiano versione, provenienza, licenza o obblighi di attribuzione. Verificare che la licenza GDownloader distribuita in [`LICENSE`](../LICENSE) resti coerente con la release upstream.

Una build tecnicamente riuscita non sostituisce questo controllo di redistribuzione.

## Build

Prima stampare il comando canonico e controllare piattaforma, tag e build argument:

```bash
./scripts/build.sh --dry-run
```

Poi costruire l'immagine:

```bash
./scripts/build.sh
```

Ricavare il tag dai valori autorevoli e ispezionare l'immagine:

```bash
source versions.env
image_tag="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
docker image inspect "$image_tag" \
  --format '{{.Architecture}} {{json .Config.Healthcheck}}'
```

L'architettura deve essere `amd64` e il health check deve interrogare la porta interna `5800`.

## Verifiche obbligatorie

Eseguire prima i test mirati al componente cambiato, quindi la suite completa:

```bash
bash tests/run.sh
git diff --check
```

La verifica di rilascio deve inoltre osservare su un container fresco:

1. endpoint HTTP e stato `healthy`;
2. titolo e versione della GUI GDownloader;
3. assenza del welcome wizard;
4. download path `/output`;
5. aggiornamenti automatici, gallery-dl e spotDL disabilitati;
6. presenza e versione di yt-dlp, Deno, FFmpeg e ffprobe;
7. clipboard noVNC;
8. completamento di un piccolo download autorizzato;
9. ownership e scrivibilità dei file prodotti;
10. persistenza di impostazioni, cronologia e file dopo la ricreazione con gli stessi mount.

Aggiornare [`verification.md`](verification.md) con data, host, image ID, componenti e soli esiti realmente osservati.

## Deployment

Prima della ricreazione fare un nuovo backup di `/config`. Aggiornare il tag immagine in `compose.yaml`, nello stack Portainer o nel comando `docker run`, senza cambiare i percorsi host collegati a `/config` e `/output`.

Con Compose:

```bash
docker compose up -d --force-recreate
```

Verificare health, log e GUI prima di rimuovere l'immagine precedente. I dati persistenti non devono essere copiati dentro l'immagine né sostituiti durante il deploy.

## Rollback

Conservare il tag immagine precedente almeno fino alla fine della verifica. In caso di regressione:

1. fermare e rimuovere soltanto il nuovo container;
2. ripristinare il tag precedente nel comando o nello stack;
3. ricreare il container usando gli stessi mount `/config` e `/output`;
4. verificare health, GUI, cronologia e accesso ai download;
5. ripristinare il backup di `/config` soltanto se la nuova versione ne ha modificato il formato in modo incompatibile.

Non cancellare `/output` durante un rollback. Se occorre ripristinare `/config`, conservare prima una copia dello stato più recente per l'analisi.

## Chiusura dell'aggiornamento

Aggiornare README, notice, glossario o architettura soltanto quando il relativo contratto cambia. Committare insieme pin, checksum, test ed eventuale documentazione collegata. Prima della consegna controllare che il worktree sia pulito e che il nuovo tag sia ricostruibile partendo dal checkout.
