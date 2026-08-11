# Architettura

## Obiettivo e perimetro

Il progetto impacchetta la release portable ufficiale di GDownloader in un'immagine Docker con desktop virtuale. Non compila né modifica il codice Java upstream e produce esclusivamente un'immagine `linux/amd64`. La GUI Swing originale viene mostrata nel browser: il container non sostituisce GDownloader con un frontend web.

L'immagine è fixed. Applicazione e dipendenze cambiano soltanto quando vengono aggiornati i pin, ricostruita l'immagine e ricreato il container.

## Pipeline di build

[`versions.env`](../versions.env) contiene base image, versioni, image revision e checksum SHA-256. [`scripts/build.sh`](../scripts/build.sh) valida che tutti i valori esistano, controlla il formato dei digest e invoca Docker con `--platform linux/amd64`. Il tag prodotto segue la forma `gdownloader-docker:<versione-gdownloader>-<image-revision>`.

Il [`Dockerfile`](../Dockerfile) parte dalla base GUI jlesage e installa gli artefatti nel modo seguente:

- scarica lo ZIP portable `linux_portable_amd64` dalla release ufficiale di GDownloader;
- installa il binario standalone `yt-dlp_linux` dalla release ufficiale di yt-dlp;
- estrae `deno-x86_64-unknown-linux-gnu.zip` dalla release ufficiale di Deno;
- installa FFmpeg e ffprobe dai pacchetti Ubuntu della base;
- verifica ogni artefatto scaricato tramite il digest indicato in `versions.env` prima di installarlo;
- registra le versioni effettive in `/opt/gdownloader/COMPONENTS`.

## Contenuto dell'immagine

La base jlesage fornisce il sistema di init, l'utente applicativo `app`, Openbox, TigerVNC, noVNC e il server HTTP. L'immagine aggiunge GDownloader, yt-dlp, Deno, FFmpeg, ffprobe, `curl`, `jq`, font, `unzip` e le librerie X11 richieste dalla GUI.

gallery-dl e spotDL non vengono installati. La configurazione iniziale li mantiene disabilitati, mentre GDownloader preferisce gli eseguibili di sistema inclusi per yt-dlp, Deno e FFmpeg.

## Sequenza di avvio

1. Il sistema di init jlesage prepara l'utente `app` e i servizi grafici.
2. [`55-gdownloader.sh`](../rootfs/etc/cont-init.d/55-gdownloader.sh) crea `/config` e `/output`, applica la gestione ownership della base e prova a scrivere in entrambi i percorsi come utente `app`.
3. Lo stesso script invoca `prepare_state` come utente `app` e controlla launcher, yt-dlp, Deno, FFmpeg e ffprobe.
4. [`startapp.sh`](../rootfs/startapp.sh) sostituisce il processo corrente con il launcher ufficiale `/opt/gdownloader/bin/GDownloader`.
5. Openbox seleziona la finestra principale tramite [`main-window-selection.xml`](../rootfs/etc/openbox/main-window-selection.xml).
6. TigerVNC espone il desktop virtuale a noVNC, mentre il server HTTP della base lo rende disponibile sulla porta `5800`.

Un mount non scrivibile o un eseguibile obbligatorio assente interrompe l'inizializzazione con un errore esplicito, prima dell'avvio della GUI.

## Stato applicativo

La release upstream è portable perché contiene `lib/runtime/portable.lock`. Durante la build quel file viene rimosso e a `GDownloader.cfg` viene aggiunta l'opzione Java `-Duser.home=/opt/gdownloader-home`.

`/opt/gdownloader-home/.gdownloader` è un collegamento simbolico a `/config`. Di conseguenza configurazione, log, database e cronologia vengono scritti nel mount persistente, senza modificare il codice Java upstream.

[`bootstrap.sh`](../rootfs/usr/local/lib/gdownloader/bootstrap.sh) usa [`defaults/config.json`](../defaults/config.json) come config seed soltanto quando `/config/config.json` non esiste. Un JSON valido esistente viene conservato byte per byte. Un file non valido viene rinominato con suffisso `config.json.corrupt-<timestamp>-<pid>` prima di applicare il seed.

## Persistenza

`/config` contiene configurazione, log, database e cronologia di GDownloader. `/output` contiene i file scaricati. I due percorsi devono essere mount distinti e scrivibili dall'identità configurata per l'utente `app`.

Non esiste un volume temp dedicato. Gli eventuali file temporanei dell'applicazione restano una responsabilità interna al container o a `/output`, secondo il comportamento di GDownloader.

La ricreazione del container conserva stato e download quando riutilizza gli stessi mount. Il seed iniziale non deve mai sovrascrivere una configurazione persistente valida.

## GUI e rete

Il percorso grafico è:

```text
browser HTTP -> noVNC/WebSocket -> TigerVNC -> desktop X11/Openbox -> GUI Swing
```

La sola porta applicativa pubblicata è `5800/tcp`. TigerVNC può ascoltare internamente sulla porta `5900`, ma questa porta non viene dichiarata né pubblicata dal packaging. Tastiera, puntatore e clipboard attraversano il protocollo VNC; il browser mostra la GUI nativa, non una sua replica HTML.

## Permessi e identità

La base jlesage crea l'utente `app` usando `USER_ID` e `GROUP_ID`, entrambi opzionali e con default `1000`. `UMASK` controlla i permessi dei nuovi file. Prima dell'avvio, l'init esegue una prova reale di creazione e rimozione file in `/config` e `/output` tramite `su-exec app`.

Su un host Docker Linux nativo l'ownership numerica dei bind mount corrisponde direttamente a UID e GID. Docker Desktop su macOS può rimappare l'ownership dei file preesistenti quando rimonta una cartella; per questo i test verificano sempre identità e scrivibilità e applicano alcune asserzioni numeriche soltanto su host Linux nativi.

## Health check

Il health check esegue una richiesta HTTP interna a `http://127.0.0.1:5800/`. Verifica che il servizio web noVNC risponda, con start period e retry adatti all'avvio della GUI. Non certifica che GDownloader abbia completato l'inizializzazione funzionale né che un download riesca.

## Rete e sicurezza

Il deployment predefinito usa HTTP senza autenticazione. È quindi adatto soltanto a una LAN fidata e non deve essere pubblicato direttamente su Internet. Per accesso remoto occorre una VPN oppure un reverse proxy con autenticazione e TLS.

Il [`compose.yaml`](../compose.yaml) pubblica soltanto `5800:5800`. Firewall, segmentazione della LAN e accesso al nodo Docker restano responsabilità dell'operatore.

## Confini intenzionali

- Immagine fixed senza auto-update nel container.
- Solo `linux/amd64`, senza variante ARM.
- Nessuna patch al codice Java upstream.
- Nessuna UI web nativa alternativa alla GUI Swing.
- Nessuna installazione di gallery-dl o spotDL.
- Nessun volume persistente oltre a `/config` e `/output`.
- Nessun volume temp dedicato.
- Nessuna pubblicazione predefinita della porta `5900`.
- Nessuna autenticazione integrata nel packaging iniziale.

Cambiare uno di questi confini richiede una decisione progettuale esplicita e l'aggiornamento coordinato di test e documentazione.

## Mappa dell'implementazione

| Percorso | Responsabilità |
| --- | --- |
| [`versions.env`](../versions.env) | Pin, image revision e SHA-256. |
| [`scripts/build.sh`](../scripts/build.sh) | Validazione dei pin e build canonica amd64. |
| [`Dockerfile`](../Dockerfile) | Assemblaggio e contratto dell'immagine. |
| [`defaults/config.json`](../defaults/config.json) | Config seed per il primo avvio. |
| [`55-gdownloader.sh`](../rootfs/etc/cont-init.d/55-gdownloader.sh) | Controlli dei mount e del runtime durante init. |
| [`bootstrap.sh`](../rootfs/usr/local/lib/gdownloader/bootstrap.sh) | Preparazione sicura dello stato persistente. |
| [`startapp.sh`](../rootfs/startapp.sh) | Avvio del launcher ufficiale. |
| [`compose.yaml`](../compose.yaml) | Deployment minimo per Docker e Portainer. |
| [`tests/`](../tests) | Contratti statici, immagine e smoke test runtime. |
| [`docs/verification.md`](verification.md) | Evidenze end-to-end raccolte sull'immagine. |
