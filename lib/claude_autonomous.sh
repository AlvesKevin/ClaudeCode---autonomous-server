#!/bin/bash

################################################################################
# MODULE D'AUTONOMIE CLAUDE CODE
# Description: Gestion autonome complète du serveur par Claude Code
# Fonctions: Analyse système, prise de décision, gestion de projets autonome
################################################################################

# ==============================================================================
# FONCTIONS D'ANALYSE DU SYSTÈME
# ==============================================================================

# Collecter les informations système complètes
collect_system_info() {
    local output_file="${1:-/tmp/system_info.txt}"

    log_info "Collection des informations système..."

    {
        echo "═══════════════════════════════════════════════════════════"
        echo "INFORMATIONS SYSTÈME - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "═══════════════════════════════════════════════════════════"
        echo ""

        echo "## SYSTÈME D'EXPLOITATION"
        echo "-----------------------------------------------------------"
        uname -a
        cat /etc/os-release 2>/dev/null || echo "Info OS non disponible"
        echo ""

        echo "## RESSOURCES"
        echo "-----------------------------------------------------------"
        echo "CPU:"
        top -bn1 | head -5
        echo ""
        echo "Mémoire:"
        free -h
        echo ""
        echo "Disque:"
        df -h / /home 2>/dev/null
        echo ""

        echo "## CHARGE SYSTÈME"
        echo "-----------------------------------------------------------"
        uptime
        echo ""

        echo "## RÉSEAU"
        echo "-----------------------------------------------------------"
        ip addr show | grep -E "inet |UP" || ifconfig 2>/dev/null | grep -E "inet |UP"
        echo ""

        echo "## SERVICES ACTIFS"
        echo "-----------------------------------------------------------"
        systemctl list-units --type=service --state=running | head -20 2>/dev/null || echo "systemctl non disponible"
        echo ""

        echo "## SÉCURITÉ"
        echo "-----------------------------------------------------------"
        echo "Dernières connexions SSH:"
        last -n 10 2>/dev/null || echo "Historique non disponible"
        echo ""
        echo "Tentatives de connexion échouées:"
        grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 || echo "Logs non accessibles"
        echo ""

        echo "## MISES À JOUR DISPONIBLES"
        echo "-----------------------------------------------------------"
        if command -v apt &> /dev/null; then
            apt list --upgradable 2>/dev/null | head -10
        fi
        echo ""

        echo "## PROCESSUS GOURMANDS"
        echo "-----------------------------------------------------------"
        ps aux --sort=-%mem | head -10
        echo ""

        echo "═══════════════════════════════════════════════════════════"

    } > "$output_file"

    log_success "Informations système collectées: $output_file"
}

# ==============================================================================
# FONCTIONS D'AUTONOMIE
# ==============================================================================

# Faire analyser le système par Claude et obtenir des recommandations
analyze_system_with_claude() {
    log_info "Demande d'analyse système à Claude Code..."

    # Collecter les infos système
    local system_info="/tmp/system_info_$(date +%Y%m%d_%H%M%S).txt"
    collect_system_info "$system_info" > /dev/null 2>&1

    if [[ ! -f "$system_info" ]]; then
        log_error "Échec de la collecte des informations système"
        return 1
    fi

    local system_content=$(cat "$system_info")

    # Lire l'historique global
    local global_context=""
    if [[ -f "${GLOBAL_CONTEXT}" ]]; then
        global_context=$(jq -r '.' "${GLOBAL_CONTEXT}" 2>/dev/null || echo "{}")
    fi

    # Charger les directives système
    local system_directives=""
    local directives_file="${CONFIG_DIR}/system_directives.md"
    if [[ -f "$directives_file" ]]; then
        system_directives=$(cat "$directives_file")
        log_info "Directives système chargées"
    else
        log_warning "Fichier de directives système non trouvé: $directives_file"
    fi

    # Charger les demandes prioritaires
    local priority_requests=""
    local requests_file="${CONFIG_DIR}/project_requests.json"
    if [[ -f "$requests_file" ]]; then
        local pending_requests=$(jq -r '[.requests[] | select(.status == "pending")] | length' "$requests_file" 2>/dev/null || echo "0")
        if [[ "$pending_requests" -gt 0 ]]; then
            priority_requests=$(jq -r '.requests[] | select(.status == "pending") | "- [\(.requested_at)] \(.description) (Priorité: \(.priority))"' "$requests_file")
            log_info "Demandes prioritaires chargées: $pending_requests demande(s)"
        fi
    fi

    # Construire le prompt d'analyse
    local analysis_output="${LOGS_DIR}/claude_system_analysis_$(date +%Y%m%d_%H%M%S).md"

    cat > /tmp/claude_system_prompt.txt << EOF
Tu es un administrateur système autonome gérant ce serveur Debian/Ubuntu.

═══════════════════════════════════════════════════════════
TES DIRECTIVES SYSTÈME (À SUIVRE STRICTEMENT)
═══════════════════════════════════════════════════════════

${system_directives}

═══════════════════════════════════════════════════════════
ÉTAT DU SYSTÈME ACTUEL
═══════════════════════════════════════════════════════════

${system_content}

═══════════════════════════════════════════════════════════
CONTEXTE GLOBAL DES PROJETS
═══════════════════════════════════════════════════════════

${global_context}

EOF
    # Ajouter les demandes prioritaires si elles existent
    if [[ -n "$priority_requests" ]]; then
        cat >> /tmp/claude_system_prompt.txt << EOF

═══════════════════════════════════════════════════════════
⚠️  DEMANDES PRIORITAIRES (TRAITER EN PREMIER) ⚠️
═══════════════════════════════════════════════════════════

L'utilisateur a fait les demandes suivantes qui doivent être traitées en PRIORITÉ:

${priority_requests}

Ces demandes sont PRIORITAIRES et doivent être incluses dans tes propositions de projets.

EOF
    fi

    cat >> /tmp/claude_system_prompt.txt << EOF
═══════════════════════════════════════════════════════════
TA MISSION POUR AUJOURD'HUI
═══════════════════════════════════════════════════════════

En tant qu'agent autonome, tu dois :

1. **ANALYSER** l'état actuel du système
   - Santé générale (CPU, RAM, disque)
   - Sécurité (connexions suspectes, mises à jour manquantes)
   - Services en cours d'exécution
   - Problèmes détectés

2. **IDENTIFIER** les priorités pour AUJOURD'HUI
   - Problèmes critiques à résoudre immédiatement
   - Tâches de maintenance nécessaires
   - Opportunités d'amélioration

3. **PROPOSER** 1 à 2 projets concrets pour aujourd'hui
   - Décris chaque projet en détail
   - Explique pourquoi c'est prioritaire
   - Donne les étapes d'implémentation

4. **RECOMMANDER** des actions de sécurité/monitoring

═══════════════════════════════════════════════════════════
FORMAT DE RÉPONSE ATTENDU (MARKDOWN)
═══════════════════════════════════════════════════════════

# Analyse Système Quotidienne
Date: $(date '+%Y-%m-%d %H:%M:%S')

## 📊 État Général
[Résumé en 2-3 phrases]

## 🔍 Points Analysés

### Ressources Système
- CPU: [état]
- RAM: [état]
- Disque: [état]

### Sécurité
- [Points de sécurité détectés]

### Services
- [Services importants et leur état]

## ⚠️ Alertes et Problèmes
[Liste des problèmes détectés, du plus critique au moins critique]

## 🎯 Projets Proposés pour Aujourd'hui

### Projet 1: [Nom du projet]
**Priorité**: [Haute/Moyenne/Basse]
**Durée estimée**: [X heures]
**Raison**: [Pourquoi ce projet est important maintenant]

**Étapes**:
1. [Étape 1]
2. [Étape 2]
3. [Étape 3]

**Résultat attendu**: [Ce qui sera accompli]

### Projet 2: [Nom du projet] (optionnel si temps)
[Même structure]

## 📋 Actions de Maintenance Recommandées
- [ ] [Action 1]
- [ ] [Action 2]

## 💡 Suggestions d'Amélioration à Long Terme
[Idées pour améliorer le système sur le long terme]

═══════════════════════════════════════════════════════════

Sois **concret**, **actionnable** et **autonome** dans tes propositions.
EOF

    # Appeler Claude Code avec le prompt (mode non-interactif)
    log_info "Consultation de Claude Code pour analyse autonome..."

    # Utiliser -p pour mode non-interactif (crucial pour cron et automation)
    if claude -p "$(cat /tmp/claude_system_prompt.txt)" > "$analysis_output" 2>&1; then
        log_success "Analyse système terminée: $analysis_output"

        # Afficher un résumé dans les logs
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "RÉSUMÉ DE L'ANALYSE CLAUDE"
        echo "═══════════════════════════════════════════════════════════"
        head -50 "$analysis_output"
        echo "..."
        echo ""
        echo "Analyse complète: $analysis_output"
        echo "═══════════════════════════════════════════════════════════"

        echo "$analysis_output"
    else
        log_error "Échec de l'analyse système par Claude"
        log_info "Vérifiez le fichier de sortie pour plus de détails:"
        log_info "  cat $analysis_output"
        return 1
    fi
}

# Laisser Claude décider et créer les projets du jour
autonomous_project_planning() {
    log_info "=== MODE AUTONOME: Planification des projets du jour ==="

    # Faire analyser le système
    local analysis_file=$(analyze_system_with_claude)

    if [[ ! -f "$analysis_file" ]]; then
        log_error "Impossible de poursuivre sans analyse système"
        return 1
    fi

    # Extraire les projets proposés de l'analyse
    log_info "Extraction des projets proposés par Claude..."

    # Demander à Claude de créer les projets
    cat > /tmp/claude_create_projects_prompt.txt << EOF
Basé sur ton analyse précédente (ci-dessous), crée les projets concrets que tu vas réaliser aujourd'hui.

ANALYSE:
$(cat "$analysis_file")

Pour chaque projet proposé, fournis :

1. **Nom du projet** (format: snake_case, ex: securite_ssh_hardening)
2. **Description courte** (1 phrase)
3. **Objectifs concrets** (liste à puces)
4. **Étapes d'implémentation** détaillées
5. **Critères de succès** (comment savoir que c'est terminé)

Format de réponse attendu:

PROJECT:nom_du_projet_1
DESCRIPTION:Description courte du projet
OBJECTIVES:
- Objectif 1
- Objectif 2
STEPS:
1. Étape détaillée 1
2. Étape détaillée 2
SUCCESS:
- Critère 1
- Critère 2
---
PROJECT:nom_du_projet_2
[même format si projet 2]

Limite-toi à 1-2 projets réalisables aujourd'hui.
EOF

    local projects_spec=$(claude -p "$(cat /tmp/claude_create_projects_prompt.txt)" 2>&1)

    # Parser et créer les projets
    echo "$projects_spec" | grep "^PROJECT:" | while read -r line; do
        local project_name=$(echo "$line" | cut -d: -f2)

        if [[ -n "$project_name" ]]; then
            log_info "Création du projet autonome: $project_name"

            # Créer le projet via le project_manager
            create_project "$project_name"

            # Enrichir le contexte avec les détails de Claude
            local project_context="${PROJECTS_DIR}/${project_name}/context.md"

            # Ajouter les spécifications complètes au contexte
            cat >> "$project_context" << CONTEXT_END

---

## 🤖 Spécifications Autonomes de Claude

Date de création: $(date '+%Y-%m-%d %H:%M:%S')

$(echo "$projects_spec" | sed -n "/^PROJECT:${project_name}/,/^---/p")

---

## Contexte Système lors de la Création

Basé sur l'analyse système du $(date '+%Y-%m-%d'):
- Voir: ${analysis_file}

CONTEXT_END

            add_journal_entry "$project_name" "Projet créé de manière autonome par Claude" "INFO"

            log_success "Projet autonome créé: $project_name"
        fi
    done

    log_success "=== Planification autonome terminée ==="
}

# ==============================================================================
# EXÉCUTION AUTONOME D'UN PROJET
# ==============================================================================

# Laisser Claude travailler de manière autonome sur un projet
execute_project_autonomously() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    local context_file="${project_dir}/context.md"
    local journal_file="${project_dir}/journal.log"

    log_info "Exécution autonome du projet: $project_name"

    if [[ ! -f "$context_file" ]]; then
        log_error "Contexte du projet introuvable"
        return 1
    fi

    # Lire le contexte complet
    local context=$(cat "$context_file")
    local journal_recent=$(tail -n 100 "$journal_file" 2>/dev/null || echo "Aucun historique")

    # Construire le prompt d'exécution
    cat > /tmp/claude_execute_prompt.txt << EOF
Tu es un agent autonome travaillant sur ce projet. Tu as un accès complet au serveur.

═══════════════════════════════════════════════════════════
CONTEXTE DU PROJET
═══════════════════════════════════════════════════════════

${context}

═══════════════════════════════════════════════════════════
HISTORIQUE RÉCENT
═══════════════════════════════════════════════════════════

${journal_recent}

═══════════════════════════════════════════════════════════
TA MISSION POUR CETTE SESSION
═══════════════════════════════════════════════════════════

1. **ANALYSER** où en est le projet
   - Quelles tâches sont complétées (✓)
   - Quelles tâches restent à faire
   - Quels obstacles ont été rencontrés

2. **DÉCIDER** de la prochaine étape logique
   - Choisis UNE tâche concrète à accomplir maintenant
   - Explique pourquoi c'est la bonne priorité

3. **FOURNIR** les commandes exactes à exécuter
   - Bash commands
   - Configurations
   - Tests à faire

4. **DOCUMENTER** le résultat attendu

═══════════════════════════════════════════════════════════
FORMAT DE RÉPONSE
═══════════════════════════════════════════════════════════

# Session de Travail - $(date '+%Y-%m-%d %H:%M:%S')

## 📌 État Actuel
[Résumé de où en est le projet]

## 🎯 Tâche Choisie pour Aujourd'hui
[Description de la tâche spécifique]

**Raison du choix**: [Pourquoi cette tâche maintenant]

## 🔧 Commandes à Exécuter

\`\`\`bash
# [Explication de ce que fait chaque commande]
commande1
commande2
commande3
\`\`\`

## ✅ Résultat Attendu
[Comment vérifier que ça a marché]

## 📝 Mise à Jour du Contexte
[Ce qui devra être mis à jour dans context.md après exécution]

## ⚠️ Précautions
[Points d'attention ou risques]

═══════════════════════════════════════════════════════════

Sois **précis** et **actionnable**. Les commandes que tu fournis seront potentiellement exécutées.
EOF

    # Consulter Claude
    local work_session="${project_dir}/session_$(date +%Y%m%d_%H%M%S).md"

    if claude -p "$(cat /tmp/claude_execute_prompt.txt)" > "$work_session" 2>&1; then
        log_success "Session de travail générée: $work_session"

        # Afficher la session
        cat "$work_session"

        # Journaliser
        add_journal_entry "$project_name" "Session de travail autonome générée: $(basename "$work_session")" "INFO"

        # Mettre à jour le contexte avec le lien vers la session
        cat >> "$context_file" << SESSION_LINK

### $(date '+%Y-%m-%d %H:%M:%S') - Session de Travail Autonome

Session générée: $(basename "$work_session")

SESSION_LINK

        echo "$work_session"
    else
        log_error "Échec de la génération de la session de travail"
        return 1
    fi
}

# ==============================================================================
# BOUCLE QUOTIDIENNE AUTONOME
# ==============================================================================

# Routine quotidienne complètement autonome
daily_autonomous_routine() {
    log_info "╔════════════════════════════════════════════════════════════╗"
    log_info "║        ROUTINE QUOTIDIENNE AUTONOME - DÉMARRAGE           ║"
    log_info "╚════════════════════════════════════════════════════════════╝"

    local routine_log="${LOGS_DIR}/autonomous_routine_$(date +%Y%m%d).log"

    {
        echo "═══════════════════════════════════════════════════════════"
        echo "ROUTINE AUTONOME - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "═══════════════════════════════════════════════════════════"

        # 1. Analyse système
        log_info "Étape 1: Analyse du système"
        analyze_system_with_claude

        # 2. Planification autonome
        log_info "Étape 2: Planification des projets du jour"
        autonomous_project_planning

        # 3. Travailler sur les projets existants actifs
        log_info "Étape 3: Travail sur les projets existants"

        local active_projects=$(get_active_projects)

        if [[ -n "$active_projects" && "$active_projects" != "[]" ]]; then
            echo "$active_projects" | jq -r '.[]' | while read -r project_name; do
                log_info "Travail autonome sur: $project_name"
                execute_project_autonomously "$project_name"
            done
        else
            log_info "Aucun projet actif en cours"
        fi

        echo "═══════════════════════════════════════════════════════════"
        echo "ROUTINE AUTONOME TERMINÉE - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "═══════════════════════════════════════════════════════════"

    } | tee "$routine_log"

    log_success "Routine quotidienne autonome terminée"
    log_info "Log complet: $routine_log"
}
