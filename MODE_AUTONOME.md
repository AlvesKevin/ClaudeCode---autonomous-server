# 🤖 Mode Autonome - Guide Complet

Le mode autonome permet à Claude Code de gérer **complètement et automatiquement** votre serveur Debian/Ubuntu.

## 🎯 Qu'est-ce que le Mode Autonome ?

Contrairement au mode `--daily` qui se contente d'exécuter les projets existants, le **mode autonome** (`--autonomous`) permet à Claude de :

1. **Analyser** l'état complet du système (CPU, RAM, disque, sécurité, services)
2. **Décider** quels projets sont prioritaires aujourd'hui
3. **Créer** de nouveaux projets automatiquement
4. **Exécuter** les actions nécessaires
5. **Documenter** tout dans les journaux et contextes

## 🔄 Comment ça fonctionne ?

### Flux d'exécution quotidien

```
┌─────────────────────────────────────────────────────────┐
│  CRON: 0 0 * * * (Minuit chaque jour)                  │
│  ./run_agent.sh --autonomous                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  1. COLLECTE DES INFORMATIONS SYSTÈME                  │
│     - État CPU/RAM/Disque                              │
│     - Services actifs                                   │
│     - Logs de sécurité (SSH, auth)                     │
│     - Mises à jour disponibles                         │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  2. CHARGEMENT DES DIRECTIVES                          │
│     Fichier: config/system_directives.md               │
│     - Bonnes pratiques obligatoires                    │
│     - Exemples de projets                              │
│     - Permissions et restrictions                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  3. ANALYSE PAR CLAUDE CODE                            │
│     Prompt: État système + Directives + Contexte       │
│     Claude répond avec:                                │
│     - Analyse de l'état actuel                         │
│     - Problèmes détectés                               │
│     - 1-2 projets concrets proposés                    │
│     - Actions de maintenance recommandées              │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  4. CRÉATION AUTONOME DES PROJETS                      │
│     Claude crée automatiquement:                       │
│     - projects/nom_projet/                             │
│     - projects/nom_projet/context.md                   │
│     - projects/nom_projet/journal.log                  │
│     - projects/nom_projet/config.json                  │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  5. EXÉCUTION DES PROJETS                              │
│     Pour chaque projet (nouveau + existant):           │
│     - Lit le contexte du projet                        │
│     - Décide de la prochaine étape                     │
│     - Génère les commandes à exécuter                  │
│     - Documente le résultat                            │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  6. JOURNALISATION COMPLÈTE                            │
│     - logs/claude_agent.log                            │
│     - logs/autonomous_routine_YYYYMMDD.log             │
│     - logs/claude_system_analysis_YYYYMMDD.md          │
│     - projects/*/journal.log                           │
└─────────────────────────────────────────────────────────┘
```

## 📝 Exemple Concret

### Jour 1 - Premier lancement

```bash
$ ./run_agent.sh --autonomous

[INFO] Collection des informations système...
[INFO] Directives système chargées
[INFO] Consultation de Claude Code pour analyse autonome...

Claude détecte:
- Docker n'est pas installé
- SSH utilise le port 22 par défaut (risque sécurité)
- Pas de monitoring installé
- 15 mises à jour de sécurité disponibles

Claude propose:
1. Projet: installer_docker
2. Projet: securiser_ssh

[INFO] Création du projet autonome: installer_docker
[INFO] Création du projet autonome: securiser_ssh
[SUCCESS] Projets autonomes créés
```

**Résultat** :
- `projects/installer_docker/` créé avec contexte détaillé
- `projects/securiser_ssh/` créé avec plan d'action
- Analyse complète dans `logs/claude_system_analysis_20260104.md`

### Jour 2 - Suite des projets

```bash
Claude détecte:
- Projet "installer_docker" existe mais pas terminé
- Projet "securiser_ssh" existe mais pas terminé

Claude décide:
1. Compléter "installer_docker" en priorité
2. Puis "securiser_ssh"

[INFO] Travail autonome sur: installer_docker
[INFO] Session de travail générée avec commandes exactes à exécuter
```

## 🎯 Directives Système

Le fichier `config/system_directives.md` guide Claude sur :

### Ce qu'il PEUT faire :
- ✅ Installer des paquets (apt, snap, docker, etc.)
- ✅ Configurer des services (nginx, postgresql, etc.)
- ✅ Gérer le firewall (ufw)
- ✅ Créer des utilisateurs et permissions
- ✅ Déployer des applications
- ✅ Installer du monitoring

### Ce qu'il NE DOIT PAS faire :
- ❌ Supprimer des données sans confirmation
- ❌ Désactiver SSH
- ❌ Exposer des services sans sécurité
- ❌ Utiliser des mots de passe faibles

### Bonnes pratiques imposées :
- Toujours utiliser HTTPS en production
- Firewall activé par défaut
- Principe du moindre privilège
- Documentation obligatoire
- Sauvegarde avant modification critique

## 💡 Exemples de Projets Autonomes

Claude peut créer et gérer ces types de projets :

### Infrastructure
- Installation de Docker + Docker Compose
- Configuration du pare-feu (ufw)
- Installation de fail2ban
- Mise en place de monitoring (Netdata, Prometheus)

### Applications
- Serveur web Nginx avec SSL
- Base de données PostgreSQL/MySQL
- Cache Redis
- Reverse proxy Traefik

### Sécurité
- Durcissement SSH
- Certificats SSL Let's Encrypt
- VPN WireGuard
- Scans de sécurité automatiques

### DevOps
- CI/CD avec Gitea + Drone
- Registry Docker privé
- Stack de monitoring (Prometheus + Grafana)
- Sauvegardes automatisées

## 🔧 Utilisation

### Lancement manuel

```bash
# Test en mode autonome
./run_agent.sh --autonomous

# Voir les projets créés
./run_agent.sh --list

# Voir le statut
./run_agent.sh --status
```

### Automatisation (Cron)

Configuré lors de l'installation :

```bash
# Vérifier la tâche cron
crontab -l | grep claude

# Sortie attendue:
0 0 * * * /chemin/vers/run_agent.sh --autonomous >> /chemin/vers/logs/cron.log 2>&1
```

### Logs et résultats

```bash
# Log principal
tail -f logs/claude_agent.log

# Log de la routine autonome du jour
cat logs/autonomous_routine_$(date +%Y%m%d).log

# Analyse système du jour
cat logs/claude_system_analysis_$(date +%Y%m%d)*.md

# Journal d'un projet
tail -f projects/installer_docker/journal.log
```

## 🎨 Personnalisation

### Modifier les directives

Éditez `config/system_directives.md` pour :
- Ajouter vos propres projets
- Modifier les priorités
- Ajouter des contraintes spécifiques
- Définir votre stack technique préférée

### Exemples de personnalisation

```markdown
# Dans system_directives.md

## MES PRÉFÉRENCES

- Stack préférée: Node.js + PostgreSQL + Redis
- Toujours utiliser Docker Compose
- Préférer Traefik à Nginx
- Alertes via Slack (webhook: XXX)
```

Claude s'adaptera à vos préférences !

## 📊 Métriques et Monitoring

Claude documente automatiquement :

```json
// context_global.json (mise à jour automatique)
{
  "statistics": {
    "total_projects": 5,
    "active_projects": 3,
    "total_executions": 12
  },
  "projects": [
    {
      "name": "installer_docker",
      "active": true,
      "created_at": "2026-01-04T00:00:00Z",
      "last_updated": "2026-01-04T00:30:00Z"
    }
  ]
}
```

## 🔒 Sécurité

### L'agent est-il sûr ?

- ✅ **Isolation** : Utilise votre compte Claude Code (pas de clé API exposée)
- ✅ **Traçabilité** : Tout est journalisé (qui, quoi, quand, pourquoi)
- ✅ **Directives** : Suit strictement les règles définies
- ✅ **Révision** : Vous pouvez auditer toutes les actions

### Recommandations

1. **Lisez les analyses quotidiennes** dans `logs/`
2. **Vérifiez les projets créés** régulièrement
3. **Ajustez les directives** selon vos besoins
4. **Testez d'abord** sur un serveur de dev

## 🚀 Workflow Recommandé

### Semaine 1 - Observation

```bash
# Lancer manuellement et observer
./run_agent.sh --autonomous

# Lire l'analyse
cat logs/claude_system_analysis_*.md

# Vérifier les projets proposés
./run_agent.sh --list

# Lire les contextes
cat projects/*/context.md
```

### Semaine 2 - Activation automatique

```bash
# Vérifier que cron est configuré
crontab -l

# Le lendemain, vérifier les logs
cat logs/cron.log
```

### Semaine 3+ - Optimisation

- Ajuster `system_directives.md` selon vos retours
- Ajouter vos propres exemples de projets
- Définir des priorités personnalisées

## 🎯 Comparaison des Modes

| Caractéristique | Mode `--daily` | Mode `--autonomous` |
|----------------|----------------|---------------------|
| Analyse système | ❌ Non | ✅ Oui |
| Crée des projets | ❌ Non | ✅ Oui |
| Décide des priorités | ❌ Non | ✅ Oui |
| Suit les directives | ❌ Non | ✅ Oui |
| Installation d'outils | ❌ Non | ✅ Oui |
| Gestion de sécurité | ❌ Non | ✅ Oui |
| Documentation auto | ⚠️ Basique | ✅ Complète |
| **Recommandé pour** | Projets définis manuellement | Gestion autonome complète |

## 💬 FAQ

**Q: Claude peut-il casser mon serveur ?**
R: Non, il suit des directives strictes. De plus, tout est journalisé et réversible.

**Q: Combien ça coûte ?**
R: Utilise votre abonnement Claude Code CLI, pas d'API payante supplémentaire.

**Q: Puis-je désactiver certains types de projets ?**
R: Oui, modifiez `system_directives.md` pour restreindre.

**Q: Comment voir ce que Claude a fait cette nuit ?**
R: `cat logs/autonomous_routine_$(date +%Y%m%d).log`

**Q: Puis-je intervenir manuellement ?**
R: Oui, vous gardez le contrôle total. C'est un assistant, pas un remplaçant.

---

**Le mode autonome transforme votre serveur en système auto-géré et auto-améliorant !** 🚀
