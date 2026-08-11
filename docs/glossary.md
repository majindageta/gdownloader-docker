# Glossario

Questo documento definisce il vocabolario canonico del repository. Le definizioni riguardano questo packaging Docker e possono essere più specifiche dell'uso generale degli stessi termini.

## Upstream

Il progetto o distributore originale da cui proviene un artefatto. L'upstream dell'applicazione è [`hstr0100/GDownloader`](https://github.com/hstr0100/GDownloader); yt-dlp, Deno, jlesage e Ubuntu sono upstream distinti per i rispettivi componenti. Questo repository non è affiliato agli upstream e non modifica il codice Java di GDownloader.

## Immagine fixed

Un'immagine nella quale applicazione e dipendenze rimangono immutate fino a una nuova build. Non significa che il container sia immutabile nei dati: `/config` e `/output` continuano a essere persistenti. L'opposto, escluso dal progetto, sarebbe aggiornare componenti dentro un container già creato.

## Portable mode

La modalità della distribuzione upstream che conserva lo stato vicino all'applicazione ed è attivata dal file `portable.lock`. Il packaging rimuove quel file perché lo stato deve vivere in `/config`, separato dai binari dell'immagine.

## Base image jlesage

L'immagine Docker di base che fornisce sistema di init, utente `app`, Openbox, TigerVNC, noVNC e server HTTP. Questo progetto aggiunge GDownloader e le sue dipendenze sopra tale infrastruttura, senza reimplementare lo stack grafico.

## noVNC

Un client VNC HTML5 che funziona nel browser e comunica tramite WebSocket. In questo progetto trasmette la GUI Swing originale eseguita nel container; non è una UI web nativa né una riscrittura di GDownloader.

## Desktop virtuale

Il display X11 interno al container sul quale Openbox dispone e GDownloader disegna la propria finestra. TigerVNC cattura questo display e noVNC lo rende interattivo nel browser.

## Bootstrap

La preparazione eseguita prima dell'avvio dell'applicazione. Comprende controllo della scrivibilità dei mount, creazione o validazione della configurazione e verifica degli eseguibili richiesti. È implementata da [`55-gdownloader.sh`](../rootfs/etc/cont-init.d/55-gdownloader.sh) e [`bootstrap.sh`](../rootfs/usr/local/lib/gdownloader/bootstrap.sh).

## Config seed

La configurazione iniziale in [`defaults/config.json`](../defaults/config.json). Viene copiata in `/config/config.json` soltanto quando non esiste già una configurazione valida; non è un template riapplicato a ogni avvio.

## Stato persistente

I dati che sopravvivono alla rimozione e ricreazione del container. Per GDownloader comprendono configurazione, log, database e cronologia sotto `/config`, oltre ai file scaricati sotto `/output`.

## Bind mount

Un'associazione esplicita tra una cartella dell'host e un percorso nel container, per esempio `/docker/appdata/gdownloader:/config`. Proprietà e permessi dipendono dal filesystem host e dagli UID/GID usati nel container.

## Volume

Il termine Docker generale per storage persistente montato in un container. Può indicare un volume gestito da Docker oppure, in senso operativo, un bind mount. Il deployment di esempio usa bind mount perché l'operatore sceglie percorsi host espliciti.

## `/config`

La destinazione persistente per configurazione, log, database e cronologia di GDownloader. Il percorso interno `~/.gdownloader` viene reindirizzato qui. Un `config.json` valido già presente non deve essere sovrascritto.

## `/output`

La destinazione persistente dei file scaricati. Deve essere distinta da `/config` e scrivibile dall'utente applicativo. Non è una cartella temporanea.

## Eseguibile di sistema

Un programma già fornito dall'immagine e individuato tramite `PATH`. GDownloader è configurato per preferire gli eseguibili di sistema di yt-dlp, Deno e FFmpeg ai download gestiti internamente dall'applicazione.

## Pin

Una versione fissata esplicitamente in [`versions.env`](../versions.env), insieme al checksum quando il componente viene scaricato come artefatto. Il pin stabilisce quale release entra nella build; non identifica le revisioni del solo packaging.

## Checksum SHA-256

Il digest crittografico usato per verificare integrità e riproducibilità di un artefatto prima dell'installazione. I checksum attesi sono in `versions.env` e la build fallisce se i byte scaricati non corrispondono.

## Image revision

Il numero `CONTAINER_REVISION` che distingue revisioni del packaging costruite con la stessa versione di GDownloader. Insieme alla versione applicativa forma il tag dell'immagine, ma non sostituisce i pin dei singoli componenti.

## Health check

Il controllo periodico che richiede la pagina HTTP interna sulla porta `5800`. Dimostra che il servizio web risponde; non dimostra da solo che la GUI sia pronta, che gli strumenti esterni funzionino o che un download possa completarsi.

## Smoke test

Un test runtime breve che avvia un container reale e verifica il contratto essenziale: servizio HTTP, inizializzazione dell'applicazione, configurazione, identità, scrivibilità, persistenza e rifiuto di mount non validi. È più ampio di un health check e più circoscritto dell'accettazione GUI manuale.
