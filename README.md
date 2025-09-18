# SRS 5.0/6.0 Webhook Fix: Dynamic Configuration Solution

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![SRS](https://img.shields.io/badge/SRS-6.0-blue?style=for-the-badge)](https://github.com/ossrs/srs)
[![Python](https://img.shields.io/badge/python-3.9+-blue?style=for-the-badge&logo=python&logoColor=white)](https://python.org)

🔥 **Critical Solution**: Fixes silent webhook failures in SRS 5.0+ versions through dynamic configuration generation.

## 🚨 The Problem

**SRS 5.0+ versions ignore static webhook configurations**, causing silent failures where:
- ✅ RTMP streams process perfectly
- ❌ HTTP webhooks never trigger (no attempts made)
- 😤 No error messages or logs indicating the issue

### Affected Versions
- ✅ **SRS 2.0**: Static webhooks work
- ❌ **SRS 5.0+**: Static webhooks silently ignored
- ❌ **SRS 6.0**: Static webhooks silently ignored

## ✨ The Solution

**Dynamic configuration generation using Python + Jinja2** (replicating the SRS 2.0 approach):

### What Fails (Static Config)
```nginx
# This is IGNORED by SRS 5.0+
vhost __defaultVhost__ {
    http_hooks {
        enabled         on;
        on_publish      http://your-api:3000/webhook;
        on_unpublish    http://your-api:3000/webhook;
    }
}
```

### What Works (Dynamic Config)
```python
# Python generates config at runtime
template = """
vhost __defaultVhost__ {
    http_hooks {
        enabled         on;
        on_publish      {{ SRS_CALLBACK_URL }};
        on_unpublish    {{ SRS_CALLBACK_URL }};
    }
}
"""
render_template(template, {'SRS_CALLBACK_URL': os.environ['SRS_CALLBACK_URL']})
```

**Result**: SRS 5.0/6.0 webhooks fire immediately! 🎉

## 🚀 Quick Start

### 1. Clone & Run
```bash
git clone https://github.com/YOUR_USERNAME/srs-webhook-fix.git
cd srs-webhook-fix
cp docker-compose.example.yml docker-compose.yml

# Set your webhook endpoint
export SRS_CALLBACK_URL=http://your-api:3000/webhook/srs/publish

docker-compose up
```

### 2. Test Webhook
Stream to `rtmp://localhost:2935/live/test` and watch webhooks trigger:
```
[INFO] SRS/6.0 webhook: POST http://your-api:3000/webhook/srs/publish
```

## 📁 Repository Structure

```
srs-webhook-fix/
├── README.md                      # This guide
├── PROBLEM.md                     # Detailed problem analysis
├── Dockerfile.srs-optimized       # Production-ready SRS image
├── docker-compose.example.yml     # Complete working example
├── srs-custom-config/             # Python config generation system
│   ├── gen_conf/
│   │   ├── gen_conf.py           # Core Python script
│   │   └── venv/                 # Pre-installed Python environment
│   ├── templates/
│   │   └── srs.conf.j2          # Jinja2 configuration template
│   └── gen_conf_and_run.sh      # Container startup script
└── .gitignore                     # Excludes generated configs
```

## 🔧 How It Works

### 1. **Environment Variables**
```bash
SRS_CALLBACK_URL=http://your-api:3000/webhook/srs/publish
```

### 2. **Python Config Generation**
```python
def collect_context():
    env_vars = {key: val for key, val in os.environ.items()}
    if 'SRS_CALLBACK_URL' not in env_vars:
        env_vars['SRS_CALLBACK_URL'] = 'http://localhost:3000/webhook/srs/publish'
    return env_vars
```

### 3. **Jinja2 Template**
```jinja2
vhost __defaultVhost__ {
    http_hooks {
        enabled         on;
        on_publish      {{ SRS_CALLBACK_URL }};
        on_unpublish    {{ SRS_CALLBACK_URL }};
    }
}
```

### 4. **Runtime Generation**
The `gen_conf_and_run.sh` script:
1. Activates Python virtual environment
2. Generates SRS config from template + environment variables
3. Starts SRS with the dynamic configuration

## 📋 Requirements

- **Docker** (for containerized deployment)
- **Python 3.9+** (for config generation)
- **Jinja2** (template engine)

## 🎯 Use Cases

### Event-Driven RTMP Applications
- Real-time conference systems
- Live streaming platforms
- Video chat applications
- Broadcasting solutions

### Production Benefits
- ✅ **Reliable webhooks**: No more polling race conditions
- ✅ **Environment flexible**: Easy deployment across environments
- ✅ **Fast startup**: Pre-installed Python dependencies
- ✅ **Container native**: Works with Docker Compose and Kubernetes

## 🐛 Troubleshooting

### Webhooks Not Firing?
1. **Check SRS features**: `docker logs your-srs-container | grep "hc:on"`
2. **Verify config generation**: `docker logs your-srs-container | grep "Generated config"`
3. **Test network connectivity**: `curl http://your-webhook-endpoint`

### Common Issues
- **Wrong endpoint**: Ensure `SRS_CALLBACK_URL` points to correct service
- **Network issues**: Use container names, not localhost
- **Static config**: Don't mix static `.conf` files with this solution

## 🤝 Contributing

Found this useful? Help improve it:

1. **Star the repo** ⭐
2. **Report issues** - Others likely have the same problem
3. **Share your setup** - Add examples for different use cases
4. **Improve docs** - Make it easier for others to implement

## 📚 Additional Resources

- **SRS Documentation**: [SRS HTTP Callbacks](https://ossrs.io/lts/en-us/docs/v4/doc/http-callback)
- **Docker Best Practices**: Container networking and environment variables
- **Production Deployment**: Kubernetes, Docker Swarm examples

## 🏆 Impact

This solution restores **event-driven architecture** for SRS 5.0+ users, eliminating:
- 🚫 Polling race conditions
- 🚫 Split-brain room management scenarios
- 🚫 Silent webhook failures
- 🚫 Complex network debugging sessions

**Result**: Reliable, real-time RTMP stream detection with immediate webhook callbacks! 🎉

---

## 🙏 Acknowledgments

This solution emerged from debugging a critical production issue where SRS 6.0 webhooks were silently failing. After extensive testing across SRS versions, we discovered this isn't a bug but the proper implementation method for modern SRS versions.

**Community Impact**: This affects many SRS users who migrated from 2.0 to 5.0+ and experienced mysterious webhook failures. The solution provides a clear path forward with production-ready implementation.

---

**Made with ❤️ for the SRS community**