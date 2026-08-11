# GDownloader Docker: specifica di design

Data: 2026-08-11  
Stato: design approvato

## 1. Obiettivo

Realizzare un'immagine Docker non ufficiale di GDownloader per server Linux
`amd64`, distribuibile anche con Portainer. La GUI Java Swing originale deve
essere utilizzabile da un browser nella rete locale tramite noVNC, seguendo il
modello di `jlesage/docker-jdownloader-2`.

L'immagine deve includere GDownloader, yt-dlp, Deno, FFmpeg e FFprobe. Lo stato
applicativo e i download devono sopravvivere alla ricreazione del container in
due volumi distinti.

## 2. Ambito

La prima versione comprende:

- piattaforma `linux/amd64`;
- release Linux portable ufficiale di GDownloader;
- GUI originale esposta via browser;
- yt-dlp come unico motore di download;
- Deno per il supporto richiesto da yt-dlp;
- FFmpeg e FFprobe per elaborazione e transcodifica;
- configurazione persistente in `/config`;
- download persistenti in `/output`;
- esempio Docker Compose compatibile con Portainer;
- esecuzione non root con UID, GID e umask configurabili;
- health check della UI web.

Sono esclusi dalla prima versione:

- architetture ARM;
- gallery-dl e spotDL;
- una nuova UI web nativa;
- HTTPS, autenticazione e pubblicazione su Internet;
- esposizione ordinaria della porta VNC;
- auto-aggiornamento delle dipendenze durante l'esecuzione;
- volume temporaneo separato;
- compilazione di GDownloader dal sorgente;
- modifiche al codice sorgente upstream di GDownloader.

## 3. Decisione architetturale

L'immagine runtime deriva dalla variante Ubuntu 24.04 della serie v4 di
`jlesage/baseimage-gui`. Una versione completa della base, non un tag mobile,
viene fissata nel Dockerfile di ogni release.

La base fornisce:

- server X virtuale;
- Openbox;
- TigerVNC;
- noVNC e server HTTP;
- supervisione dei processi;
- gestione di UID, GID, umask, locale e timezone.

Il progetto aggiunge:

- GDownloader sotto `/opt/gdownloader`;
- yt-dlp e Deno come eseguibili di sistema;
- FFmpeg e FFprobe;
- configurazione iniziale adatta al container;
- script di inizializzazione e avvio.

Il flusso principale è:

```text
browser nella LAN
  -> HTTP sulla porta pubblicata dall'host
  -> noVNC / TigerVNC / Openbox
  -> GUI Swing di GDownloader
  -> yt-dlp + Deno + FFmpeg
  -> /output
```

Non viene introdotta un'API remota di GDownloader.

## 4. Costruzione dell'immagine

La build scarica la ZIP Linux portable `amd64` dalla release ufficiale di
GDownloader e ne verifica il checksum. La release portable include il runtime
Java prodotto da `jpackage`, quindi nell'immagine finale non serve un JDK.

La modalità portable upstream scriverebbe lo stato accanto all'applicazione.
Durante la build viene rimosso il relativo indicatore `portable.lock`, così
`/opt/gdownloader` resta immutabile e lo stato può essere reindirizzato al
volume `/config`.

yt-dlp e Deno vengono scaricati in versioni esplicite e verificati con checksum.
FFmpeg e FFprobe vengono installati dalla distribuzione. La versione effettiva
di ogni componente viene registrata nei metadati o nella documentazione della
release dell'immagine.

Una build pubblicabile non usa URL `latest`. L'aggiornamento di un componente
richiede una modifica esplicita del repository e genera una nuova immagine.

## 5. Layout runtime

```text
/opt/gdownloader  applicazione e runtime Java immutabili
/config           configurazione, database, cronologia e log persistenti
/output           download, file parziali e cache persistenti
/tmp              file temporanei effimeri del container
```

La cache multimediale di GDownloader resta sotto `/output/tmp`, coerentemente
con il comportamento upstream. Non viene introdotto un mount `/temp`.

## 6. Inizializzazione e avvio

Prima di avviare la GUI, lo script di inizializzazione:

1. crea `/config` e `/output` se necessario;
2. applica la gestione dei permessi prevista dalla base jlesage;
3. verifica che entrambe le directory siano scrivibili dall'utente applicativo;
4. collega la directory di lavoro Linux di GDownloader al volume `/config`;
5. crea la configurazione iniziale solo quando non esiste;
6. verifica la presenza di GDownloader, yt-dlp, Deno, FFmpeg e FFprobe;
7. avvia il launcher ufficiale di GDownloader nel display virtuale.

Il collegamento fra `~/.gdownloader` e `/config` può essere realizzato dal
launcher tramite home JVM dedicata o link simbolico. La scelta implementativa
deve rispettare il contratto osservabile: nessuno stato persistente deve essere
scritto fuori da `/config`.

La configurazione iniziale imposta:

- `DownloadsPath` a `/output`;
- aggiornamenti automatici disabilitati;
- preferenza per gli eseguibili di sistema;
- gallery-dl disabilitato;
- spotDL disabilitato.

Una configurazione esistente non viene sovrascritta. Le migrazioni tra versioni
restano responsabilità di GDownloader.

Se `config.json` non è JSON valido, l'inizializzatore lo rinomina con un nome di
backup univoco e crea una nuova configurazione iniziale. Gli altri file presenti
in `/config` non vengono rimossi.

## 7. Aggiornamenti e immutabilità

L'unità di aggiornamento è l'immagine Docker:

```text
nuova release o nuove dipendenze
  -> nuova build e nuovo tag
  -> pull dell'immagine
  -> ricreazione del container
  -> riuso di /config e /output
```

GDownloader usa gli eseguibili forniti dall'immagine e non li aggiorna
automaticamente. Anche il self-update automatico di GDownloader è disabilitato
dalla configurazione iniziale.

Poiché non viene modificato il codice upstream, il comando manuale di controllo
aggiornamenti presente nella GUI può ancora forzare un aggiornamento. Questo è
un limite noto e documentato della prima versione. L'immutabilità è garantita
nel normale avvio e funzionamento, non contro un aggiornamento manuale richiesto
esplicitamente dall'utente.

## 8. Contratto Docker

Il deployment minimo documentato richiede:

- una porta host pubblicata verso `5800/tcp`;
- un volume persistente montato su `/config`;
- un volume persistente montato su `/output`.

Esempio:

```sh
docker run -d \
  --name=gdownloader \
  -p 5800:5800 \
  -v /docker/appdata/gdownloader:/config:rw \
  -v /home/user/Downloads:/output:rw \
  gdownloader
```

La porta host è liberamente sostituibile, per esempio `8080:5800`. La porta
interna rimane `5800/tcp`.

Docker consente l'avvio senza pubblicare la porta e può creare volumi anonimi
quando mancano bind mount espliciti. Il container non tenta di bloccare questi
casi: porta e due mapping sono requisiti operativi documentati, non controlli
artificialmente imposti all'avvio.

La porta `5900/tcp` non è pubblicata nel Compose predefinito.

## 9. Parametri runtime

Tutte le variabili d'ambiente sono opzionali. Vengono riutilizzati i parametri
standard della base jlesage:

| Variabile | Valore predefinito | Scopo |
| --- | --- | --- |
| `USER_ID` | `1000` | UID dell'utente applicativo |
| `GROUP_ID` | `1000` | GID dell'utente applicativo |
| `UMASK` | `0022` | Permessi predefiniti dei file creati |
| `TZ` | `Etc/UTC` | Timezone del container |
| `LANG` | `en_US.UTF-8` | Locale del container |
| `DISPLAY_WIDTH` | `1920` | Larghezza del desktop virtuale |
| `DISPLAY_HEIGHT` | `1080` | Altezza del desktop virtuale |

Le funzioni ulteriori della base jlesage non vengono ridefinite. La
documentazione iniziale espone soltanto i parametri utili al caso d'uso.

Non sono configurabili a runtime:

- percorsi interni `/config` e `/output`;
- versioni di GDownloader, yt-dlp, Deno e FFmpeg;
- abilitazione di gallery-dl e spotDL;
- auto-aggiornamento.

## 10. Sicurezza e rete

La prima versione è destinata esclusivamente a una rete locale fidata:

- HTTP senza TLS;
- autenticazione web disabilitata per impostazione iniziale;
- nessuna porta applicativa aggiuntiva;
- nessuna modalità host network;
- nessun privilegio Docker aggiuntivo richiesto;
- processo applicativo non root.

Il README deve avvertire esplicitamente di non pubblicare la UI su Internet. Un
deployment Internet-facing richiede un design successivo con HTTPS,
autenticazione e reverse proxy.

## 11. Gestione degli errori

- Se `/config` o `/output` non è scrivibile, l'avvio fallisce con un messaggio
  che identifica directory, UID e GID effettivi.
- Se un eseguibile richiesto manca o non è eseguibile, l'avvio fallisce prima
  di mostrare la GUI.
- Se `config.json` è corrotto, viene conservato come backup e rigenerato.
- Se la rete non è disponibile, la GUI può avviarsi; saranno i download a non
  funzionare.
- Se GDownloader termina, il supervisore e la policy Docker gestiscono il ciclo
  di vita senza lasciare processi orfani.
- Un arresto Docker invia il segnale al processo e attende la chiusura pulita
  prima di forzarlo.

## 12. Versionamento

I tag dell'immagine seguono lo schema:

```text
<versione-gdownloader>-<revisione-container>
```

Esempio: `1.7.8-1`.

La revisione container aumenta quando cambia il packaging o una dipendenza senza
che cambi la versione di GDownloader. Il tag `latest`, se pubblicato in futuro,
è soltanto un alias e non viene usato come input della build.

## 13. Struttura prevista del repository

```text
Dockerfile
compose.yaml
README.md
LICENSE
defaults/
  config.json
rootfs/
  startapp.sh
  etc/cont-init.d/
scripts/
docs/superpowers/specs/
```

Gli script in `scripts/` servono per controlli ripetibili di build e verifica,
non per sostituire il normale flusso Docker.

## 14. Strategia di verifica

Una release è accettabile quando supera tutti i controlli seguenti:

1. build riuscita per `linux/amd64`;
2. verifica dei checksum degli artefatti scaricati;
3. avvio con `/config` e `/output` vuoti;
4. health check della UI web positivo;
5. GUI Swing visibile e utilizzabile dal browser;
6. rilevamento delle versioni incluse di yt-dlp, Deno, FFmpeg e FFprobe;
7. assenza di gallery-dl e spotDL senza errori bloccanti;
8. download di un piccolo contenuto autorizzato;
9. risultato presente sotto `/output` con proprietà e permessi corretti;
10. ricreazione del container conservando configurazione, coda e cronologia;
11. avvio e scrittura con UID/GID non root;
12. nessun download di aggiornamenti durante un avvio normale;
13. arresto e riavvio puliti tramite Docker;
14. messaggio diagnostico corretto quando un volume non è scrivibile.

## 15. Criteri di completamento

Il primo rilascio è completato quando un utente può copiare il Compose di
esempio in Portainer, modificare porta e percorsi host, avviare il container,
aprire la GUI GDownloader dal browser e scaricare con yt-dlp in `/output`, senza
installare dipendenze sul server e conservando stato e download dopo la
ricreazione del container.
