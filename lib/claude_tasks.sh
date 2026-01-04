#!/bin/bash

################################################################################
# MODULE DE TÂCHES CLAUDE CODE
# Description: Exemples et fonctions pour exécuter des tâches avec Claude Code
# Fonctions: Analyse de projets, génération de plans, documentation automatique
################################################################################

# ==============================================================================
# FONCTIONS D'EXÉCUTION DE TÂCHES CLAUDE CODE
# ==============================================================================

# Exécuter les tâches Claude Code pour un projet
execute_claude_tasks() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    local context_file="${project_dir}/context.md"
    local config_file="${project_dir}/config.json"

    if [[ ! -d "$project_dir" ]]; then
        log_error "Le projet '$project_name' n'existe pas"
        return 1
    fi

    log_info "Exécution des tâches Claude Code pour: $project_name"

    # Lire la configuration du projet
    local auto_analysis=false
    local auto_documentation=false
    local auto_testing=false

    if [[ -f "$config_file" ]]; then
        auto_analysis=$(jq -r '.tasks.auto_analysis // false' "$config_file")
        auto_documentation=$(jq -r '.tasks.auto_documentation // false' "$config_file")
        auto_testing=$(jq -r '.tasks.auto_testing // false' "$config_file")
    fi

    # Exécuter les tâches configurées
    if [[ "$auto_analysis" == "true" ]]; then
        analyze_project_with_claude "$project_name"
    fi

    if [[ "$auto_documentation" == "true" ]]; then
        generate_documentation_with_claude "$project_name"
    fi

    if [[ "$auto_testing" == "true" ]]; then
        run_tests_with_claude "$project_name"
    fi

    # Tâche par défaut: mise à jour du contexte
    update_project_status_with_claude "$project_name"

    log_success "Tâches Claude Code terminées pour: $project_name"
}

# Analyser un projet avec Claude Code
analyze_project_with_claude() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    local context_file="${project_dir}/context.md"

    log_info "Analyse du projet '$project_name' avec Claude Code..."

    add_journal_entry "$project_name" "Début de l'analyse automatique" "INFO"

    # Exemple de commande Claude pour analyser le projet
    # Note: Cette commande est un exemple et doit être adaptée selon vos besoins
    local analysis_prompt="Analysez le contexte du projet suivant et identifiez les tâches prioritaires:\n\n$(cat "$context_file")"

    # Simulation d'analyse (à remplacer par une vraie commande Claude)
    # claude chat --project "$project_name" --prompt "$analysis_prompt" > "${project_dir}/analysis_$(date +%Y%m%d).md"

    # Pour l'instant, créer un exemple de résultat d'analyse
    cat > "${project_dir}/analysis_$(date +%Y%m%d).md" << EOF
# Analyse Automatique du Projet: ${project_name}
Date: $(date '+%Y-%m-%d %H:%M:%S')

## Résumé de l'Analyse

Ce rapport a été généré automatiquement par l'agent Claude Code.

## État Actuel du Projet

- Le projet est en cours de développement
- Les fichiers de base sont en place
- Le contexte est correctement configuré

## Recommandations

1. **Définir les objectifs précis** - Le projet nécessite une définition claire des objectifs
2. **Planifier les étapes** - Établir un plan d'action détaillé
3. **Identifier les dépendances** - Lister toutes les dépendances nécessaires

## Prochaines Actions Suggérées

- [ ] Compléter la section "Description du Projet" dans context.md
- [ ] Définir au moins 3 objectifs mesurables
- [ ] Créer un plan d'implémentation

## Métriques

- Progression estimée: Initialisation (0-10%)
- Complexité: À évaluer
- Priorité: Moyenne

---
*Généré automatiquement par Claude Code Agent*
EOF

    add_journal_entry "$project_name" "Analyse terminée - Rapport généré: analysis_$(date +%Y%m%d).md" "SUCCESS"
    log_success "Analyse terminée pour: $project_name"
}

# Générer de la documentation avec Claude Code
generate_documentation_with_claude() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"

    log_info "Génération de documentation pour '$project_name'..."

    add_journal_entry "$project_name" "Génération automatique de documentation" "INFO"

    # Créer un répertoire pour la documentation
    local docs_dir="${project_dir}/docs"
    mkdir -p "$docs_dir"

    # Exemple: Générer un fichier README pour le projet
    cat > "${docs_dir}/README.md" << EOF
# Documentation du Projet: ${project_name}

Généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')

## Vue d'Ensemble

Ce projet est géré par l'agent Claude Code autonome.

## Structure du Projet

\`\`\`
${project_name}/
├── context.md       # Contexte et mémoire du projet
├── journal.log      # Journal des actions quotidiennes
├── config.json      # Configuration du projet
└── docs/           # Documentation générée
\`\`\`

## Utilisation

Consultez le fichier \`context.md\` pour comprendre l'état actuel du projet.

## Historique

Consultez \`journal.log\` pour voir l'historique complet des actions.

## Mises à Jour

Cette documentation est mise à jour automatiquement lors de chaque exécution de l'agent.

---
*Dernière mise à jour: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

    add_journal_entry "$project_name" "Documentation générée dans docs/" "SUCCESS"
    log_success "Documentation générée pour: $project_name"
}

# Exécuter des tests avec Claude Code
run_tests_with_claude() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"

    log_info "Exécution des tests pour '$project_name'..."

    add_journal_entry "$project_name" "Début des tests automatiques" "INFO"

    # Exemple de vérification de l'intégrité du projet
    local integrity_ok=true
    local issues=()

    # Vérifier la présence des fichiers requis
    if [[ ! -f "${project_dir}/context.md" ]]; then
        integrity_ok=false
        issues+=("Fichier context.md manquant")
    fi

    if [[ ! -f "${project_dir}/journal.log" ]]; then
        integrity_ok=false
        issues+=("Fichier journal.log manquant")
    fi

    if [[ ! -f "${project_dir}/config.json" ]]; then
        integrity_ok=false
        issues+=("Fichier config.json manquant")
    fi

    # Créer un rapport de test
    local test_report="${project_dir}/test_report_$(date +%Y%m%d).txt"
    {
        echo "================================================================================"
        echo "RAPPORT DE TEST - ${project_name}"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================================"
        echo ""

        if [[ "$integrity_ok" == true ]]; then
            echo "✓ TOUS LES TESTS SONT PASSÉS"
            echo ""
            echo "Vérifications effectuées:"
            echo "  ✓ Fichier context.md présent"
            echo "  ✓ Fichier journal.log présent"
            echo "  ✓ Fichier config.json présent"
        else
            echo "✗ ÉCHECS DÉTECTÉS"
            echo ""
            echo "Problèmes identifiés:"
            for issue in "${issues[@]}"; do
                echo "  ✗ $issue"
            done
        fi

        echo ""
        echo "================================================================================"
    } > "$test_report"

    if [[ "$integrity_ok" == true ]]; then
        add_journal_entry "$project_name" "Tests réussis - Aucun problème détecté" "SUCCESS"
        log_success "Tests réussis pour: $project_name"
    else
        add_journal_entry "$project_name" "Tests échoués - ${#issues[@]} problème(s) détecté(s)" "WARNING"
        log_warning "Tests échoués pour: $project_name (voir $test_report)"
    fi
}

# Mettre à jour le statut du projet avec Claude Code
update_project_status_with_claude() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    local context_file="${project_dir}/context.md"

    log_info "Mise à jour du statut pour '$project_name'..."

    # Compter les tâches complétées et en attente
    local tasks_done=0
    local tasks_pending=0

    if [[ -f "$context_file" ]]; then
        tasks_done=$(grep -c "^- \[x\]" "$context_file" 2>/dev/null || echo "0")
        tasks_pending=$(grep -c "^- \[ \]" "$context_file" 2>/dev/null || echo "0")
    fi

    local total_tasks=$((tasks_done + tasks_pending))
    local progress=0

    if [[ $total_tasks -gt 0 ]]; then
        progress=$((tasks_done * 100 / total_tasks))
    fi

    # Créer une entrée de statut
    local status_entry="Mise à jour automatique: $tasks_done/$total_tasks tâches complétées (${progress}%)"

    # Ajouter au contexte
    update_project_context "$project_name" "Mise à jour automatique" "$status_entry"

    # Journaliser
    add_journal_entry "$project_name" "$status_entry" "INFO"

    log_info "Statut: $status_entry"
}

# ==============================================================================
# EXEMPLES DE COMMANDES CLAUDE CODE
# ==============================================================================

# Exemple 1: Créer un plan d'action avec Claude
claude_create_action_plan() {
    local project_name="$1"
    local objective="$2"

    log_info "Création d'un plan d'action pour: $objective"

    # Exemple de prompt pour Claude Code
    local prompt="Créez un plan d'action détaillé pour atteindre l'objectif suivant:\n\nObjectif: ${objective}\n\nLe plan doit inclure:\n1. Les étapes principales\n2. Les sous-tâches pour chaque étape\n3. Les dépendances entre les tâches\n4. Une estimation de la complexité"

    # Commande Claude (exemple - à adapter)
    # claude chat --prompt "$prompt" > "${PROJECTS_DIR}/${project_name}/action_plan_$(date +%Y%m%d).md"

    add_journal_entry "$project_name" "Plan d'action créé pour: $objective" "INFO"
}

# Exemple 2: Analyser des fichiers de code
claude_analyze_code() {
    local project_name="$1"
    local code_path="$2"

    log_info "Analyse du code: $code_path"

    # Exemple de commande pour analyser du code
    # claude analyze --path "$code_path" --output "${PROJECTS_DIR}/${project_name}/code_analysis.md"

    add_journal_entry "$project_name" "Analyse de code effectuée: $code_path" "INFO"
}

# Exemple 3: Générer des tests automatiques
claude_generate_tests() {
    local project_name="$1"
    local code_file="$2"

    log_info "Génération de tests pour: $code_file"

    # Exemple de commande pour générer des tests
    # claude generate-tests --input "$code_file" --output "${PROJECTS_DIR}/${project_name}/tests/test_$(basename "$code_file")"

    add_journal_entry "$project_name" "Tests générés pour: $code_file" "INFO"
}

# Exemple 4: Refactoring de code
claude_refactor_code() {
    local project_name="$1"
    local target_file="$2"
    local instructions="$3"

    log_info "Refactoring de: $target_file"

    # Exemple de commande pour refactorer du code
    # claude refactor --file "$target_file" --instructions "$instructions" --backup

    add_journal_entry "$project_name" "Refactoring effectué: $target_file" "INFO"
}

# Exemple 5: Générer un rapport de progression
claude_generate_progress_report() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    local report_file="${project_dir}/progress_report_$(date +%Y%m%d).md"

    log_info "Génération du rapport de progression..."

    # Lire les données du contexte et du journal
    local context_content=""
    local journal_recent=""

    if [[ -f "${project_dir}/context.md" ]]; then
        context_content=$(cat "${project_dir}/context.md")
    fi

    if [[ -f "${project_dir}/journal.log" ]]; then
        journal_recent=$(tail -n 50 "${project_dir}/journal.log")
    fi

    # Créer le rapport
    cat > "$report_file" << EOF
# Rapport de Progression - ${project_name}

**Date:** $(date '+%Y-%m-%d %H:%M:%S')

## Résumé Exécutif

Ce rapport présente l'état actuel du projet ${project_name}.

## Métriques de Progression

$(get_project_stats "$project_name" | grep -A 20 "Tâches:")

## Activité Récente

Les 50 dernières entrées du journal:

\`\`\`
${journal_recent}
\`\`\`

## Analyse du Contexte

Le contexte actuel du projet montre:
- Structure de base en place
- Fichiers de configuration créés
- Système de suivi actif

## Recommandations

1. Continuer à documenter les progrès dans context.md
2. Maintenir le journal à jour
3. Réviser régulièrement les objectifs

---
*Rapport généré automatiquement par Claude Code Agent*
EOF

    add_journal_entry "$project_name" "Rapport de progression généré: $(basename "$report_file")" "INFO"
    log_success "Rapport généré: $report_file"
}

# ==============================================================================
# COMMANDES INTERACTIVES CLAUDE CODE
# ==============================================================================

# Session interactive avec Claude pour un projet
claude_interactive_session() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"

    log_info "Démarrage d'une session interactive pour: $project_name"

    # Charger le contexte
    echo "Contexte du projet chargé:"
    echo "──────────────────────────────────────────────────────────────"
    head -n 20 "${project_dir}/context.md"
    echo "──────────────────────────────────────────────────────────────"
    echo ""

    # Exemple de session interactive (nécessite Claude Code installé)
    # cd "$project_dir" && claude chat

    add_journal_entry "$project_name" "Session interactive démarrée" "INFO"
}
