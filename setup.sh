#!/bin/bash

################################################################################
# SCRIPT D'INSTALLATION ET CONFIGURATION
# Description: Installation complète du workflow Claude Code sur Debian
# Usage: sudo ./setup.sh ou ./setup.sh
# Auteur: Workflow Claude Code
# Date: 2026-01-04
################################################################################

set -euo pipefail

# ==============================================================================
# VARIABLES DE CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_USER="${SUDO_USER:-$USER}"
INSTALL_HOME=$(eval echo ~"$INSTALL_USER")

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# FONCTIONS D'AFFICHAGE
# ==============================================================================

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ==============================================================================
# FONCTIONS DE VÉRIFICATION
# ==============================================================================

check_os() {
    section "Vérification du système d'exploitation"

    if [[ ! -f /etc/debian_version ]]; then
        error "Ce script est conçu pour Debian/Ubuntu"
        error "Système détecté: $(uname -s)"
        exit 1
    fi

    local debian_version=$(cat /etc/debian_version)
    success "Système Debian détecté (version: $debian_version)"
}

check_dependencies() {
    section "Vérification des dépendances système"

    local deps=("curl" "bash" "jq" "gzip" "tar" "cron")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
            warning "Dépendance manquante: $dep"
        else
            success "✓ $dep"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warning "Installation des dépendances manquantes..."

        if [[ $EUID -ne 0 ]]; then
            error "Droits root nécessaires pour installer les dépendances"
            info "Exécutez: sudo apt-get install ${missing[*]}"
            exit 1
        fi

        apt-get update
        apt-get install -y "${missing[@]}"
        success "Dépendances installées"
    else
        success "Toutes les dépendances sont présentes"
    fi
}

# ==============================================================================
# FONCTIONS D'INSTALLATION
# ==============================================================================

install_workflow() {
    section "Installation du workflow Claude Code"

    # Créer les répertoires nécessaires
    info "Création de la structure de répertoires..."
    mkdir -p "${SCRIPT_DIR}"/{projects,logs,config,lib}

    # Configurer les permissions des répertoires
    info "Configuration des permissions..."
    chmod +x "${SCRIPT_DIR}/run_agent.sh"
    chmod +x "${SCRIPT_DIR}/lib"/*.sh

    # Définir le propriétaire correct des répertoires
    if [[ $EUID -eq 0 ]] && [[ -n "$INSTALL_USER" ]]; then
        chown -R "${INSTALL_USER}:${INSTALL_USER}" "${SCRIPT_DIR}"/{projects,logs,config}
        info "Propriétaire défini: ${INSTALL_USER}"
    fi

    # S'assurer que les répertoires sont accessibles en écriture
    chmod 755 "${SCRIPT_DIR}"/{projects,logs,config}

    success "Structure du workflow créée"
}

configure_cron() {
    section "Configuration de la tâche Cron"

    echo ""
    info "Choisissez le mode d'exécution automatique:"
    echo "  1. Mode AUTONOME (recommandé) - Claude analyse et décide tout seul"
    echo "  2. Mode DAILY - Exécute uniquement les projets existants"
    echo ""
    read -p "Votre choix (1/2) [1]: " -r choice
    echo

    local mode="--autonomous"
    if [[ "$choice" == "2" ]]; then
        mode="--daily"
        info "Mode sélectionné: DAILY (projets existants uniquement)"
    else
        mode="--autonomous"
        success "Mode sélectionné: AUTONOME (Claude gère tout)"
    fi

    local cron_schedule="0 0 * * *"  # Minuit chaque jour
    local cron_command="${SCRIPT_DIR}/run_agent.sh ${mode} >> ${SCRIPT_DIR}/logs/cron.log 2>&1"
    local cron_entry="${cron_schedule} ${cron_command}"

    info "Configuration de la tâche cron pour l'utilisateur: $INSTALL_USER"

    # Vérifier si une tâche existe déjà
    if crontab -u "$INSTALL_USER" -l 2>/dev/null | grep -q "run_agent.sh"; then
        warning "Une tâche cron existe déjà pour ce workflow"
        read -p "Voulez-vous la remplacer ? (o/N) " -r replace
        echo
        if [[ ! "$replace" =~ ^[Oo]$ ]]; then
            info "Tâche cron conservée"
            return 0
        fi

        # Supprimer l'ancienne tâche
        crontab -u "$INSTALL_USER" -l 2>/dev/null | grep -v "run_agent.sh" | crontab -u "$INSTALL_USER" - || true
    fi

    # Ajouter la nouvelle tâche
    (crontab -u "$INSTALL_USER" -l 2>/dev/null || true; echo "$cron_entry") | crontab -u "$INSTALL_USER" - || {
        error "Échec de la configuration de la tâche cron"
        warning "Vous pourrez la configurer manuellement plus tard avec:"
        echo "  crontab -e"
        echo "  Ajoutez: $cron_entry"
        return 0
    }

    success "Tâche cron configurée: $cron_schedule"
    info "La tâche s'exécutera tous les jours à minuit en mode: $mode"

    # Afficher les tâches cron actuelles
    info "Tâches cron pour $INSTALL_USER:"
    crontab -u "$INSTALL_USER" -l 2>/dev/null | grep "run_agent" || echo "  (aucune tâche cron configurée)"
}

configure_environment() {
    section "Configuration de l'environnement"

    # Créer un fichier d'environnement pour cron
    local env_file="${SCRIPT_DIR}/.env"

    cat > "$env_file" << EOF
# Configuration d'environnement pour Claude Code Agent
# Généré le: $(date '+%Y-%m-%d %H:%M:%S')

# Chemins
PATH=${INSTALL_HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin
HOME=${INSTALL_HOME}

# Configuration du workflow
WORKFLOW_DIR=${SCRIPT_DIR}
LOG_LEVEL=INFO

# Configuration Claude Code
# Ajoutez ici vos variables d'environnement spécifiques
EOF

    success "Fichier d'environnement créé: $env_file"

    # Mettre à jour le script pour charger l'environnement
    info "Configuration de l'environnement pour cron..."

    # Ajouter le chargement de l'environnement dans run_agent.sh si nécessaire
    if ! grep -q "source.*\.env" "${SCRIPT_DIR}/run_agent.sh"; then
        info "Note: Ajoutez 'source ${env_file}' au début de run_agent.sh si nécessaire"
    fi
}

setup_logrotate() {
    section "Configuration de la rotation des logs"

    local logrotate_config="/etc/logrotate.d/claude-agent"

    if [[ $EUID -ne 0 ]]; then
        warning "Droits root nécessaires pour configurer logrotate"
        info "Pour configurer logrotate manuellement, créez le fichier:"
        info "$logrotate_config"
        info "Avec le contenu suivant:"
        echo ""
        cat << EOF
${SCRIPT_DIR}/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${INSTALL_USER} ${INSTALL_USER}
}
EOF
        return 0
    fi

    # Créer la configuration logrotate
    cat > "$logrotate_config" << EOF
# Configuration logrotate pour Claude Code Agent
# Créé le: $(date '+%Y-%m-%d %H:%M:%S')

${SCRIPT_DIR}/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${INSTALL_USER} ${INSTALL_USER}
    sharedscripts
    postrotate
        # Optionnel: notifier l'application
    endscript
}

${SCRIPT_DIR}/projects/*/journal.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${INSTALL_USER} ${INSTALL_USER}
}
EOF

    success "Configuration logrotate créée: $logrotate_config"

    # Tester la configuration
    if logrotate -d "$logrotate_config" &> /dev/null; then
        success "Configuration logrotate valide"
    else
        warning "La configuration logrotate pourrait avoir des problèmes"
    fi
}

install_claude_code() {
    section "Installation de Claude Code"

    # Vérifier si Claude Code est déjà installé
    if command -v claude &> /dev/null; then
        success "Claude Code est déjà installé"
        claude --version || true
        return 0
    fi

    info "Claude Code n'est pas installé"
    read -p "Voulez-vous installer Claude Code maintenant ? (o/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        warning "Installation de Claude Code ignorée"
        info "Vous pouvez l'installer plus tard avec: ./run_agent.sh --install"
        return 0
    fi

    info "Téléchargement et installation de Claude Code..."

    # Installer en tant qu'utilisateur normal (pas root)
    if [[ $EUID -eq 0 ]]; then
        su - "$INSTALL_USER" -c "curl -fsSL https://claude.ai/install.sh | bash"
    else
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    # Configurer automatiquement le PATH dans .bashrc
    local bashrc_file="${INSTALL_HOME}/.bashrc"
    local path_export='export PATH="$HOME/.local/bin:$PATH"'

    if [[ -f "$bashrc_file" ]] && ! grep -q '.local/bin' "$bashrc_file"; then
        info "Configuration automatique du PATH dans .bashrc..."
        if [[ $EUID -eq 0 ]]; then
            su - "$INSTALL_USER" -c "echo '$path_export' >> ~/.bashrc"
        else
            echo "$path_export" >> "$bashrc_file"
        fi
        success "PATH configuré automatiquement"
    fi

    # Recharger le PATH pour la session actuelle
    export PATH="$INSTALL_HOME/.local/bin:$PATH"

    # Vérifier l'installation
    if command -v claude &> /dev/null; then
        success "Claude Code installé avec succès"
        claude --version || true
    else
        warning "Claude Code installé mais nécessite rechargement du shell"
        info "Exécutez: source ~/.bashrc"
    fi
}

authenticate_claude_code() {
    section "Authentification Claude Code"

    # Vérifier si Claude Code est installé
    if ! command -v claude &> /dev/null; then
        warning "Claude Code n'est pas installé, authentification ignorée"
        return 0
    fi

    # Vérifier si déjà authentifié
    info "Vérification de l'authentification Claude Code..."

    # Tester si une session est active
    if claude --version &> /dev/null; then
        # Essayer une commande simple pour tester l'auth
        if timeout 5 claude help &> /dev/null 2>&1; then
            success "Claude Code est déjà authentifié"
            return 0
        fi
    fi

    warning "Claude Code n'est pas authentifié"
    echo ""
    info "Pour utiliser Claude Code, vous devez vous authentifier avec votre compte Claude."
    info "Cette opération se fait UNE SEULE FOIS et sera persistée pour cron."
    echo ""

    read -p "Voulez-vous vous authentifier maintenant ? (o/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        warning "Authentification ignorée"
        info "Pour vous authentifier plus tard, exécutez:"
        info "  claude auth login"
        echo ""
        info "IMPORTANT: Vous DEVEZ vous authentifier avant d'utiliser le workflow !"
        return 0
    fi

    echo ""
    info "Lancement de l'authentification interactive..."
    info "Suivez les instructions à l'écran pour vous connecter à votre compte Claude."
    echo ""

    # Lancer l'authentification en tant qu'utilisateur approprié
    if [[ $EUID -eq 0 ]]; then
        su - "$INSTALL_USER" -c "claude auth login"
    else
        claude auth login
    fi

    # Vérifier le résultat
    echo ""
    if timeout 5 claude help &> /dev/null 2>&1; then
        success "Authentification réussie !"
        info "Votre session Claude Code est maintenant active."
        info "Le workflow pourra utiliser votre abonnement Claude Code automatiquement."
    else
        error "L'authentification a échoué"
        info "Réessayez manuellement avec: claude auth login"
        return 1
    fi
}

# ==============================================================================
# FONCTIONS DE POST-INSTALLATION
# ==============================================================================

create_example_project() {
    section "Création d'un projet d'exemple"

    read -p "Voulez-vous créer un projet d'exemple ? (o/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        info "Création du projet d'exemple ignorée"
        return 0
    fi

    info "Création du projet 'example_project'..."

    # Exécuter le script principal pour créer le projet
    "${SCRIPT_DIR}/run_agent.sh" --new example_project

    success "Projet d'exemple créé"
}

show_completion_message() {
    section "Installation terminée avec succès !"

    cat << EOF
${GREEN}╔════════════════════════════════════════════════════════════╗
║           WORKFLOW CLAUDE CODE INSTALLÉ                    ║
╚════════════════════════════════════════════════════════════╝${NC}

${BLUE}Répertoire d'installation:${NC}
  ${SCRIPT_DIR}

${BLUE}Prochaines étapes:${NC}

  ${YELLOW}⚠️  IMPORTANT: N'utilisez PAS sudo avec run_agent.sh !${NC}
  ${YELLOW}    Claude Code fonctionne avec votre compte utilisateur.${NC}

  1. Recharger le shell pour activer Claude Code:
     ${GREEN}source ~/.bashrc${NC}

  2. Authentifier Claude Code (OBLIGATOIRE):
     ${GREEN}claude auth login${NC}

  3. Ajouter une demande de projet prioritaire:
     ${GREEN}./run_agent.sh --request "Install Docker and Docker Compose"${NC}

  4. Lancer le mode autonome immédiatement:
     ${GREEN}./run_agent.sh --run-now${NC}

  5. Vérifier le statut:
     ${GREEN}./run_agent.sh --status${NC}

${BLUE}Tâche automatique:${NC}
  ✓ Configurée pour s'exécuter tous les jours à minuit
  ✓ Les logs seront dans: ${SCRIPT_DIR}/logs/

${BLUE}Vérifier la tâche cron:${NC}
  ${GREEN}crontab -l | grep claude${NC}

${BLUE}Documentation:${NC}
  Consultez le fichier README.md pour plus d'informations

${RED}⚠️  NE PAS UTILISER SUDO:${NC}
  ${RED}✗ sudo ./run_agent.sh --run-now${NC}  (FAUX)
  ${GREEN}✓ ./run_agent.sh --run-now${NC}       (CORRECT)

${GREEN}Bon développement avec Claude Code ! 🚀${NC}
EOF
}

# ==============================================================================
# FONCTION DE DÉSINSTALLATION
# ==============================================================================

uninstall_workflow() {
    section "Désinstallation du workflow Claude Code"

    warning "Cette action va supprimer:"
    echo "  - La tâche cron"
    echo "  - La configuration logrotate (si configurée)"
    echo ""
    warning "Les projets et logs ne seront PAS supprimés"
    echo ""

    read -p "Êtes-vous sûr de vouloir continuer ? (o/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        info "Désinstallation annulée"
        exit 0
    fi

    # Supprimer la tâche cron
    info "Suppression de la tâche cron..."
    crontab -u "$INSTALL_USER" -l 2>/dev/null | grep -v "run_agent.sh" | crontab -u "$INSTALL_USER" - || true
    success "Tâche cron supprimée"

    # Supprimer la configuration logrotate
    if [[ -f "/etc/logrotate.d/claude-agent" ]]; then
        if [[ $EUID -eq 0 ]]; then
            rm -f "/etc/logrotate.d/claude-agent"
            success "Configuration logrotate supprimée"
        else
            warning "Droits root nécessaires pour supprimer /etc/logrotate.d/claude-agent"
        fi
    fi

    success "Désinstallation terminée"
    info "Les fichiers du workflow sont toujours dans: ${SCRIPT_DIR}"
    info "Pour supprimer complètement, exécutez: rm -rf ${SCRIPT_DIR}"
}

# ==============================================================================
# FONCTION PRINCIPALE
# ==============================================================================

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      INSTALLATION DU WORKFLOW CLAUDE CODE AUTONOME         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Traiter les options
    case "${1:-}" in
        --uninstall)
            uninstall_workflow
            exit 0
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Options:
    (aucune)        Installation complète
    --uninstall     Désinstaller le workflow
    --help, -h      Afficher cette aide

Installation:
    sudo $0         Installation complète (recommandé)
    $0              Installation sans privilèges root (certaines fonctionnalités limitées)

EOF
            exit 0
            ;;
    esac

    # Processus d'installation
    check_os || { error "Vérification OS échouée"; exit 1; }
    check_dependencies || { error "Vérification dépendances échouée"; exit 1; }
    install_workflow || { error "Installation workflow échouée"; exit 1; }
    configure_environment || { error "Configuration environnement échouée"; exit 1; }
    install_claude_code || warning "Installation Claude Code ignorée ou échouée (non bloquant)"
    authenticate_claude_code || warning "Authentification Claude Code ignorée ou échouée (non bloquant)"
    configure_cron || warning "Configuration cron ignorée ou échouée (non bloquant)"
    setup_logrotate || warning "Configuration logrotate ignorée ou échouée (non bloquant)"
    create_example_project || warning "Création projet exemple ignorée (non bloquant)"
    show_completion_message
}

# Exécuter le script
main "$@"
