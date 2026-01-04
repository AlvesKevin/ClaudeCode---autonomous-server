#!/bin/bash

################################################################################
# MODULE DE GESTION DES LOGS
# Description: Système de logging centralisé avec niveaux et couleurs
# Fonctions: Logging formaté, rotation des logs, archivage
################################################################################

# ==============================================================================
# CONFIGURATION DU LOGGING
# ==============================================================================

# Niveaux de log
declare -r LOG_LEVEL_DEBUG=0
declare -r LOG_LEVEL_INFO=1
declare -r LOG_LEVEL_SUCCESS=2
declare -r LOG_LEVEL_WARNING=3
declare -r LOG_LEVEL_ERROR=4

# Niveau de log actuel (peut être modifié via variable d'environnement)
LOG_LEVEL="${LOG_LEVEL:-$LOG_LEVEL_INFO}"

# Couleurs pour la sortie console (si le terminal les supporte)
if [[ -t 1 ]] && command -v tput &> /dev/null; then
    COLOR_RESET=$(tput sgr0)
    COLOR_RED=$(tput setaf 1)
    COLOR_GREEN=$(tput setaf 2)
    COLOR_YELLOW=$(tput setaf 3)
    COLOR_BLUE=$(tput setaf 4)
    COLOR_MAGENTA=$(tput setaf 5)
    COLOR_CYAN=$(tput setaf 6)
    COLOR_BOLD=$(tput bold)
else
    COLOR_RESET=""
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_MAGENTA=""
    COLOR_CYAN=""
    COLOR_BOLD=""
fi

# ==============================================================================
# FONCTIONS DE LOGGING
# ==============================================================================

# Initialiser le système de logs
setup_logging() {
    # Créer le répertoire de logs s'il n'existe pas
    if [[ ! -d "${LOGS_DIR}" ]]; then
        mkdir -p "${LOGS_DIR}"
    fi

    # Créer le fichier de log principal s'il n'existe pas
    if [[ ! -f "${MAIN_LOG}" ]]; then
        touch "${MAIN_LOG}"
    fi

    # Écrire l'en-tête de session
    {
        echo ""
        echo "================================================================================"
        echo "NOUVELLE SESSION - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================================"
    } >> "${MAIN_LOG}"
}

# Fonction générique de logging
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Formater le message pour le fichier (sans couleur)
    local log_entry="[${timestamp}] [${level}] ${message}"

    # Formater le message pour la console (avec couleur)
    local console_entry="${color}[${level}]${COLOR_RESET} ${message}"

    # Écrire dans le fichier de log
    echo "$log_entry" >> "${MAIN_LOG}"

    # Afficher sur la console
    echo -e "$console_entry"
}

# Log de débogage
log_debug() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]]; then
        _log "DEBUG" "${COLOR_MAGENTA}" "$1"
    fi
}

# Log d'information
log_info() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
        _log "INFO" "${COLOR_BLUE}" "$1"
    fi
}

# Log de succès
log_success() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_SUCCESS ]]; then
        _log "SUCCESS" "${COLOR_GREEN}" "$1"
    fi
}

# Log d'avertissement
log_warning() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_WARNING ]]; then
        _log "WARNING" "${COLOR_YELLOW}" "$1"
    fi
}

# Log d'erreur
log_error() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
        _log "ERROR" "${COLOR_RED}" "$1"
    fi
}

# Log d'une section (avec séparateur visuel)
log_section() {
    local title="$1"
    local separator="──────────────────────────────────────────────────────────────"

    echo ""
    echo "${COLOR_CYAN}${separator}${COLOR_RESET}" | tee -a "${MAIN_LOG}"
    echo "${COLOR_CYAN}${COLOR_BOLD}${title}${COLOR_RESET}" | tee -a "${MAIN_LOG}"
    echo "${COLOR_CYAN}${separator}${COLOR_RESET}" | tee -a "${MAIN_LOG}"
    echo ""
}

# ==============================================================================
# GESTION DES FICHIERS DE LOG
# ==============================================================================

# Rotation des logs (conserver les N derniers jours)
rotate_logs() {
    local retention_days="${1:-30}"  # Par défaut, conserver 30 jours
    local rotated_count=0

    log_info "Rotation des logs (rétention: ${retention_days} jours)"

    # Archiver le log principal s'il est trop volumineux (>10MB)
    if [[ -f "${MAIN_LOG}" ]]; then
        local log_size=$(stat -f%z "${MAIN_LOG}" 2>/dev/null || stat -c%s "${MAIN_LOG}" 2>/dev/null || echo "0")

        if [[ $log_size -gt 10485760 ]]; then  # 10MB
            local archive_name="${LOGS_DIR}/claude_agent_$(date +%Y%m%d_%H%M%S).log"
            mv "${MAIN_LOG}" "$archive_name"
            gzip "$archive_name"
            log_success "Log principal archivé: ${archive_name}.gz"
            touch "${MAIN_LOG}"
            ((rotated_count++))
        fi
    fi

    # Supprimer les logs archivés trop anciens
    find "${LOGS_DIR}" -name "*.log.gz" -type f -mtime "+${retention_days}" -delete 2>/dev/null
    local deleted_count=$(find "${LOGS_DIR}" -name "*.log.gz" -type f -mtime "+${retention_days}" 2>/dev/null | wc -l || echo "0")

    if [[ $deleted_count -gt 0 ]]; then
        log_info "Logs supprimés: $deleted_count fichier(s) de plus de ${retention_days} jours"
    fi

    # Rotation des logs de projets
    if [[ -d "${PROJECTS_DIR}" ]]; then
        for project_dir in "${PROJECTS_DIR}"/*/; do
            if [[ -d "$project_dir" ]]; then
                local journal_file="${project_dir}/journal.log"

                if [[ -f "$journal_file" ]]; then
                    local journal_size=$(stat -f%z "$journal_file" 2>/dev/null || stat -c%s "$journal_file" 2>/dev/null || echo "0")

                    if [[ $journal_size -gt 5242880 ]]; then  # 5MB
                        local project_name=$(basename "$project_dir")
                        local archive_name="${project_dir}/journal_$(date +%Y%m%d_%H%M%S).log"
                        cp "$journal_file" "$archive_name"
                        gzip "$archive_name"

                        # Tronquer le fichier original en gardant les 1000 dernières lignes
                        local temp_file=$(mktemp)
                        tail -n 1000 "$journal_file" > "$temp_file"
                        mv "$temp_file" "$journal_file"

                        log_info "Journal du projet '$project_name' archivé et tronqué"
                        ((rotated_count++))
                    fi
                fi
            fi
        done
    fi

    log_success "Rotation des logs terminée: $rotated_count fichier(s) traité(s)"
}

# Nettoyer les logs anciens
cleanup_old_logs() {
    local days="${1:-90}"  # Par défaut, supprimer les logs de plus de 90 jours

    log_info "Nettoyage des logs de plus de ${days} jours..."

    local deleted=0

    # Supprimer les logs principaux archivés
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted++))
    done < <(find "${LOGS_DIR}" -name "*.log.gz" -type f -mtime "+${days}" -print0 2>/dev/null)

    # Supprimer les journaux de projets archivés
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted++))
    done < <(find "${PROJECTS_DIR}" -name "journal_*.log.gz" -type f -mtime "+${days}" -print0 2>/dev/null)

    if [[ $deleted -gt 0 ]]; then
        log_success "Nettoyage terminé: $deleted fichier(s) supprimé(s)"
    else
        log_info "Aucun fichier à nettoyer"
    fi
}

# Afficher les statistiques des logs
show_log_stats() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              STATISTIQUES DES LOGS                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Statistiques du log principal
    if [[ -f "${MAIN_LOG}" ]]; then
        local size=$(du -h "${MAIN_LOG}" | cut -f1)
        local lines=$(wc -l < "${MAIN_LOG}")
        local errors=$(grep -c "\[ERROR\]" "${MAIN_LOG}" 2>/dev/null || echo "0")
        local warnings=$(grep -c "\[WARNING\]" "${MAIN_LOG}" 2>/dev/null || echo "0")

        echo "Log principal:"
        echo "  Fichier:        ${MAIN_LOG}"
        echo "  Taille:         $size"
        echo "  Lignes:         $lines"
        echo "  Erreurs:        $errors"
        echo "  Avertissements: $warnings"
        echo ""
    fi

    # Logs archivés
    local archived_count=$(find "${LOGS_DIR}" -name "*.log.gz" -type f 2>/dev/null | wc -l)
    local archived_size=$(du -sh "${LOGS_DIR}" 2>/dev/null | cut -f1)

    echo "Logs archivés:"
    echo "  Nombre:         $archived_count"
    echo "  Taille totale:  $archived_size"
    echo ""
}

# Exporter les logs d'une période spécifique
export_logs() {
    local start_date="$1"
    local end_date="${2:-$(date +%Y-%m-%d)}"
    local output_file="${LOGS_DIR}/export_${start_date}_to_${end_date}.log"

    log_info "Export des logs de $start_date à $end_date"

    # Extraire les logs de la période
    {
        echo "================================================================================"
        echo "EXPORT DES LOGS: $start_date à $end_date"
        echo "Généré le: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================================"
        echo ""

        # Extraire du log principal
        if [[ -f "${MAIN_LOG}" ]]; then
            awk -v start="$start_date" -v end="$end_date" '
                $0 ~ /^\[/ {
                    date = substr($1, 2, 10)
                    if (date >= start && date <= end) print
                }
            ' "${MAIN_LOG}"
        fi

        # Extraire des logs archivés
        find "${LOGS_DIR}" -name "*.log.gz" -type f -exec zcat {} \; | \
        awk -v start="$start_date" -v end="$end_date" '
            $0 ~ /^\[/ {
                date = substr($1, 2, 10)
                if (date >= start && date <= end) print
            }
        '

    } > "$output_file"

    log_success "Logs exportés: $output_file"
    echo "$output_file"
}

# Surveiller les logs en temps réel (tail -f like)
watch_logs() {
    local lines="${1:-50}"

    log_info "Surveillance des logs en temps réel (Ctrl+C pour arrêter)"
    echo ""

    tail -f -n "$lines" "${MAIN_LOG}"
}

# Rechercher dans les logs
search_logs() {
    local pattern="$1"
    local case_sensitive="${2:-false}"

    log_info "Recherche dans les logs: '$pattern'"

    local grep_opts="-n"
    if [[ "$case_sensitive" != "true" ]]; then
        grep_opts="$grep_opts -i"
    fi

    # Rechercher dans le log principal
    echo ""
    echo "Résultats dans ${MAIN_LOG}:"
    echo "──────────────────────────────────────────────────────────────"
    grep $grep_opts "$pattern" "${MAIN_LOG}" || echo "Aucun résultat trouvé"

    # Rechercher dans les logs archivés
    local archived_results=$(find "${LOGS_DIR}" -name "*.log.gz" -type f -exec zgrep -l $grep_opts "$pattern" {} \;)

    if [[ -n "$archived_results" ]]; then
        echo ""
        echo "Résultats dans les archives:"
        echo "──────────────────────────────────────────────────────────────"
        echo "$archived_results"
    fi
}
