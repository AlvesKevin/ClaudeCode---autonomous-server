#!/bin/bash

################################################################################
# SCRIPT PRINCIPAL - AGENT CLAUDE CODE AUTONOME
# Description: Script principal pour gérer l'agent Claude Code automatisé
# Usage: ./run_agent.sh [projet_name]
# Auteur: Workflow Claude Code
# Date: 2026-01-04
################################################################################

set -euo pipefail  # Arrêt en cas d'erreur, variables non définies, erreurs de pipeline

# ==============================================================================
# CONFIGURATION GLOBALE
# ==============================================================================

# Répertoire de base du workflow
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="${WORKFLOW_DIR}/projects"
LOGS_DIR="${WORKFLOW_DIR}/logs"
CONFIG_DIR="${WORKFLOW_DIR}/config"
LIB_DIR="${WORKFLOW_DIR}/lib"

# Fichiers de configuration
GLOBAL_CONTEXT="${CONFIG_DIR}/context_global.json"
MAIN_LOG="${LOGS_DIR}/claude_agent.log"

# Charger les modules
source "${LIB_DIR}/logger.sh"
source "${LIB_DIR}/context_manager.sh"
source "${LIB_DIR}/project_manager.sh"
source "${LIB_DIR}/claude_tasks.sh"
source "${LIB_DIR}/claude_autonomous.sh"

# ==============================================================================
# FONCTIONS PRINCIPALES
# ==============================================================================

# Vérifier si Claude Code est installé
check_claude_installation() {
    log_info "Vérification de l'installation de Claude Code..."

    if command -v claude &> /dev/null; then
        log_success "Claude Code est déjà installé"
        claude --version || true
        return 0
    else
        log_warning "Claude Code n'est pas installé"
        return 1
    fi
}

# Vérifier l'authentification Claude Code
check_claude_authentication() {
    log_info "Vérification de l'authentification Claude Code..."

    # Vérifier si Claude Code est installé
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code n'est pas installé"
        return 1
    fi

    # Tester l'authentification avec une commande non-interactive
    # On teste directement car Claude peut stocker credentials dans le keychain système
    local auth_test_output
    local auth_test_exitcode

    auth_test_output=$(timeout 10 claude -p "test" 2>&1)
    auth_test_exitcode=$?

    # Si le code de sortie est 0, la commande a réussi
    if [[ $auth_test_exitcode -eq 0 ]]; then
        log_success "Claude Code authentifié - Session active"
        return 0
    fi

    # Vérifier si c'est une erreur d'authentification spécifique
    if echo "$auth_test_output" | grep -qi "not.*authenticated\|login.*required\|credentials.*not.*found\|authentication.*required\|please.*log.*in"; then
        log_error "Claude Code n'est pas authentifié"
        log_info ""
        log_info "Pour vous authentifier:"
        log_info "  1. Exécutez: claude"
        log_info "  2. Choisissez 'Claude.ai'"
        log_info "  3. Suivez les instructions"
        log_info "  4. Tapez /exit pour sortir"
        log_info "  5. Vérifiez: claude -p \"test\""
        log_info ""
        return 1
    fi

    # Autre erreur (timeout, réseau, etc.)
    log_warning "Impossible de vérifier l'authentification (timeout ou erreur réseau)"
    log_info "Sortie de la commande:"
    echo "$auth_test_output" | head -5
    return 1
}

# Installer Claude Code
install_claude() {
    log_info "Installation de Claude Code en cours..."

    # Vérifier les dépendances système
    local deps=("curl" "bash")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Dépendance manquante: $dep"
            log_info "Installation via: sudo apt-get install $dep"
            exit 1
        fi
    done

    # Installation officielle de Claude Code
    log_info "Téléchargement et installation via le script officiel..."
    if curl -fsSL https://claude.ai/install.sh | bash; then
        log_success "Claude Code installé avec succès"

        # Recharger le PATH pour la session actuelle
        export PATH="$HOME/.local/bin:$PATH"

        # Vérifier l'installation
        if command -v claude &> /dev/null; then
            log_success "Vérification: Claude Code est maintenant disponible"
            claude --version || true
        else
            log_warning "Claude Code installé mais non disponible dans PATH"
            log_info "Ajoutez cette ligne à votre ~/.bashrc ou ~/.profile :"
            log_info "export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
    else
        log_error "Échec de l'installation de Claude Code"
        exit 1
    fi
}

# Initialiser l'environnement de travail
initialize_environment() {
    log_info "Initialisation de l'environnement de travail..."

    # Créer les répertoires nécessaires
    local dirs=("${PROJECTS_DIR}" "${LOGS_DIR}" "${CONFIG_DIR}" "${LIB_DIR}")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Répertoire créé: $dir"
        fi
    done

    # Initialiser le contexte global s'il n'existe pas
    if [[ ! -f "${GLOBAL_CONTEXT}" ]]; then
        log_info "Création du contexte global..."
        initialize_global_context
    fi

    log_success "Environnement initialisé"
}

# Vérifier et mettre à jour le contexte global
update_global_status() {
    log_info "Mise à jour du contexte global..."

    # Vérifier si Claude est installé
    local claude_installed=false
    if command -v claude &> /dev/null; then
        claude_installed=true
    fi

    # Mettre à jour le flag d'installation dans le contexte
    update_claude_installation_status "$claude_installed"

    # Scanner et mettre à jour la liste des projets
    scan_and_update_projects

    log_success "Contexte global mis à jour"
}

# Exécuter les tâches quotidiennes
run_daily_tasks() {
    log_info "=== DÉBUT DES TÂCHES QUOTIDIENNES ==="
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"

    # Vérifier l'authentification avant de commencer
    if ! check_claude_authentication; then
        log_error "Impossible d'exécuter les tâches: Claude Code non authentifié"
        log_info "Authentifiez-vous avec: claude auth login"
        return 1
    fi

    # Récupérer la liste des projets actifs
    local projects=$(get_active_projects)

    if [[ -z "$projects" || "$projects" == "[]" ]]; then
        log_warning "Aucun projet actif trouvé"
        return 0
    fi

    # Traiter chaque projet
    echo "$projects" | jq -r '.[]' | while read -r project_name; do
        log_info "Traitement du projet: $project_name"
        process_project "$project_name"
    done

    log_info "=== FIN DES TÂCHES QUOTIDIENNES ==="
}

# Traiter un projet spécifique
process_project() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"

    if [[ ! -d "$project_dir" ]]; then
        log_error "Le projet '$project_name' n'existe pas"
        return 1
    fi

    log_info "--- Début du traitement: $project_name ---"

    # Journaliser le début du traitement
    add_journal_entry "$project_name" "Début du traitement quotidien"

    # Exécuter les tâches Claude Code pour ce projet
    execute_claude_tasks "$project_name"

    # Journaliser la fin du traitement
    add_journal_entry "$project_name" "Fin du traitement quotidien"

    log_info "--- Fin du traitement: $project_name ---"
}

# Ajouter une demande de projet prioritaire
add_project_request() {
    local request_description="$1"
    local requests_file="${CONFIG_DIR}/project_requests.json"

    log_info "Ajout d'une demande de projet prioritaire..."

    # Créer le fichier de demandes s'il n'existe pas
    if [[ ! -f "$requests_file" ]]; then
        echo '{"requests": []}' > "$requests_file"
    fi

    # Créer l'objet de demande
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local request_obj=$(jq -n \
        --arg desc "$request_description" \
        --arg date "$timestamp" \
        --arg status "pending" \
        '{
            description: $desc,
            requested_at: $date,
            status: $status,
            priority: "high"
        }')

    # Ajouter la demande au fichier
    local temp_file=$(mktemp)
    jq --argjson req "$request_obj" \
        '.requests += [$req]' \
        "$requests_file" > "$temp_file"
    mv "$temp_file" "$requests_file"

    log_success "Demande de projet ajoutée avec succès !"
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           DEMANDE DE PROJET ENREGISTRÉE                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Description: $request_description"
    echo "Date: $timestamp"
    echo "Priorité: Haute"
    echo ""
    echo "Cette demande sera traitée lors de la prochaine exécution autonome."
    echo ""
    echo "Pour lancer le mode autonome maintenant:"
    echo "  ./run_agent.sh --run-now"
    echo ""
}

# Afficher l'aide
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [PROJET]

Script principal de l'agent Claude Code autonome pour Debian.

OPTIONS:
    -h, --help              Afficher cette aide
    -i, --install           Installer Claude Code (si non installé)
    -s, --status            Afficher le statut du système
    -n, --new PROJECT       Créer un nouveau projet
    -l, --list              Lister tous les projets
    -d, --daily             Exécuter les tâches quotidiennes (mode cron)
    -a, --autonomous        MODE AUTONOME: Laisser Claude analyser et décider
    -r, --request "DESC"    Ajouter une demande de projet prioritaire
    --run-now               Lancer le mode autonome immédiatement

MODES:
    --daily                 Exécute les projets existants
    --autonomous            Claude analyse le système, crée et gère ses projets
    --run-now               Comme --autonomous mais pour exécution manuelle immédiate

EXEMPLES:
    $0 --install                        # Installer Claude Code
    $0 --new mon_projet                 # Créer un nouveau projet
    $0 --daily                          # Exécuter les tâches quotidiennes
    $0 --autonomous                     # Mode autonome complet (pour cron)
    $0 --run-now                        # Lancer mode autonome maintenant
    $0 --request "Installer Docker"     # Demander un projet à Claude
    $0 mon_projet                       # Traiter un projet spécifique

FICHIERS:
    Configuration:   ${GLOBAL_CONTEXT}
    Logs:            ${MAIN_LOG}
    Projets:         ${PROJECTS_DIR}/

Pour plus d'informations, consultez le README.md
EOF
}

# ==============================================================================
# POINT D'ENTRÉE PRINCIPAL
# ==============================================================================

main() {
    # Initialiser le système de logs
    setup_logging

    log_info "╔════════════════════════════════════════════════════════════╗"
    log_info "║        AGENT CLAUDE CODE AUTONOME - DÉMARRAGE            ║"
    log_info "╚════════════════════════════════════════════════════════════╝"

    # Initialiser l'environnement
    initialize_environment

    # Traiter les arguments
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--install)
            if ! check_claude_installation; then
                install_claude
            fi
            update_global_status
            ;;
        -s|--status)
            check_claude_installation
            check_claude_authentication || log_warning "Session Claude non authentifiée"
            show_global_status
            ;;
        -n|--new)
            if [[ -z "${2:-}" ]]; then
                log_error "Nom du projet requis"
                echo "Usage: $0 --new <nom_du_projet>"
                exit 1
            fi
            create_project "$2"
            update_global_status
            ;;
        -l|--list)
            list_all_projects
            ;;
        -d|--daily)
            # Mode tâches quotidiennes (appelé par cron)
            if ! check_claude_installation; then
                log_error "Claude Code n'est pas installé"
                exit 1
            fi
            update_global_status
            run_daily_tasks
            ;;
        -a|--autonomous)
            # MODE AUTONOME: Claude analyse et décide tout seul
            if ! check_claude_installation; then
                log_error "Claude Code n'est pas installé"
                exit 1
            fi
            if ! check_claude_authentication; then
                log_error "Claude Code non authentifié - Impossible d'utiliser le mode autonome"
                exit 1
            fi
            update_global_status
            daily_autonomous_routine
            ;;
        --run-now)
            # Lancer le mode autonome immédiatement (comme -a mais alias explicite)
            log_info "Lancement immédiat du mode autonome..."
            if ! check_claude_installation; then
                log_error "Claude Code n'est pas installé"
                exit 1
            fi
            if ! check_claude_authentication; then
                log_error "Claude Code non authentifié - Impossible d'utiliser le mode autonome"
                exit 1
            fi
            update_global_status
            daily_autonomous_routine
            ;;
        -r|--request)
            # Ajouter une demande de projet
            if [[ -z "${2:-}" ]]; then
                log_error "Description de la demande requise"
                echo "Usage: $0 --request \"Description du projet demandé\""
                exit 1
            fi
            add_project_request "$2"
            ;;
        "")
            # Sans argument, vérifier l'installation et afficher le statut
            if ! check_claude_installation; then
                log_warning "Claude Code n'est pas installé"
                log_info "Utilisez: $0 --install pour l'installer"
                exit 1
            fi
            update_global_status
            show_global_status
            ;;
        *)
            # Traiter un projet spécifique
            local project_name="$1"
            if ! check_claude_installation; then
                log_error "Claude Code n'est pas installé"
                exit 1
            fi
            update_global_status
            process_project "$project_name"
            ;;
    esac

    log_info "╔════════════════════════════════════════════════════════════╗"
    log_info "║              EXÉCUTION TERMINÉE AVEC SUCCÈS               ║"
    log_info "╚════════════════════════════════════════════════════════════╝"
}

# Exécuter le script principal
main "$@"
