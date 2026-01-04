# 🚀 Commandes Rapides - Workflow Claude Code

## 📋 Commandes Essentielles

### Installation
```bash
sudo ./setup.sh
```

### Aide
```bash
./run_agent.sh --help
```

### Statut
```bash
./run_agent.sh --status
```

---

## 🤖 Mode Autonome

### Lancer Immédiatement
```bash
./run_agent.sh --run-now
```
Lance Claude en mode autonome **maintenant** (sans attendre minuit).

Claude va :
1. Analyser l'état du système
2. Lire les demandes prioritaires
3. Décider quels projets faire
4. Créer et documenter tout

---

## 📝 Demander un Projet

### Ajouter une Demande Prioritaire
```bash
./run_agent.sh --request "Installer Docker et Docker Compose"
```

### Exemples de Demandes

```bash
# Infrastructure
./run_agent.sh --request "Installer Docker sur le serveur"
./run_agent.sh --request "Configurer le pare-feu ufw"
./run_agent.sh --request "Installer fail2ban pour sécuriser SSH"

# Applications
./run_agent.sh --request "Déployer nginx avec SSL"
./run_agent.sh --request "Installer PostgreSQL en Docker"
./run_agent.sh --request "Mettre en place Redis pour le cache"

# Sécurité
./run_agent.sh --request "Durcir la configuration SSH"
./run_agent.sh --request "Installer des certificats Let's Encrypt"
./run_agent.sh --request "Configurer un VPN WireGuard"

# Monitoring
./run_agent.sh --request "Installer Netdata pour le monitoring"
./run_agent.sh --request "Mettre en place Prometheus et Grafana"
./run_agent.sh --request "Configurer des alertes système"
```

### Workflow Recommandé

```bash
# 1. Faire une ou plusieurs demandes
./run_agent.sh --request "Installer Docker"
./run_agent.sh --request "Sécuriser SSH"

# 2. Lancer le mode autonome immédiatement
./run_agent.sh --run-now

# 3. Consulter les résultats
tail -f logs/claude_agent.log

# 4. Vérifier les projets créés
./run_agent.sh --list
```

---

## 📂 Gestion des Projets

### Créer un Projet Manuellement
```bash
./run_agent.sh --new mon_projet
```

### Lister les Projets
```bash
./run_agent.sh --list
```

### Traiter un Projet Spécifique
```bash
./run_agent.sh mon_projet
```

---

## 📊 Consultation des Résultats

### Voir les Logs Principaux
```bash
tail -f logs/claude_agent.log
```

### Voir l'Analyse Système du Jour
```bash
cat logs/claude_system_analysis_$(date +%Y%m%d)*.md
```

### Voir les Demandes en Attente
```bash
cat config/project_requests.json | jq '.requests[] | select(.status == "pending")'
```

### Journal d'un Projet
```bash
tail -f projects/installer_docker/journal.log
```

### Contexte d'un Projet
```bash
cat projects/installer_docker/context.md
```

---

## ⏰ Automatisation

### Vérifier la Tâche Cron
```bash
crontab -l | grep claude
```

### Logs de Cron
```bash
tail -f logs/cron.log
```

### Routine Autonome du Jour
```bash
cat logs/autonomous_routine_$(date +%Y%m%d).log
```

---

## 🎯 Scénarios d'Utilisation

### Scénario 1 : Nouveau Serveur
```bash
# Demander la configuration de base
./run_agent.sh --request "Installer Docker et Docker Compose"
./run_agent.sh --request "Configurer le firewall ufw avec règles de base"
./run_agent.sh --request "Sécuriser SSH (fail2ban, changement de port)"
./run_agent.sh --request "Installer monitoring Netdata"

# Lancer maintenant
./run_agent.sh --run-now
```

### Scénario 2 : Déployer une Application
```bash
# Demander les composants
./run_agent.sh --request "Installer nginx avec SSL Let's Encrypt"
./run_agent.sh --request "Déployer PostgreSQL 15 en Docker"
./run_agent.sh --request "Installer Redis pour le cache"

# Lancer
./run_agent.sh --run-now
```

### Scénario 3 : Amélioration Sécurité
```bash
# Audit et renforcement
./run_agent.sh --request "Faire un audit de sécurité complet"
./run_agent.sh --request "Mettre à jour tous les paquets système"
./run_agent.sh --request "Configurer des sauvegardes automatiques"

./run_agent.sh --run-now
```

### Scénario 4 : Mode Automatique (Laisser faire)
```bash
# Ne rien demander, juste laisser Claude analyser et décider
./run_agent.sh --run-now

# Ou attendre la tâche cron de minuit (automatique)
```

---

## 💡 Astuces

### Demandes Multiples en Une Fois
```bash
# Vous pouvez faire plusieurs demandes d'affilée
for req in "Installer Docker" "Configurer ufw" "Installer fail2ban"; do
    ./run_agent.sh --request "$req"
done

# Puis lancer une seule fois
./run_agent.sh --run-now
```

### Vérifier Avant de Lancer
```bash
# Voir les demandes en attente
cat config/project_requests.json | jq -r '.requests[] | select(.status == "pending") | .description'

# Si OK, lancer
./run_agent.sh --run-now
```

### Observer en Temps Réel
```bash
# Dans un terminal
./run_agent.sh --run-now

# Dans un autre terminal
tail -f logs/claude_agent.log
```

---

## 🔧 Dépannage

### Claude ne répond pas
```bash
# Vérifier l'authentification
./run_agent.sh --status

# Se ré-authentifier si nécessaire
claude auth login
```

### Voir les Erreurs
```bash
# Logs principaux
grep ERROR logs/claude_agent.log

# Logs cron
grep -i error logs/cron.log
```

### Réinitialiser les Demandes
```bash
# Vider toutes les demandes en attente
echo '{"requests": []}' > config/project_requests.json
```

---

## 📖 Documentation Complète

- **README.md** : Documentation complète
- **MODE_AUTONOME.md** : Guide du mode autonome
- **config/system_directives.md** : Directives pour Claude

---

**Résumé** : Pour utiliser rapidement le workflow autonome

1. **Faire des demandes** : `./run_agent.sh --request "..."`
2. **Lancer maintenant** : `./run_agent.sh --run-now`
3. **Consulter les résultats** : `tail -f logs/claude_agent.log`

C'est tout ! 🚀
