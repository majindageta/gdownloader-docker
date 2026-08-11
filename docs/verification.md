# Verifica end-to-end

Data della verifica: 11 agosto 2026.

## Ambiente

- Host: macOS `arm64` con Docker Desktop.
- Docker client/server: `20.10.22/arm64`.
- Immagine verificata: `gdownloader-docker:1.7.8-1`.
- Image ID: `sha256:585cae5dfaec8a42d46351e0e28bb0a20298a93c25ec71a1e50b3a5928e79f8b`.
- Architettura dichiarata dall'immagine: `amd64`.
- Architettura osservata nel container: `x86_64` (emulazione Docker Desktop).
- Health check configurato: richiesta HTTP a `127.0.0.1:5800`, intervallo 30 s, timeout 5 s, 3 tentativi, start period 30 s.

Il container è stato pubblicato esclusivamente su `127.0.0.1:5800` e avviato con due bind mount separati:

```text
/tmp/gdownloader-verification.9hjQEU/config -> /config
/tmp/gdownloader-verification.9hjQEU/output -> /output
```

I dati di verifica sono stati conservati nel percorso host indicato sopra; il container `gdownloader-verification` è stato rimosso al termine.

## Componenti osservati

Il file `/opt/gdownloader/COMPONENTS` nell'immagine riporta:

```text
GDownloader 1.7.8
2026.07.04
deno 2.9.5 (stable, release, x86_64-unknown-linux-gnu)
ffmpeg version 6.1.1-3ubuntu5 Copyright (c) 2000-2023 the FFmpeg developers
```

Durante l'avvio GDownloader ha individuato `/usr/local/bin/yt-dlp`, `/usr/local/bin/deno` e `/usr/bin/ffmpeg`. I log hanno inoltre confermato aggiornamenti automatici disabilitati e updater di gallery-dl e spotDL non supportati/assenti.

## Verifica della GUI

La GUI Swing originale è stata aperta in un browser tramite noVNC. Sono stati osservati:

- titolo `GDownloader v1.7.8`;
- assenza della procedura guidata iniziale;
- directory di download `/output`;
- aggiornamenti automatici disabilitati;
- gallery-dl e spotDL disabilitati;
- stato finale del download `Complete`.

È stata acquisita una schermata temporanea, non inclusa nel repository.

Il campo Clipboard di noVNC ha accettato il testo durante l'automazione, ma il passaggio alla clipboard X11 non è risultato osservabile con eventi sintetici del browser. Per completare il collaudo applicativo l'URL è stato quindi impostato nella clipboard X11 della stessa sessione e acquisito tramite il pulsante `+` della GUI. Questo punto resta da riconfermare manualmente con una normale operazione di incolla da un browser LAN; non viene registrato come esito positivo automatico.

## Download autorizzato

Il video yt-dlp indicato nel piano, `https://www.youtube.com/watch?v=BaW_jenozKc`, il giorno della verifica restituiva `Video unavailable` anche invocando direttamente la versione yt-dlp inclusa. Non è stato considerato un test superato.

Come alternativa autorizzata è stato generato con FFmpeg un media locale di due secondi, 320x180, pubblicato temporaneamente dal solo container all'URL:

```text
http://127.0.0.1:5800/verification-sample.mp4
```

L'URL è stato aggiunto e avviato dalla GUI. Il flusso ha attraversato gli stati `Queued`, `Transcoding` e `Complete`, producendo:

```text
/output/verification-sample (320kbps).mp3  83735 byte
/output/verification-sample (NA).mp4       26795 byte
```

Prima della ricreazione entrambi i file risultavano `uid=1000`, `gid=1000`, modalità `-rw-r--r--` dal container.

## Ricreazione e persistenza

Il container è stato fermato, rimosso e ricreato dalla stessa immagine usando gli stessi mount. Dopo il nuovo avvio sono stati osservati:

- endpoint HTTP nuovamente raggiungibile;
- stato Docker `running` e `healthy`;
- configurazione ancora impostata su `/output`, aggiornamenti automatici disabilitati, gallery-dl e spotDL disabilitati;
- log `Successfully restored 1 downloads`;
- voce completata nuovamente visibile nella GUI;
- entrambi i file ancora presenti in `/output` con le stesse dimensioni;
- utente applicativo `uid=1000(app) gid=1000(app)` e prova di scrittura in `/output` riuscita con file `1000:1000`.

Docker Desktop su macOS ha rimappato i due file preesistenti a `0:0` alla successiva esposizione del bind mount nel container. Directory persistenti e nuovi file creati come utente `app` risultavano invece `1000:1000`. Il test automatico applica per questo motivo l'asserzione numerica sui file persistiti soltanto su host Docker Linux nativi.

## Comandi verificati

I seguenti controlli hanno restituito stato 0 nell'ambiente descritto:

```text
curl -fsS http://127.0.0.1:5800/
docker inspect gdownloader-verification --format '{{.State.Health.Status}}'
docker exec gdownloader-verification jq -e . /config/config.json
docker exec gdownloader-verification /opt/base/sbin/su-exec app sh -c ': > /output/.recreate-write-test'
docker image inspect gdownloader-docker:1.7.8-1
```

La suite completa `bash tests/run.sh` è stata eseguita immediatamente prima del commit di questo documento ed è terminata con stato `0`. Il messaggio `Directory is not writable by app: /output` emesso in chiusura è l'esito atteso del caso negativo che verifica il rifiuto di un volume non scrivibile.
