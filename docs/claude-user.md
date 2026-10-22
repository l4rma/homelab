# Oppgave: Sett opp en read-only bruker for Claude i homelab-klusteret

Jeg vil at du skal lage filene som trengs for at Claude Code skal ha lesetilgang til
Kubernetes-klusteret mitt via en egen ServiceAccount. Jeg kjører GitOps med Flux fra
dette repoet. Repoet skal være public, så ingen hemmeligheter skal i Git.

## Viktige regler for denne oppgaven

- Ikke gjør endringer i klusteret. Ingen kubectl apply, create, delete, patch,
  edit eller flux reconcile. Flux ruller ut endringene når jeg pusher.
- Du kan bruke lesekommandoer (kubectl get, flux get) for å forstå oppsettet.
- Ikke commit eller push. Jeg ser over og gjør det selv.
- kubeconfig-filer, tokens og age-nøkler skal aldri inn i repoet.

## Steg 1: Forstå repoet

Se på strukturen i repoet og finn ut:
- hvor Flux-entrypointene ligger (typisk clusters/<navn>/)
- hvordan infrastruktur er organisert (typisk infrastructure/ eller lignende)
- hvilken Flux Kustomization som synker infrastruktur

Bruk samme konvensjoner som resten av repoet. Hvis strukturen er uklar, spør meg
før du lager filer.

## Steg 2: RBAC-manifester

Lag en mappe for dette, for eksempel infrastructure/claude-readonly/, med en
kustomization.yaml og en rbac.yaml som inneholder:

1. Namespace: claude
2. ServiceAccount: claude-readonly i namespace claude
3. Secret av type kubernetes.io/service-account-token med annotasjonen
   kubernetes.io/service-account.name: claude-readonly
   (ingen data, Kubernetes fyller inn tokenet selv, så dette er trygt å committe)
4. ClusterRoleBinding claude-readonly-view som binder ServiceAccounten til den
   innebygde ClusterRolen "view" (gir lesetilgang uten secrets)
5. ClusterRole claude-readonly-extra med get/list/watch på:
   - core: nodes, persistentvolumes, namespaces
   - storage.k8s.io: storageclasses, volumeattachments, csidrivers
   - apiextensions.k8s.io: customresourcedefinitions
   - events.k8s.io: events
   - alle ressurser i Flux sine API-grupper: source.toolkit.fluxcd.io,
     kustomize.toolkit.fluxcd.io, helm.toolkit.fluxcd.io,
     notification.toolkit.fluxcd.io, image.toolkit.fluxcd.io
   - metrics.k8s.io: pods, nodes (kun get og list)
   Ikke gi tilgang til secrets.
6. ClusterRoleBinding claude-readonly-extra som binder ServiceAccounten til
   ClusterRolen over

Koble mappen inn der den hører hjemme slik at Flux faktisk synker den.

## Steg 3: Script for å lage kubeconfig

Lag scripts/create-claude-kubeconfig.sh som:
- bruker min admin-context (den heter "homelab") til å hente server-adresse,
  CA og token fra secreten claude-readonly-token i namespace claude
- skriver en kubeconfig til ~/.kube/claude-readonly.yaml med
  cluster "homelab", user "claude-readonly", context "claude@homelab"
- setter chmod 600 på filen
- feiler tydelig hvis secreten ikke finnes ennå (Flux har ikke synket)
- til slutt kjører en enkel test med den nye kubeconfigen:
  kubectl get nodes, og kubectl auth can-i get secrets -A (skal gi "no")
  og kubectl auth can-i delete pods -A (skal gi "no")

Gjør scriptet kjørbart.

## Steg 4: Claude Code-innstillinger

Lag .claude/settings.json (committes) med permissions:
- allow: kubectl get, describe, logs, top, events, explain, auth can-i,
  flux get, flux logs, flux tree, kustomize build
- deny: kubectl delete, apply, edit, patch, exec, config,
  flux reconcile, flux suspend, og lesing av ~/.kube/config

Sjekk hvilken syntaks for permission-regler din versjon av Claude Code bruker,
og bruk den.

Lag .claude/settings.local.json.example (committes) som viser hvordan man setter
env KUBECONFIG til full sti til ~/.kube/claude-readonly.yaml. Min hjemmemappe er
/home/larma.

Lag også selve .claude/settings.local.json med riktig sti, men den skal ikke
committes.

## Steg 5: .gitignore

Sørg for at .gitignore inneholder minst:
- .claude/settings.local.json
- *.agekey
- kubeconfig*
- *.kubeconfig
- .env

Ikke fjern noe som allerede står der.

## Steg 6: CLAUDE.md

Lag en CLAUDE.md i roten av repoet. Fyll inn det du finner ut fra repoet og fra
lesekommandoer mot klusteret (distribusjon, noder, struktur i repoet, hvilke apper
som kjører). Der du ikke vet, la det stå en tydelig plassholder jeg kan fylle inn.

Den skal inneholde:
- kort beskrivelse av homelabben (Proxmox, NAS, k8s, Flux; senere Crossplane og AWS)
- oversikt over klusteret og nodene
- struktur i repoet
- arbeidsregler for deg:
  - du har kun lesetilgang til klusteret
  - alle endringer gjøres i repoet, aldri direkte mot klusteret
  - lag en ny branch for endringer og forklar hva og hvorfor
  - kjør kustomize build på det du endrer før du sier deg ferdig
  - ingen hemmeligheter i klartekst, repoet er public
- feilsøkingstips: start med flux get all -A og
  kubectl get events -A --sort-by=.lastTimestamp

## Når du er ferdig

Gi meg en kort liste over filene du har laget eller endret, og stegene jeg må
gjøre selv i riktig rekkefølge:
1. se over endringene og commit/push
2. vente på at Flux synker (og hvordan jeg sjekker det)
3. kjøre scripts/create-claude-kubeconfig.sh
4. starte en ny Claude Code-sesjon så KUBECONFIG fra settings.local.json tas i bruk
5. hvordan jeg verifiserer at den nye sesjonen faktisk bruker claude-readonly
