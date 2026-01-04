# Guide de Démarrage Rapide - Workflow Claude Code

Ce guide vous permettra de démarrer avec le workflow Claude Code en moins de 5 minutes.

## Installation en 3 Étapes

### 1. Télécharger le Workflow

```bash
# Cloner le dépôt
git clone https://github.com/votre-repo/workflow_claudecode.git
cd workflow_claudecode

# Ou télécharger et extraire l'archive
wget https://github.com/votre-repo/workflow_claudecode/archive/main.zip
unzip main.zip
cd workflow_claudecode-main
```

### 2. Installer

```bash
# Rendre le script exécutable
chmod +x setup.sh

# Exécuter l'installation
sudo ./setup.sh
```

Le script va :
- ✓ Vérifier votre système Debian/Ubuntu
- ✓ Installer les dépendances nécessaires (`jq`, `curl`, etc.)
- ✓ Créer la structure de répertoires
- ✓ Installer Claude Code (avec votre confirmation)
- ✓ Configurer la tâche cron quotidienne
- ✓ Configurer la rotation des logs

### 3. Vérifier

```bash
# Vérifier l'installation
./run_agent.sh --status

# Devrait afficher :
# ✓ Claude Code installé
# ✓ Contexte global initialisé
# ✓ 0 projet (à créer)
```

---

## Premier Projet en 2 Minutes

### Créer un Projet

```bash
# Créer votre premier projet
./run_agent.sh --new mon_premier_projet

# Le système crée automatiquement :
# ✓ projects/mon_premier_projet/
# ✓ projects/mon_premier_projet/context.md
# ✓ projects/mon_premier_projet/journal.log
# ✓ projects/mon_premier_projet/config.json
```

### Personnaliser le Projet

```bash
# Éditer le contexte du projet
nano projects/mon_premier_projet/context.md

# Modifiez :
# - La description
# - Les objectifs
# - Les prochaines étapes
```

Exemple de contenu :

```markdown
# Contexte du Projet: mon_premier_projet

## Description du Projet

Créer une application web pour gérer des tâches avec Claude Code.

## Objectifs

- [x] Initialiser le projet
- [ ] Définir l'architecture
- [ ] Créer la base de données
- [ ] Développer l'API
- [ ] Créer l'interface utilisateur

## État Actuel

**Statut:** En cours
**Progression:** 20%
```

### Exécuter Manuellement

```bash
# Traiter ce projet maintenant
./run_agent.sh mon_premier_projet

# L'agent va :
# ✓ Analyser le contexte
# ✓ Générer un rapport d'analyse
# ✓ Mettre à jour le journal
# ✓ Générer la documentation
```

---

## Vérifier l'Automatisation

### Tâche Cron Configurée

```bash
# Vérifier la tâche cron
crontab -l | grep claude

# Devrait afficher :
# 0 0 * * * /chemin/vers/run_agent.sh --daily >> /chemin/vers/logs/cron.log 2>&1
```

Cette tâche s'exécute automatiquement **tous les jours à minuit**.

### Tester Manuellement

```bash
# Simuler l'exécution quotidienne
./run_agent.sh --daily

# L'agent va traiter tous les projets actifs
```

---

## Consulter les Résultats

### Voir les Logs

```bash
# Log principal
tail -f logs/claude_agent.log

# Journal du projet
tail -f projects/mon_premier_projet/journal.log

# Logs cron
tail -f logs/cron.log
```

### Analyser les Rapports

```bash
# Rapport d'analyse généré automatiquement
cat projects/mon_premier_projet/analysis_*.md

# Documentation générée
cat projects/mon_premier_projet/docs/README.md
```

---

## Commandes Essentielles

```bash
# Afficher l'aide
./run_agent.sh --help

# Statut du système
./run_agent.sh --status

# Lister tous les projets
./run_agent.sh --list

# Créer un nouveau projet
./run_agent.sh --new nom_du_projet

# Traiter un projet spécifique
./run_agent.sh nom_du_projet

# Exécuter les tâches quotidiennes
./run_agent.sh --daily
```

---

## Workflow Quotidien Recommandé

### Matin (5 minutes)

```bash
# 1. Vérifier le statut
./run_agent.sh --status

# 2. Consulter les logs de la nuit
tail -n 50 logs/cron.log

# 3. Lire les nouveaux rapports
ls -lt projects/*/analysis_*.md | head -5
```

### Soir (5 minutes)

```bash
# 1. Mettre à jour le contexte des projets actifs
nano projects/mon_projet/context.md

# 2. Lancer manuellement si nécessaire
./run_agent.sh --daily

# 3. Vérifier les résultats
tail -n 20 logs/claude_agent.log
```

---

## Configuration Avancée (Optionnel)

### Personnaliser un Projet

Éditez `projects/mon_projet/config.json` :

```json
{
  "tasks": {
    "auto_analysis": true,        // Analyse automatique chaque jour
    "auto_documentation": true,   // Génération de docs
    "auto_testing": false         // Tests (à activer si besoin)
  }
}
```

### Modifier la Planification

```bash
# Éditer le crontab
crontab -e

# Exemples de planification :

# Toutes les 6 heures
0 */6 * * * /chemin/vers/run_agent.sh --daily >> /chemin/vers/logs/cron.log 2>&1

# Deux fois par jour (9h et 21h)
0 9,21 * * * /chemin/vers/run_agent.sh --daily >> /chemin/vers/logs/cron.log 2>&1

# Seulement les jours de semaine à 8h
0 8 * * 1-5 /chemin/vers/run_agent.sh --daily >> /chemin/vers/logs/cron.log 2>&1
```

---

## Dépannage Rapide

### Claude Code Non Trouvé

```bash
# Réinstaller Claude Code
./run_agent.sh --install

# Ou manuellement
curl -fsSL https://claude.ai/install.sh | bash

# Ajouter au PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Cron Ne Fonctionne Pas

```bash
# Vérifier que cron est actif
sudo systemctl status cron

# Vérifier les permissions
chmod +x run_agent.sh

# Tester manuellement
./run_agent.sh --daily
```

### Erreur de Permissions

```bash
# Corriger les permissions
chmod +x run_agent.sh setup.sh lib/*.sh
chmod 755 projects/ logs/ config/
```

---

## Prochaines Étapes

1. **Lire la documentation complète** : [README.md](README.md)
2. **Créer plus de projets** pour différentes tâches
3. **Personnaliser les tâches** selon vos besoins
4. **Configurer les notifications** (email, Slack, etc.)
5. **Optimiser la planification cron** selon votre workflow

---

## Ressources Utiles

- **Documentation complète** : [README.md](README.md)
- **Architecture** : Section "Architecture" du README
- **Dépannage** : Section "Dépannage" du README
- **Configuration** : Fichier `.env.example`

---

## Support

Besoin d'aide ?

1. Consultez le [README.md](README.md) complet
2. Vérifiez les logs : `tail -f logs/claude_agent.log`
3. Créez une issue sur GitHub avec les détails du problème

---

**Vous êtes prêt ! Bon développement avec Claude Code ! 🚀**
