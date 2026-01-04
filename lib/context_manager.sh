#!/bin/bash

################################################################################
# MODULE DE GESTION DU CONTEXTE GLOBAL
# Description: Gestion du fichier context_global.json
# Fonctions: Création, lecture, mise à jour du contexte global
################################################################################

# ==============================================================================
# FONCTIONS DE GESTION DU CONTEXTE GLOBAL
# ==============================================================================

# Initialiser le contexte global
initialize_global_context() {
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    cat > "${GLOBAL_CONTEXT}" << EOF
{
  "version": "1.0.0",
  "created_at": "${timestamp}",
  "last_updated": "${timestamp}",
  "claude_code": {
    "installed": false,
    "version": null,
    "installation_date": null
  },
  "projects": [],
  "statistics": {
    "total_projects": 0,
    "active_projects": 0,
    "total_executions": 0
  },
  "configuration": {
    "auto_update": true,
    "log_retention_days": 30,
    "max_projects": 100
  }
}
EOF

    log_success "Contexte global initialisé: ${GLOBAL_CONTEXT}"
}

# Mettre à jour le statut d'installation de Claude Code
update_claude_installation_status() {
    local is_installed="$1"
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    if [[ ! -f "${GLOBAL_CONTEXT}" ]]; then
        log_error "Le fichier de contexte global n'existe pas"
        return 1
    fi

    local version="null"
    if [[ "$is_installed" == "true" ]]; then
        # Récupérer la version de Claude Code
        if command -v claude &> /dev/null; then
            version=$(claude --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
            version="\"${version}\""
        fi
    fi

    # Mettre à jour le contexte avec jq
    local temp_file=$(mktemp)
    jq --arg installed "$is_installed" \
       --arg version "$version" \
       --arg date "$timestamp" \
       '.claude_code.installed = ($installed == "true") |
        .claude_code.version = if ($version == "null") then null else $version end |
        .claude_code.installation_date = if ($installed == "true") then $date else .claude_code.installation_date end |
        .last_updated = $date' \
        "${GLOBAL_CONTEXT}" > "$temp_file"

    mv "$temp_file" "${GLOBAL_CONTEXT}"
    log_info "Statut d'installation mis à jour: Claude Code installé = $is_installed"
}

# Scanner les projets existants et mettre à jour le contexte
scan_and_update_projects() {
    if [[ ! -d "${PROJECTS_DIR}" ]]; then
        log_warning "Le répertoire des projets n'existe pas encore"
        return 0
    fi

    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local projects_array="[]"

    # Scanner les sous-répertoires du dossier projects
    if ls -d "${PROJECTS_DIR}"/*/ &> /dev/null; then
        for project_dir in "${PROJECTS_DIR}"/*/; do
            if [[ -d "$project_dir" ]]; then
                local project_name=$(basename "$project_dir")
                local context_file="${project_dir}/context.md"
                local journal_file="${project_dir}/journal.log"

                # Vérifier que le projet a les fichiers requis
                local is_active=false
                if [[ -f "$context_file" && -f "$journal_file" ]]; then
                    is_active=true
                fi

                # Créer l'objet projet
                local project_obj=$(jq -n \
                    --arg name "$project_name" \
                    --arg dir "$project_dir" \
                    --arg active "$is_active" \
                    --arg updated "$timestamp" \
                    '{
                        name: $name,
                        path: $dir,
                        active: ($active == "true"),
                        created_at: $updated,
                        last_updated: $updated
                    }')

                # Ajouter au tableau
                projects_array=$(echo "$projects_array" | jq --argjson proj "$project_obj" '. + [$proj]')
            fi
        done
    fi

    # Compter les projets
    local total_projects=$(echo "$projects_array" | jq 'length')
    local active_projects=$(echo "$projects_array" | jq '[.[] | select(.active == true)] | length')

    # Mettre à jour le contexte global
    local temp_file=$(mktemp)
    jq --argjson projects "$projects_array" \
       --arg total "$total_projects" \
       --arg active "$active_projects" \
       --arg updated "$timestamp" \
       '.projects = $projects |
        .statistics.total_projects = ($total | tonumber) |
        .statistics.active_projects = ($active | tonumber) |
        .last_updated = $updated' \
        "${GLOBAL_CONTEXT}" > "$temp_file"

    mv "$temp_file" "${GLOBAL_CONTEXT}"
    log_info "Projets scannés: $total_projects total, $active_projects actifs"
}

# Incrémenter le compteur d'exécutions
increment_execution_counter() {
    local temp_file=$(mktemp)
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    jq --arg updated "$timestamp" \
       '.statistics.total_executions += 1 |
        .last_updated = $updated' \
        "${GLOBAL_CONTEXT}" > "$temp_file"

    mv "$temp_file" "${GLOBAL_CONTEXT}"
}

# Récupérer la liste des projets actifs
get_active_projects() {
    if [[ ! -f "${GLOBAL_CONTEXT}" ]]; then
        echo "[]"
        return
    fi

    jq -r '[.projects[] | select(.active == true) | .name]' "${GLOBAL_CONTEXT}"
}

# Récupérer tous les projets
get_all_projects() {
    if [[ ! -f "${GLOBAL_CONTEXT}" ]]; then
        echo "[]"
        return
    fi

    jq -r '[.projects[] | .name]' "${GLOBAL_CONTEXT}"
}

# Afficher le statut global
show_global_status() {
    if [[ ! -f "${GLOBAL_CONTEXT}" ]]; then
        log_error "Fichier de contexte global introuvable"
        return 1
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              STATUT DU SYSTÈME CLAUDE CODE                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Extraire les informations
    local claude_installed=$(jq -r '.claude_code.installed' "${GLOBAL_CONTEXT}")
    local claude_version=$(jq -r '.claude_code.version // "N/A"' "${GLOBAL_CONTEXT}")
    local total_projects=$(jq -r '.statistics.total_projects' "${GLOBAL_CONTEXT}")
    local active_projects=$(jq -r '.statistics.active_projects' "${GLOBAL_CONTEXT}")
    local total_executions=$(jq -r '.statistics.total_executions' "${GLOBAL_CONTEXT}")
    local last_updated=$(jq -r '.last_updated' "${GLOBAL_CONTEXT}")

    echo "Claude Code installé:     $claude_installed"
    echo "Version:                   $claude_version"
    echo "Total de projets:          $total_projects"
    echo "Projets actifs:            $active_projects"
    echo "Exécutions totales:        $total_executions"
    echo "Dernière mise à jour:      $last_updated"
    echo ""

    # Lister les projets
    if [[ "$total_projects" -gt 0 ]]; then
        echo "Projets enregistrés:"
        jq -r '.projects[] | "  - \(.name) (\(if .active then "actif" else "inactif" end))"' "${GLOBAL_CONTEXT}"
        echo ""
    fi
}

# Vérifier si un projet existe dans le contexte
project_exists_in_context() {
    local project_name="$1"

    if [[ ! -f "${GLOBAL_CONTEXT}" ]]; then
        return 1
    fi

    local exists=$(jq -r --arg name "$project_name" \
        '.projects[] | select(.name == $name) | .name' \
        "${GLOBAL_CONTEXT}")

    if [[ -n "$exists" ]]; then
        return 0
    else
        return 1
    fi
}

# Ajouter un projet au contexte
add_project_to_context() {
    local project_name="$1"
    local project_path="${PROJECTS_DIR}/${project_name}"
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Vérifier si le projet existe déjà
    if project_exists_in_context "$project_name"; then
        log_warning "Le projet '$project_name' existe déjà dans le contexte"
        return 0
    fi

    # Créer l'objet projet
    local project_obj=$(jq -n \
        --arg name "$project_name" \
        --arg path "$project_path" \
        --arg created "$timestamp" \
        '{
            name: $name,
            path: $path,
            active: true,
            created_at: $created,
            last_updated: $created
        }')

    # Ajouter au contexte
    local temp_file=$(mktemp)
    jq --argjson proj "$project_obj" \
       --arg updated "$timestamp" \
       '.projects += [$proj] |
        .statistics.total_projects += 1 |
        .statistics.active_projects += 1 |
        .last_updated = $updated' \
        "${GLOBAL_CONTEXT}" > "$temp_file"

    mv "$temp_file" "${GLOBAL_CONTEXT}"
    log_success "Projet '$project_name' ajouté au contexte global"
}

# Exporter le contexte vers un format lisible
export_context_report() {
    local output_file="${LOGS_DIR}/context_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "═══════════════════════════════════════════════════════════"
        echo "  RAPPORT DU CONTEXTE GLOBAL - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        show_global_status
        echo ""
        echo "Contenu JSON complet:"
        echo "-----------------------------------------------------------"
        jq '.' "${GLOBAL_CONTEXT}"
    } > "$output_file"

    log_success "Rapport exporté: $output_file"
    echo "$output_file"
}
