# Contesto per agenti

## Scopo

Questo repository costruisce un'immagine Docker non ufficiale, fixed e riproducibile di GDownloader. La GUI Swing originale viene resa accessibile dal browser tramite noVNC; non esiste una UI web alternativa sviluppata in questo progetto.

## Letture per attività

| Attività | Leggere prima |
| --- | --- |
| Modifiche a build, runtime, mount o GUI | `docs/architecture.md` |
| Terminologia o nomi dei componenti | `docs/glossary.md` |
| Aggiornamento di GDownloader o dipendenze | `docs/maintenance.md` |
| Evidenze dell'immagine corrente | `docs/verification.md` |
| Installazione Docker o Portainer | `README.md` |

Le specifiche e i piani in `docs/superpowers/` descrivono la storia progettuale. Non sostituiscono i documenti operativi sopra indicati.

## Vincoli non negoziabili

- Il target è esclusivamente `linux/amd64`; non aggiungere supporto ARM.
- La GUI Swing originale resta accessibile tramite noVNC sulla porta interna `5800`.
- L'immagine è fixed: gli aggiornamenti richiedono rebuild e ricreazione del container.
- I componenti inclusi sono GDownloader, yt-dlp, Deno, FFmpeg e ffprobe.
- gallery-dl e spotDL non devono essere installati e restano disabilitati.
- Persistono soltanto `/config` e `/output`; non aggiungere un volume temp.
- Non pubblicare la porta VNC `5900` per default.
- La UI senza autenticazione è destinata soltanto a una rete locale fidata.
- Non sovrascrivere un `/config/config.json` valido già esistente.
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
- `LICENSE` e `THIRD_PARTY_NOTICES.md`: licenze dei componenti distribuiti.

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
