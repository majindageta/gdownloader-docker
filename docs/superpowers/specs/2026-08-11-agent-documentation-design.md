# Documentazione di progetto per agenti: specifica di design

Data: 11 agosto 2026  
Stato: approvato per la pianificazione

## 1. Obiettivo

Rendere il repository comprensibile e modificabile da agenti futuri senza obbligarli a ricostruire ogni volta decisioni, termini e procedure dal codice o dalla cronologia della conversazione.

La documentazione deve servire anche agli sviluppatori umani, ma mantiene due percorsi distinti:

- il `README.md` resta orientato all'installazione e alla gestione del container;
- `AGENTS.md` guida il lavoro sul repository e indirizza verso documenti specialistici.

## 2. Principi

La soluzione adotta un modello a router documentale. `AGENTS.md` contiene il contesto minimo che ogni agente deve conoscere e indica quale documento leggere in base all'attività. I dettagli non vengono duplicati nel router.

I principi vincolanti sono:

1. una sola fonte autorevole per ogni informazione;
2. documenti brevi, con responsabilità distinte;
3. italiano per le spiegazioni e nomi tecnici originali quando evitano ambiguità;
4. riferimenti ai file autorevoli al posto di valori duplicati soggetti a variazione;
5. verifiche automatiche per struttura, collegamenti e vincoli critici.

## 3. Struttura documentale

### 3.1 `AGENTS.md`

È il punto d'ingresso obbligatorio per gli agenti che lavorano nel repository. Deve contenere:

- scopo del progetto;
- vincoli non negoziabili;
- mappa sintetica dei file e delle responsabilità;
- tabella di instradamento verso i documenti specialistici;
- comandi minimi per build e test;
- regole per modifiche, verifica e commit;
- elenco delle decisioni che richiedono una nuova approvazione progettuale.

Non deve diventare un secondo manuale operativo né replicare l'intera architettura.

### 3.2 `docs/architecture.md`

Descrive il sistema implementato, non la sua storia. Deve coprire:

- provenienza degli artefatti e pipeline di build;
- contenuto dell'immagine;
- sequenza di inizializzazione e avvio;
- relazione tra noVNC, desktop virtuale e GUI Swing;
- gestione di `user.home` e stato applicativo;
- persistenza di `/config` e `/output`;
- health check, permessi e identità applicativa;
- confini intenzionali: amd64, rete locale, immagine fixed, nessun volume temp;
- dipendenze escluse e motivazione.

Il documento deve rimandare ai file di implementazione rilevanti senza copiare grandi porzioni di codice.

### 3.3 `docs/glossary.md`

Definisce il vocabolario condiviso del progetto. Ogni voce deve avere:

- termine canonico;
- definizione nel contesto di questo repository;
- eventuale distinzione da termini simili;
- collegamento al documento o file pertinente quando utile.

Il nucleo iniziale comprende almeno: upstream, immagine fixed, portable mode, base image jlesage, noVNC, desktop virtuale, bootstrap, config seed, stato persistente, bind mount, volume, `/config`, `/output`, eseguibile di sistema, pin, checksum SHA-256, image revision, health check e smoke test.

### 3.4 `docs/maintenance.md`

È la procedura tecnica per aggiornare i componenti inclusi. Deve trattare:

1. selezione esclusiva di release ufficiali;
2. individuazione degli artefatti `linux/amd64` corretti;
3. download e calcolo dei checksum SHA-256;
4. aggiornamento di `versions.env` come fonte autorevole;
5. revisione di licenze e `THIRD_PARTY_NOTICES.md`;
6. costruzione dell'immagine tramite `scripts/build.sh`;
7. esecuzione dei test statici e runtime;
8. accettazione GUI, download controllato e persistenza;
9. aggiornamento del tag e ricreazione del deployment senza perdere i mount;
10. strategia di rollback al tag precedente.

La procedura deve distinguere gli aggiornamenti di GDownloader, yt-dlp, Deno, FFmpeg e base jlesage, evidenziando i controlli specifici di ciascuno.

### 3.5 `README.md`

Resta rivolto all'operatore. Riceve una sezione breve, denominata `Documentazione del progetto`, che collega architettura, glossario, manutenzione e verbale di verifica. Non assorbe le nuove spiegazioni tecniche.

## 4. Fonti autorevoli

Per limitare la deriva documentale, ogni dato viene letto dalla fonte seguente:

| Informazione | Fonte autorevole |
| --- | --- |
| Versioni, revision e checksum | `versions.env` |
| Build e build argument | `scripts/build.sh`, `Dockerfile` |
| Configurazione iniziale | `defaults/config.json` |
| Inizializzazione dei mount | `rootfs/etc/cont-init.d/55-gdownloader.sh` |
| Preparazione dello stato | `rootfs/usr/local/lib/gdownloader/bootstrap.sh` |
| Avvio della GUI | `rootfs/startapp.sh` |
| Contratto di deployment | `compose.yaml` |
| Comportamento verificato | `tests/` e `docs/verification.md` |
| Licenze incluse | `LICENSE`, `THIRD_PARTY_NOTICES.md` |

I documenti possono mostrare esempi, ma devono indicare chiaramente quale file aggiornare quando un valore cambia.

## 5. Vincoli da preservare

`AGENTS.md` deve rendere immediatamente visibili i seguenti vincoli:

- target esclusivo `linux/amd64`;
- GUI Swing originale accessibile via browser attraverso noVNC;
- immagine fixed, aggiornata mediante rebuild e ricreazione;
- GDownloader, yt-dlp, Deno, FFmpeg e ffprobe inclusi;
- gallery-dl e spotDL non installati e disabilitati;
- soli mount persistenti `/config` e `/output`;
- porta interna web `5800`; porta VNC `5900` non pubblicata;
- utilizzo su rete locale fidata, senza autenticazione applicativa predefinita;
- nessuna sovrascrittura di un `config.json` valido già persistito;
- variabili d'ambiente opzionali e compatibili con i default jlesage;
- aggiornamenti automatici disabilitati.

ARM, auto-update nel container, autenticazione integrata, nuove dipendenze di download, ulteriori volumi o modifiche al codice Java upstream richiedono una nuova decisione progettuale esplicita.

## 6. Flusso di utilizzo da parte degli agenti

Un agente deve seguire questo percorso:

1. leggere `AGENTS.md`;
2. classificare l'attività;
3. aprire solo i documenti specialistici indicati dal router;
4. controllare i file autorevoli coinvolti;
5. modificare codice, test e documentazione insieme quando il contratto cambia;
6. eseguire la verifica proporzionata e poi `tests/run.sh` prima del completamento;
7. aggiornare i documenti soltanto se il comportamento o il vocabolario sono cambiati.

Il router deve evitare che un intervento operativo richieda la lettura della specifica storica o dell'intero piano originario.

## 7. Gestione degli errori documentali

Una modifica non deve essere considerata completa quando:

- introduce collegamenti locali non validi;
- duplica versioni o checksum fuori dalle fonti autorevoli senza motivo;
- contraddice i vincoli elencati in `AGENTS.md`;
- modifica un contratto senza aggiornare il documento specialistico pertinente;
- lascia placeholder, istruzioni non eseguibili o nomi di file inesistenti.

Quando il comportamento osservato differisce dalla documentazione, codice e test hanno valore diagnostico, ma la discrepanza deve essere risolta nello stesso cambiamento anziché essere ignorata.

## 8. Strategia di verifica

`tests/test-docs.sh` deve essere esteso per controllare almeno:

- presenza dei quattro nuovi punti di documentazione;
- collegamenti dal `README.md` verso i documenti specialistici;
- instradamento da `AGENTS.md` verso architettura, glossario e manutenzione;
- presenza in `AGENTS.md` dei vincoli amd64, `/config`, `/output`, porta `5800`, gallery-dl e spotDL;
- riferimento a `versions.env` come fonte autorevole nella manutenzione;
- presenza di build, checksum, test, persistenza e rollback nella procedura di aggiornamento;
- assenza di marcatori di lavoro incompleto nei nuovi documenti.

Dopo i test documentali deve essere eseguita l'intera suite `bash tests/run.sh`, perché la documentazione descrive anche contratti verificati dall'immagine.

## 9. Criteri di completamento

Il lavoro è completo quando:

- `AGENTS.md`, `docs/architecture.md`, `docs/glossary.md` e `docs/maintenance.md` esistono e hanno responsabilità non sovrapposte;
- il `README.md` collega correttamente la nuova documentazione;
- la procedura di manutenzione è eseguibile senza ricorrere alla cronologia della conversazione;
- un agente può individuare fonte autorevole, vincoli e test applicabili partendo solo da `AGENTS.md`;
- `tests/test-docs.sh`, `tests/run.sh` e `git diff --check` terminano con stato zero;
- il worktree è pulito dopo il commit.
