# 🤖 Claude Code - Autonomous Server Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Debian/Ubuntu](https://img.shields.io/badge/Platform-Debian%2FUbuntu-orange.svg)](https://www.debian.org/)
[![Powered by Claude](https://img.shields.io/badge/Powered%20by-Claude%20Code-blue.svg)](https://claude.ai/)

> Transform your Debian/Ubuntu server into a self-managed, autonomous system powered by Claude Code AI.

## 🌟 What is This?

An **intelligent, autonomous agent** that manages your entire server using Claude Code. It analyzes your system, makes decisions, creates projects, and maintains your infrastructure automatically - every day at midnight, or on-demand.

**Key Features:**
- 🔍 **Automatic System Analysis** - CPU, RAM, disk, security, services
- 🧠 **Autonomous Decision Making** - Claude decides what to work on
- 🛠️ **Auto-Project Creation** - Creates and manages projects automatically  
- 📋 **Priority Requests** - Tell Claude what you need, it handles the rest
- 🔐 **Security First** - Follows best practices for production deployments
- 📊 **Complete Logging** - Everything is documented and traceable
- ⏰ **Automated Execution** - Runs daily via cron or on-demand

## 🚀 Quick Start

### Installation (3 commands)

```bash
git clone https://github.com/AlvesKevin/ClaudeCode---autonomous-server.git
cd ClaudeCode---autonomous-server
sudo ./setup.sh
```

The installer will:
- ✅ Install dependencies (jq, curl, etc.)
- ✅ Install Claude Code CLI
- ✅ Authenticate you with Claude (one time)
- ✅ Configure cron for daily execution
- ✅ Set up log rotation

### Instant Usage

```bash
# Request a project
./run_agent.sh --request "Install Docker and Docker Compose"

# Run autonomous mode NOW
./run_agent.sh --run-now

# Check results
tail -f logs/claude_agent.log
```

## 💡 What Can Claude Do Autonomously?

Based on `config/system_directives.md`, Claude can:

### Infrastructure
- ✅ Install Docker, Docker Compose
- ✅ Configure firewall (ufw)
- ✅ Set up fail2ban
- ✅ Install monitoring (Netdata, Prometheus, Grafana)

### Applications
- ✅ Deploy Nginx with SSL (Let's Encrypt)
- ✅ Set up PostgreSQL, MySQL, Redis
- ✅ Configure reverse proxies (Traefik, Nginx)

### Security
- ✅ Harden SSH configuration
- ✅ Manage SSL certificates
- ✅ Set up VPN (WireGuard)
- ✅ Perform security audits

### DevOps
- ✅ CI/CD pipelines (Gitea + Drone)
- ✅ Private Docker registry
- ✅ Automated backups
- ✅ System monitoring & alerts

## 🎯 Core Commands

| Command | Description |
|---------|-------------|
| `./run_agent.sh --help` | Show all available commands |
| `./run_agent.sh --status` | Check system status |
| `./run_agent.sh --request "..."` | Add a priority project request |
| `./run_agent.sh --run-now` | Run autonomous mode immediately |
| `./run_agent.sh --list` | List all projects |
| `./run_agent.sh --new project` | Create a project manually |

## 📖 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[MODE_AUTONOME.md](MODE_AUTONOME.md)** - Deep dive into autonomous mode
- **[COMMANDES_RAPIDES.md](COMMANDES_RAPIDES.md)** - Command reference
- **[config/system_directives.md](config/system_directives.md)** - Claude's instructions

## 🔄 How It Works

```
┌─────────────────────────────────────────┐
│  Daily at Midnight (Cron)              │
│  OR Manual: ./run_agent.sh --run-now   │
└──────────────┬──────────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Collect System Info │
    │  - CPU, RAM, Disk    │
    │  - Security logs     │
    │  - Services status   │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Load Directives     │
    │  + Priority Requests │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Claude Analyzes     │
    │  - Identifies issues │
    │  - Proposes projects │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Auto-Create         │
    │  Projects            │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Execute & Document  │
    └──────────────────────┘
```

## 🛡️ Security

- **CLI Authentication**: Uses your Claude Code subscription (no API keys)
- **Full Traceability**: Every action is logged
- **Directive-Based**: Follows strict rules you define
- **Auditable**: Review everything Claude does

## 📋 Example Workflows

### New Server Setup

```bash
./run_agent.sh --request "Install Docker and Docker Compose"
./run_agent.sh --request "Configure firewall with basic rules"
./run_agent.sh --request "Secure SSH (fail2ban, port change)"
./run_agent.sh --request "Install Netdata monitoring"
./run_agent.sh --run-now
```

### Deploy Application Stack

```bash
./run_agent.sh --request "Install Nginx with SSL Let's Encrypt"
./run_agent.sh --request "Deploy PostgreSQL 15 in Docker"
./run_agent.sh --request "Set up Redis for caching"
./run_agent.sh --run-now
```

### Security Hardening

```bash
./run_agent.sh --request "Perform complete security audit"
./run_agent.sh --request "Update all system packages"
./run_agent.sh --request "Configure automated backups"
./run_agent.sh --run-now
```

## 📂 Project Structure

```
ClaudeCode---autonomous-server/
├── run_agent.sh              # Main script
├── setup.sh                  # Installation script
├── lib/                      # Core modules
│   ├── logger.sh            # Logging system
│   ├── context_manager.sh   # Global context management
│   ├── project_manager.sh   # Project lifecycle
│   ├── claude_tasks.sh      # Claude Code tasks
│   └── claude_autonomous.sh # Autonomous operations
├── config/
│   ├── system_directives.md # Instructions for Claude
│   └── project_requests.json # Priority requests (auto-created)
├── projects/                 # Managed projects (auto-created)
│   └── [project_name]/
│       ├── context.md       # Project memory
│       ├── journal.log      # Action log
│       └── config.json      # Project config
└── logs/                     # System logs (auto-created)
    ├── claude_agent.log
    └── autonomous_routine_*.log
```

## 🔧 Requirements

- **OS**: Debian 10+ or Ubuntu 20.04+
- **Architecture**: x86_64 / amd64
- **Claude Code**: Free CLI account
- **Dependencies**: Installed automatically (jq, curl, cron)

## 🎨 Customization

Edit `config/system_directives.md` to:
- Add your own project examples
- Modify priorities
- Define your preferred tech stack
- Add custom constraints

Claude will adapt to your preferences!

## 📊 Monitoring

```bash
# Main log
tail -f logs/claude_agent.log

# Today's system analysis
cat logs/claude_system_analysis_$(date +%Y%m%d)*.md

# Project journal
tail -f projects/my_project/journal.log

# Pending requests
cat config/project_requests.json | jq
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test on Debian/Ubuntu
4. Submit a pull request

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/AlvesKevin/ClaudeCode---autonomous-server/issues)
- **Documentation**: See `/docs` folder
- **Examples**: Check `COMMANDES_RAPIDES.md`

## ⭐ Star This Project

If this project helps you manage your server autonomously, please give it a star! ⭐

---

**Made with ❤️ using Claude Code**

Transform your server into an autonomous, self-improving system today! 🚀
