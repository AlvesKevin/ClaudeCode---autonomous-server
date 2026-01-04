#!/bin/bash

################################################################################
# MODULE DE GESTION DES PROJETS
# Description: Création, gestion et maintenance des projets
# Fonctions: Création de projets, gestion du contexte et du journal
################################################################################

# ==============================================================================
# FONCTIONS DE GESTION DES PROJETS
# ==============================================================================

# Créer un nouveau projet
create_project() {
    local project_name="$1"

    # Valider le nom du projet
    if [[ -z "$project_name" ]]; then
        log_error "Le nom du projet ne peut pas être vide"
        return 1
    fi

    # Vérifier les caractères autorisés (lettres, chiffres, underscore, tiret)
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Nom de projet invalide. Utilisez uniquement: lettres, chiffres, _ et -"
        return 1
    fi

    local project_dir="${PROJECTS_DIR}/${project_name}"

    # Vérifier si le projet existe déjà
    if [[ -d "$project_dir" ]]; then
        log_error "Le projet '$project_name' existe déjà"
        return 1
    fi

    log_info "Création du projet: $project_name"

    # Créer le répertoire du projet
    mkdir -p "$project_dir"

    # Créer le fichier de contexte
    create_project_context "$project_name"

    # Créer le fichier de journal
    create_project_journal "$project_name"

    # Créer un fichier de configuration optionnel
    create_project_config "$project_name"

    # Ajouter le projet au contexte global
    add_project_to_context "$project_name"

    log_success "Projet '$project_name' créé avec succès"
    log_info "Répertoire: $project_dir"
    log_info "Contexte: ${project_dir}/context.md"
    log_info "Journal: ${project_dir}/journal.log"
}

# Créer le fichier de contexte d'un projet
create_project_context() {
    local project_name="$1"
    local context_file="${PROJECTS_DIR}/${project_name}/context.md"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "$context_file" << EOF
# Contexte du Projet: ${project_name}

**Créé le:** ${timestamp}
**Dernière mise à jour:** ${timestamp}

---

## Description du Projet

[Décrivez ici l'objectif et la portée de ce projet]

---

## Objectifs

- [ ] Objectif 1: À définir
- [ ] Objectif 2: À définir
- [ ] Objectif 3: À définir

---

## État Actuel

**Statut:** Nouveau projet
**Progression:** 0%

### Tâches en Cours

Aucune tâche en cours pour le moment.

### Tâches Complétées

Aucune tâche complétée pour le moment.

---

## Notes et Observations

### $(date '+%Y-%m-%d')

- Projet initialisé
- En attente de configuration et de définition des objectifs

---

## Dépendances et Technologies

- Claude Code (Agent autonome)
- [Ajoutez vos dépendances ici]

---

## Historique des Décisions

### $(date '+%Y-%m-%d') - Création du projet

**Décision:** Initialisation du projet ${project_name}
**Raison:** Nouveau projet créé dans le système de workflow Claude Code
**Impact:** Structure de base créée, prête pour développement

---

## Prochaines Étapes

1. Définir les objectifs du projet
2. Identifier les ressources nécessaires
3. Établir un plan d'action
4. Commencer l'implémentation

---

## Ressources et Références

- [Ajoutez vos liens et ressources ici]

---

*Dernière synchronisation: ${timestamp}*
EOF

    log_success "Fichier de contexte créé: $context_file"
}

# Créer le fichier de journal d'un projet
create_project_journal() {
    local project_name="$1"
    local journal_file="${PROJECTS_DIR}/${project_name}/journal.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "$journal_file" << EOF
================================================================================
JOURNAL DU PROJET: ${project_name}
Créé le: ${timestamp}
================================================================================

[${timestamp}] [INFO] Projet initialisé
[${timestamp}] [INFO] Structure de base créée
[${timestamp}] [INFO] En attente de première exécution de l'agent

================================================================================
EOF

    log_success "Fichier de journal créé: $journal_file"
}

# Créer le fichier de configuration d'un projet
create_project_config() {
    local project_name="$1"
    local config_file="${PROJECTS_DIR}/${project_name}/config.json"
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    cat > "$config_file" << EOF
{
  "project_name": "${project_name}",
  "created_at": "${timestamp}",
  "active": true,
  "schedule": {
    "enabled": true,
    "frequency": "daily"
  },
  "tasks": {
    "auto_analysis": true,
    "auto_documentation": true,
    "auto_testing": false
  },
  "notifications": {
    "enabled": false,
    "email": null
  },
  "custom_settings": {}
}
EOF

    log_success "Fichier de configuration créé: $config_file"
}

# Ajouter une entrée au journal d'un projet
add_journal_entry() {
    local project_name="$1"
    local message="$2"
    local level="${3:-INFO}"
    local journal_file="${PROJECTS_DIR}/${project_name}/journal.log"

    if [[ ! -f "$journal_file" ]]; then
        log_error "Journal du projet '$project_name' introuvable"
        return 1
    fi

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$journal_file"
}

# Mettre à jour le contexte d'un projet
update_project_context() {
    local project_name="$1"
    local section="$2"
    local content="$3"
    local context_file="${PROJECTS_DIR}/${project_name}/context.md"

    if [[ ! -f "$context_file" ]]; then
        log_error "Contexte du projet '$project_name' introuvable"
        return 1
    fi

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Ajouter une note dans la section Notes et Observations
    cat >> "$context_file" << EOF

### ${timestamp} - ${section}

${content}

EOF

    # Mettre à jour la date de dernière mise à jour
    sed -i.bak "s/\*Dernière synchronisation:.*/*Dernière synchronisation: ${timestamp}*/" "$context_file"
    rm -f "${context_file}.bak"

    log_success "Contexte du projet '$project_name' mis à jour"
}

# Lire le contexte d'un projet
read_project_context() {
    local project_name="$1"
    local context_file="${PROJECTS_DIR}/${project_name}/context.md"

    if [[ ! -f "$context_file" ]]; then
        log_error "Contexte du projet '$project_name' introuvable"
        return 1
    fi

    cat "$context_file"
}

# Lire le journal d'un projet
read_project_journal() {
    local project_name="$1"
    local lines="${2:-50}"  # Par défaut, afficher les 50 dernières lignes
    local journal_file="${PROJECTS_DIR}/${project_name}/journal.log"

    if [[ ! -f "$journal_file" ]]; then
        log_error "Journal du projet '$project_name' introuvable"
        return 1
    fi

    tail -n "$lines" "$journal_file"
}

# Lister tous les projets
list_all_projects() {
    if [[ ! -d "${PROJECTS_DIR}" ]]; then
        log_warning "Aucun projet trouvé"
        return 0
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   LISTE DES PROJETS                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    local count=0
    if ls -d "${PROJECTS_DIR}"/*/ &> /dev/null; then
        for project_dir in "${PROJECTS_DIR}"/*/; do
            if [[ -d "$project_dir" ]]; then
                local project_name=$(basename "$project_dir")
                local context_file="${project_dir}/context.md"
                local journal_file="${project_dir}/journal.log"
                local config_file="${project_dir}/config.json"

                echo "Projet: $project_name"
                echo "  Chemin: $project_dir"

                # Vérifier l'intégrité du projet
                if [[ -f "$context_file" ]]; then
                    echo "  ✓ Contexte: Présent"
                else
                    echo "  ✗ Contexte: Manquant"
                fi

                if [[ -f "$journal_file" ]]; then
                    local entries=$(grep -c "\[.*\]" "$journal_file" 2>/dev/null || echo "0")
                    echo "  ✓ Journal: Présent ($entries entrées)"
                else
                    echo "  ✗ Journal: Manquant"
                fi

                if [[ -f "$config_file" ]]; then
                    local active=$(jq -r '.active // "unknown"' "$config_file" 2>/dev/null || echo "unknown")
                    echo "  ✓ Configuration: Présent (Actif: $active)"
                fi

                echo ""
                ((count++))
            fi
        done
    fi

    if [[ $count -eq 0 ]]; then
        echo "Aucun projet trouvé."
        echo ""
        echo "Créez un nouveau projet avec:"
        echo "  ./run_agent.sh --new <nom_du_projet>"
        echo ""
    else
        echo "Total: $count projet(s)"
        echo ""
    fi
}

# Archiver un projet
archive_project() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    local archive_dir="${WORKFLOW_DIR}/archives"
    local timestamp=$(date '+%Y%m%d_%H%M%S')

    if [[ ! -d "$project_dir" ]]; then
        log_error "Le projet '$project_name' n'existe pas"
        return 1
    fi

    # Créer le répertoire d'archives
    mkdir -p "$archive_dir"

    # Créer une archive tar.gz
    local archive_file="${archive_dir}/${project_name}_${timestamp}.tar.gz"
    tar -czf "$archive_file" -C "${PROJECTS_DIR}" "$project_name"

    log_success "Projet archivé: $archive_file"

    # Demander confirmation avant suppression
    log_warning "Voulez-vous supprimer le projet actif ? (Cette action est irréversible)"
    echo "Archive créée: $archive_file"
}

# Obtenir les statistiques d'un projet
get_project_stats() {
    local project_name="$1"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    local journal_file="${project_dir}/journal.log"
    local context_file="${project_dir}/context.md"

    if [[ ! -d "$project_dir" ]]; then
        log_error "Le projet '$project_name' n'existe pas"
        return 1
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         STATISTIQUES DU PROJET: ${project_name}"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Comptage des entrées de journal
    if [[ -f "$journal_file" ]]; then
        local total_entries=$(grep -c "\[.*\]" "$journal_file" 2>/dev/null || echo "0")
        local error_entries=$(grep -c "\[ERROR\]" "$journal_file" 2>/dev/null || echo "0")
        local warning_entries=$(grep -c "\[WARNING\]" "$journal_file" 2>/dev/null || echo "0")
        local info_entries=$(grep -c "\[INFO\]" "$journal_file" 2>/dev/null || echo "0")

        echo "Entrées du journal:"
        echo "  Total:        $total_entries"
        echo "  Erreurs:      $error_entries"
        echo "  Avertissements: $warning_entries"
        echo "  Informations: $info_entries"
        echo ""
    fi

    # Analyse du contexte
    if [[ -f "$context_file" ]]; then
        local tasks_total=$(grep -c "^- \[" "$context_file" 2>/dev/null || echo "0")
        local tasks_done=$(grep -c "^- \[x\]" "$context_file" 2>/dev/null || echo "0")
        local tasks_pending=$(grep -c "^- \[ \]" "$context_file" 2>/dev/null || echo "0")

        echo "Tâches:"
        echo "  Total:        $tasks_total"
        echo "  Complétées:   $tasks_done"
        echo "  En attente:   $tasks_pending"
        echo ""
    fi

    # Taille du projet
    local project_size=$(du -sh "$project_dir" 2>/dev/null | cut -f1)
    echo "Taille du projet: $project_size"
    echo ""
}
