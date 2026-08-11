# Agent Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aggiungere un router di contesto per agenti e documenti separati per architettura, vocabolario e manutenzione del progetto GDownloader Docker.

**Architecture:** `AGENTS.md` fornisce vincoli e instradamento, mentre tre documenti specialistici mantengono responsabilità distinte. `README.md` resta orientato all'operatore e collega il nuovo set; `tests/test-docs.sh` impedisce regressioni su presenza, collegamenti e contenuti critici.

**Tech Stack:** Markdown, Bash, `grep`, `rg`, Docker test suite esistente.

## Global Constraints

- Scrivere spiegazioni in italiano e conservare i nomi tecnici originali quando una traduzione sarebbe ambigua.
- Trattare `versions.env` come unica fonte autorevole per versioni, image revision e checksum.
- Non duplicare l'intera architettura o la procedura di manutenzione in `AGENTS.md`.
- Preservare il target esclusivo `linux/amd64`; non introdurre ARM.
- Preservare la GUI Swing originale accessibile via browser attraverso noVNC.
- Preservare l'immagine fixed, aggiornata tramite rebuild e ricreazione.
- Includere soltanto GDownloader, yt-dlp, Deno, FFmpeg e ffprobe; gallery-dl e spotDL restano assenti e disabilitati.
- Conservare soltanto i mount persistenti `/config` e `/output`; non introdurre un volume temp.
- Conservare la porta web interna `5800`; non pubblicare `5900` per default.
- Descrivere il deployment come adatto esclusivamente a una rete locale fidata, senza autenticazione predefinita.
- Non cambiare codice runtime, configurazione, versioni o dipendenze durante questo intervento documentale.
- Usare test-first, eseguire `git diff --check` prima di ogni commit e non lasciare marcatori di lavoro incompleto nei documenti finali.

---

## Planned File Map

- `AGENTS.md`: router obbligatorio per agenti, vincoli, fonti autorevoli e comandi.
- `docs/architecture.md`: descrizione del sistema implementato e dei suoi confini.
- `docs/glossary.md`: vocabolario canonico del progetto.
- `docs/maintenance.md`: procedura riproducibile per aggiornamenti e rollback.
- `README.md`: collegamenti per sviluppatori e agenti, senza duplicare i contenuti.
- `tests/test-docs.sh`: contratto automatico della documentazione.

---

### Task 1: Router per agenti e architettura

**Files:**
- Create: `AGENTS.md`
- Create: `docs/architecture.md`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: struttura corrente del repository, vincoli della specifica e comandi già presenti in `tests/run.sh` e `scripts/build.sh`.
- Produces: punto d'ingresso `AGENTS.md` e fonte architetturale `docs/architecture.md` usati dai task successivi.

- [ ] **Step 1: Aggiungere il contratto documentale iniziale**

Appendere a `tests/test-docs.sh`:

```bash
for file in AGENTS.md docs/architecture.md; do
  [[ -s "$repo_dir/$file" ]] || { echo "Missing agent documentation: $file" >&2; exit 1; }
done

for reference in docs/architecture.md docs/glossary.md docs/maintenance.md docs/verification.md; do
  grep -F "$reference" "$repo_dir/AGENTS.md"
done

for constraint in linux/amd64 noVNC /config /output 5800 gallery-dl spotDL versions.env tests/run.sh; do
  grep -F "$constraint" "$repo_dir/AGENTS.md"
done

for heading in 'Pipeline di build' 'Sequenza di avvio' 'Persistenza' 'Rete e sicurezza' 'Confini intenzionali'; do
  grep -F "## $heading" "$repo_dir/docs/architecture.md"
done
```

- [ ] **Step 2: Verificare il fallimento atteso**

Run: `bash tests/test-docs.sh`

Expected: FAIL con `Missing agent documentation: AGENTS.md`.

- [ ] **Step 3: Creare `AGENTS.md`**

Creare un documento conciso con questa struttura e questi contenuti vincolanti:

```markdown
# Contesto per agenti

## Scopo

Questo repository costruisce un'immagine Docker non ufficiale, fixed e riproducibile di GDownloader. La GUI Swing originale viene resa accessibile via browser tramite noVNC.

## Letture per attività

| Attività | Leggere prima |
| --- | --- |
| Modifiche a build, runtime, mount o GUI | `docs/architecture.md` |
| Terminologia o nomi dei componenti | `docs/glossary.md` |
| Aggiornamento di GDownloader o dipendenze | `docs/maintenance.md` |
| Evidenze dell'immagine corrente | `docs/verification.md` |
| Installazione Docker o Portainer | `README.md` |

Le specifiche e i piani in `docs/superpowers/` descrivono la storia progettuale; non sostituiscono i documenti operativi sopra indicati.

## Vincoli non negoziabili

- Target esclusivo `linux/amd64`; nessun supporto ARM.
- GUI Swing originale attraverso noVNC sulla porta interna `5800`.
- Immagine fixed: gli aggiornamenti richiedono rebuild e ricreazione.
- Componenti inclusi: GDownloader, yt-dlp, Deno, FFmpeg e ffprobe.
- gallery-dl e spotDL non devono essere installati e restano disabilitati.
- Persistono soltanto `/config` e `/output`; non aggiungere un volume temp.
- Non pubblicare la porta VNC `5900` per default.
- La UI senza autenticazione è destinata soltanto a una rete locale fidata.
- Non sovrascrivere un `/config/config.json` valido esistente.
- Gli aggiornamenti automatici restano disabilitati.
- Le variabili runtime restano opzionali e compatibili con i default jlesage.

ARM, auto-update nel container, autenticazione integrata, nuovi downloader, ulteriori volumi o patch al codice Java upstream richiedono una nuova decisione progettuale esplicita.

## Fonti autorevoli

- `versions.env`: versioni, image revision e checksum.
- `Dockerfile` e `scripts/build.sh`: composizione e build dell'immagine.
- `defaults/config.json`: configurazione iniziale.
- `rootfs/etc/cont-init.d/55-gdownloader.sh`: inizializzazione dei mount.
- `rootfs/usr/local/lib/gdownloader/bootstrap.sh`: preparazione dello stato.
- `rootfs/startapp.sh`: avvio della GUI.
- `compose.yaml`: contratto minimo di deployment.
- `tests/` e `docs/verification.md`: comportamento verificato.

## Flusso di lavoro

1. Leggere questo file e il documento specialistico pertinente.
2. Controllare i file autorevoli prima di modificare esempi o spiegazioni.
3. Scrivere o aggiornare prima il test che rappresenta il contratto modificato.
4. Preservare le modifiche dell'utente e limitare il cambiamento allo scopo richiesto.
5. Eseguire il test mirato, poi `bash tests/run.sh` prima di dichiarare il lavoro completo.
6. Eseguire `git diff --check` e controllare `git status --short` prima del commit.

## Comandi essenziali

```bash
./scripts/build.sh --dry-run
./scripts/build.sh
bash tests/test-docs.sh
bash tests/run.sh
git diff --check
```
```

- [ ] **Step 4: Creare `docs/architecture.md`**

Creare il documento con le sezioni seguenti e descrivere il comportamento corrente:

```markdown
# Architettura

## Obiettivo e perimetro

L'immagine impacchetta la release portable ufficiale di GDownloader sulla base GUI jlesage. Non compila né modifica il codice Java upstream e produce esclusivamente un'immagine `linux/amd64`.

## Pipeline di build

`versions.env` contiene pin e SHA-256. `scripts/build.sh` valida i valori e invoca Docker con `--platform linux/amd64`. Il `Dockerfile` scarica gli artefatti ufficiali, verifica i checksum prima dell'installazione, installa i pacchetti Ubuntu e registra le versioni in `/opt/gdownloader/COMPONENTS`.

Documentare separatamente GDownloader portable, binario standalone yt-dlp, archivio Deno amd64 e FFmpeg/ffprobe provenienti da Ubuntu.

## Contenuto dell'immagine

Elencare la base jlesage/noVNC, GDownloader, yt-dlp, Deno, FFmpeg/ffprobe, `jq`, font e librerie X11. Spiegare che gallery-dl e spotDL non sono installati.

## Sequenza di avvio

Descrivere nell'ordine: init jlesage, `55-gdownloader.sh`, verifica scrivibilità come utente `app`, `prepare_state`, controllo degli eseguibili, `startapp.sh`, desktop Openbox, GUI Swing e servizio HTTP noVNC.

## Stato applicativo

Spiegare la rimozione di `portable.lock`, l'opzione Java `-Duser.home=/opt/gdownloader-home` e il collegamento `/opt/gdownloader-home/.gdownloader -> /config`. Descrivere il seed iniziale, la conservazione di un JSON valido e il backup di una configurazione corrotta.

## Persistenza

Definire `/config` come configurazione, log, database e cronologia; `/output` come destinazione dei download. Chiarire che non esiste un volume temp e che i bind mount devono restare separati.

## GUI e rete

Descrivere il percorso browser HTTP -> noVNC/WebSocket -> TigerVNC/Openbox -> GUI Swing. La sola porta pubblicata è `5800`; `5900` resta interna. Clipboard e input vengono trasportati dal protocollo VNC.

## Permessi e identità

Descrivere `USER_ID`, `GROUP_ID`, `UMASK`, l'utente `app`, i controlli di scrittura all'avvio e la differenza di ownership osservabile con bind mount Docker Desktop rispetto a Linux nativo.

## Health check

Descrivere la richiesta HTTP interna a `127.0.0.1:5800`, il suo scopo e il fatto che non certifica il successo di un download.

## Rete e sicurezza

Indicare che HTTP senza autenticazione è accettabile soltanto su LAN fidata; per accesso remoto servono VPN oppure reverse proxy con autenticazione e TLS.

## Confini intenzionali

Ribadire immagine fixed, amd64, nessun auto-update, nessun ARM, nessun volume temp, nessuna porta 5900 pubblicata, nessuna patch Java upstream e nessuna dipendenza gallery-dl/spotDL.

## Mappa dell'implementazione

Collegare `versions.env`, `scripts/build.sh`, `Dockerfile`, `defaults/config.json`, i tre script sotto `rootfs/`, `compose.yaml`, `tests/` e `docs/verification.md`, specificando in una frase la responsabilità di ciascuno.
```

Trasformare le indicazioni interne di ogni sezione in prosa definitiva; non lasciare frasi imperative o note redazionali.

- [ ] **Step 5: Verificare i documenti**

Run:

```bash
bash tests/test-docs.sh
git diff --check
```

Expected: entrambi stato 0.

- [ ] **Step 6: Commit**

```bash
git add AGENTS.md docs/architecture.md tests/test-docs.sh
git commit -m "docs: add agent context and architecture guide"
```

---

### Task 2: Glossario canonico

**Files:**
- Create: `docs/glossary.md`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: termini e confini definiti da `AGENTS.md` e `docs/architecture.md`.
- Produces: definizioni canoniche richiamabili da agenti, manutentori e documenti futuri.

- [ ] **Step 1: Aggiungere il test del vocabolario**

Appendere a `tests/test-docs.sh`:

```bash
[[ -s "$repo_dir/docs/glossary.md" ]] || { echo 'Missing docs/glossary.md' >&2; exit 1; }
for term in \
  '## Upstream' \
  '## Immagine fixed' \
  '## Portable mode' \
  '## Base image jlesage' \
  '## noVNC' \
  '## Desktop virtuale' \
  '## Bootstrap' \
  '## Config seed' \
  '## Stato persistente' \
  '## Bind mount' \
  '## Volume' \
  '## `/config`' \
  '## `/output`' \
  '## Eseguibile di sistema' \
  '## Pin' \
  '## Checksum SHA-256' \
  '## Image revision' \
  '## Health check' \
  '## Smoke test'; do
  grep -F "$term" "$repo_dir/docs/glossary.md"
done
```

- [ ] **Step 2: Verificare il fallimento atteso**

Run: `bash tests/test-docs.sh`

Expected: FAIL con `Missing docs/glossary.md`.

- [ ] **Step 3: Creare `docs/glossary.md`**

Creare `# Glossario` e una sezione `##` per ciascun termine del test. Usare queste definizioni, espandendole solo con collegamenti pertinenti:

| Termine | Definizione obbligatoria |
| --- | --- |
| Upstream | Progetto o distributore originale da cui proviene un artefatto; per GDownloader è `hstr0100/GDownloader`. |
| Immagine fixed | Immagine in cui applicazione e dipendenze restano immutate fino a una nuova build. |
| Portable mode | Modalità upstream attivata da `portable.lock`; viene rimossa perché lo stato deve vivere in `/config`. |
| Base image jlesage | Immagine che fornisce init, utente `app`, Openbox, TigerVNC, noVNC e server HTTP. |
| noVNC | Client VNC HTML5 accessibile dal browser; non è una riscrittura web di GDownloader. |
| Desktop virtuale | Display X11 nel container sul quale viene eseguita la GUI Swing. |
| Bootstrap | Preparazione e validazione di mount, config ed eseguibili prima dell'avvio. |
| Config seed | `defaults/config.json` copiato solo quando una configurazione persistente valida non esiste. |
| Stato persistente | Configurazione, log, database e cronologia conservati oltre la vita del container. |
| Bind mount | Associazione esplicita tra cartella host e percorso container. |
| Volume | Termine Docker generale per storage persistente; non implica necessariamente un bind mount. |
| `/config` | Destinazione persistente dello stato GDownloader. |
| `/output` | Destinazione persistente dei file scaricati. |
| Eseguibile di sistema | Programma fornito nell'immagine e trovato tramite `PATH`, preferito a un download interno dell'app. |
| Pin | Valore di versione fissato in `versions.env`. |
| Checksum SHA-256 | Digest verificato prima dell'installazione per garantire integrità e riproducibilità. |
| Image revision | Numero che distingue revisioni del packaging con la stessa versione GDownloader. |
| Health check | Controllo HTTP della raggiungibilità del servizio web interno. |
| Smoke test | Test runtime breve che avvia un container e verifica il contratto essenziale. |

Ogni definizione deve spiegare il termine nel contesto del repository e distinguere almeno `bind mount` da `volume`, `noVNC` da una UI web nativa, `health check` da un download funzionale e `pin` da `image revision`.

- [ ] **Step 4: Verificare e committare**

Run:

```bash
bash tests/test-docs.sh
git diff --check
```

Expected: entrambi stato 0.

Commit:

```bash
git add docs/glossary.md tests/test-docs.sh
git commit -m "docs: add project glossary"
```

---

### Task 3: Procedura di manutenzione e indice README

**Files:**
- Create: `docs/maintenance.md`
- Modify: `README.md`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: `versions.env`, URL nel `Dockerfile`, `scripts/build.sh`, suite `tests/run.sh` e contratto di persistenza.
- Produces: procedura completa di aggiornamento/rollback e collegamenti pubblici dal README.

- [ ] **Step 1: Aggiungere i test per manutenzione e collegamenti**

Appendere a `tests/test-docs.sh`:

```bash
[[ -s "$repo_dir/docs/maintenance.md" ]] || { echo 'Missing docs/maintenance.md' >&2; exit 1; }

for reference in \
  'docs/architecture.md' \
  'docs/glossary.md' \
  'docs/maintenance.md' \
  'docs/verification.md'; do
  grep -F "$reference" "$repo_dir/README.md"
done

for requirement in \
  versions.env \
  linux/amd64 \
  sha256sum \
  scripts/build.sh \
  tests/run.sh \
  THIRD_PARTY_NOTICES.md \
  /config \
  /output \
  rollback; do
  grep -Fi "$requirement" "$repo_dir/docs/maintenance.md"
done

for component in GDownloader yt-dlp Deno FFmpeg jlesage; do
  grep -F "$component" "$repo_dir/docs/maintenance.md"
done

for file in AGENTS.md docs/architecture.md docs/glossary.md docs/maintenance.md; do
  if rg -n '\b(TO[D]O|TB[D]|FIX[M]E)\b' "$repo_dir/$file"; then
    echo "Incomplete marker found in $file" >&2
    exit 1
  fi
done
```

- [ ] **Step 2: Verificare il fallimento atteso**

Run: `bash tests/test-docs.sh`

Expected: FAIL con `Missing docs/maintenance.md`.

- [ ] **Step 3: Creare la procedura di manutenzione**

Creare `docs/maintenance.md` con questa sequenza eseguibile:

1. **Ambito e prerequisiti:** Docker con build `linux/amd64`, `curl`, `sha256sum` (oppure `shasum -a 256` su macOS), worktree pulito, backup di `/config`, nessuna modifica ai dati in `/output`.
2. **Fonti ufficiali:** release GitHub di GDownloader, yt-dlp e Deno; tag jlesage per la base; pacchetti Ubuntu per FFmpeg. Vietare mirror non verificati.
3. **Preparazione:** creare una branch dedicata, leggere `versions.env`, annotare tag immagine corrente e costruire l'immagine precedente prima di cambiare i pin se non è già disponibile.
4. **GDownloader:** scaricare `gdownloader-${version}-linux_portable_amd64.zip`, calcolare SHA-256, aggiornare `GDOWNLOADER_VERSION` e `GDOWNLOADER_SHA256`, controllare nome del launcher e struttura `lib/runtime`/`lib/app`.
5. **yt-dlp:** scaricare `yt-dlp_linux`, calcolare SHA-256, aggiornare `YTDLP_VERSION` e `YTDLP_SHA256`, verificare `yt-dlp --version` nel container.
6. **Deno:** scaricare `deno-x86_64-unknown-linux-gnu.zip`, calcolare SHA-256, aggiornare `DENO_VERSION` e `DENO_SHA256`, verificare `deno --version` e architettura x86_64.
7. **FFmpeg e base:** spiegare che FFmpeg arriva da Ubuntu; aggiornare `BASE_IMAGE` soltanto a un tag jlesage Ubuntu compatibile, quindi verificare versioni di `ffmpeg` e `ffprobe`, init script e noVNC.
8. **Revision:** incrementare `CONTAINER_REVISION` per sole modifiche al packaging; riportarla a `1` quando cambia GDownloader, salvo una diversa convenzione esplicitamente approvata.
9. **Licenze:** confrontare licenze e dipendenze distribuite e aggiornare `THIRD_PARTY_NOTICES.md` se release, licenza o provenienza cambiano.
10. **Build:** eseguire `./scripts/build.sh --dry-run`, controllare tag e build argument, poi `./scripts/build.sh`.
11. **Verifiche:** eseguire `bash tests/run.sh`, `git diff --check`, ispezionare architettura e health check, aprire la GUI, controllare versione/impostazioni, completare un piccolo download autorizzato e ricreare il container con gli stessi mount.
12. **Deployment:** eseguire backup di `/config`, aggiornare il tag in Compose/Portainer e ricreare senza cambiare i percorsi host di `/config` e `/output`.
13. **Rollback:** fermare il nuovo container, ripristinare il tag immagine precedente e ricreare con gli stessi mount; ripristinare il backup di `/config` soltanto se la nuova versione ne ha modificato il formato in modo incompatibile.
14. **Chiusura:** aggiornare README, verbale di verifica e notice quando necessario, quindi committare pin, documentazione e test insieme.

Includere questi comandi concreti, usando variabili con nomi specifici del task e senza sovrascrivere `HOME`:

```bash
source versions.env
curl -fL -o /tmp/gdownloader.zip \
  "https://github.com/hstr0100/GDownloader/releases/download/v${GDOWNLOADER_VERSION}/gdownloader-${GDOWNLOADER_VERSION}-linux_portable_amd64.zip"
sha256sum /tmp/gdownloader.zip

curl -fL -o /tmp/yt-dlp_linux \
  "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux"
sha256sum /tmp/yt-dlp_linux

curl -fL -o /tmp/deno.zip \
  "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip"
sha256sum /tmp/deno.zip

./scripts/build.sh --dry-run
./scripts/build.sh
bash tests/run.sh
git diff --check
docker image inspect "gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}" \
  --format '{{.Architecture}} {{json .Config.Healthcheck}}'
```

Specificare che i valori nel documento sono esempi derivati da `versions.env`, non pin duplicati da aggiornare manualmente.

- [ ] **Step 4: Collegare la documentazione dal README**

Inserire dopo l'introduzione del `README.md`:

```markdown
## Documentazione del progetto

- [Architettura](docs/architecture.md): build, avvio, GUI, persistenza e confini del sistema.
- [Glossario](docs/glossary.md): vocabolario canonico usato nel repository.
- [Manutenzione](docs/maintenance.md): aggiornamento di componenti, checksum, test, deployment e rollback.
- [Verifica end-to-end](docs/verification.md): evidenze raccolte sull'immagine corrente.

Gli agenti che modificano il repository devono iniziare da [AGENTS.md](AGENTS.md).
```

- [ ] **Step 5: Verificare il task**

Run:

```bash
bash tests/test-docs.sh
git diff --check
```

Expected: entrambi stato 0 e nessun marcatore di lavoro incompleto.

- [ ] **Step 6: Commit**

```bash
git add docs/maintenance.md README.md tests/test-docs.sh
git commit -m "docs: add component maintenance workflow"
```

---

### Task 4: Audit finale della documentazione

**Files:**
- Verify: `AGENTS.md`
- Verify: `docs/architecture.md`
- Verify: `docs/glossary.md`
- Verify: `docs/maintenance.md`
- Verify: `README.md`
- Verify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: tutti i documenti e test prodotti nei task precedenti.
- Produces: evidenza conclusiva di coerenza, collegamenti validi e suite verde.

- [ ] **Step 1: Controllare i file autorevoli citati**

Run:

```bash
for file in \
  versions.env \
  scripts/build.sh \
  Dockerfile \
  defaults/config.json \
  rootfs/etc/cont-init.d/55-gdownloader.sh \
  rootfs/usr/local/lib/gdownloader/bootstrap.sh \
  rootfs/startapp.sh \
  compose.yaml \
  docs/verification.md; do
  test -e "$file" || exit 1
done
```

Expected: stato 0.

- [ ] **Step 2: Eseguire il test documentale in modo isolato**

Run: `bash tests/test-docs.sh`

Expected: stato 0.

- [ ] **Step 3: Eseguire la suite completa**

Run: `bash tests/run.sh`

Expected: stato 0; il messaggio del caso negativo per `/output` non scrivibile è previsto dal test smoke.

- [ ] **Step 4: Controllare qualità e stato Git**

Run:

```bash
git diff --check
git status --short --branch
git log --oneline -4
```

Expected: nessun diff non committato, branch `feat/gdownloader-docker` pulita e tre commit documentali nuovi dopo il commit della specifica.

- [ ] **Step 5: Confermare la leggibilità dal solo router**

Partendo da `AGENTS.md`, verificare manualmente che siano individuabili senza consultare la cronologia:

- fonte delle versioni e dei checksum;
- documento da usare per un aggiornamento;
- documento da usare per comprendere bootstrap e persistenza;
- definizione di immagine fixed e portable mode;
- comando del test completo;
- cambiamenti che richiedono una nuova decisione progettuale.

Expected: tutti e sei i punti hanno un riferimento diretto e non ambiguo.
