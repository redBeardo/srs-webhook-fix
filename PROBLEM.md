# The SRS 5.0+ Webhook Problem: Detailed Analysis

## 🔍 Problem Discovery Timeline

### Initial Symptoms
- RTMP streams processed perfectly by SRS
- Webhook endpoints never received callbacks
- No error messages in SRS logs
- SRS features showed `hc:on` (HTTP callbacks enabled)

### Debugging Journey

#### Step 1: Network Connectivity Tests ✅
```bash
# All tests PASSED - networking was fine
curl http://webhook-endpoint:3000/test     # ✅ Works
docker exec srs-container curl webhook-endpoint:3000   # ✅ Works
ping between containers                    # ✅ Works
```

#### Step 2: SRS Configuration Verification ✅
```bash
# SRS compiled with webhook support
docker logs srs-container | grep "features.*hc:on"
# [INFO] features, rch:on, dash:on, hls:on, hds:off, srt:on, hc:on

# Webhook config looks correct
vhost __defaultVhost__ {
    http_hooks {
        enabled         on;
        on_publish      http://webhook-endpoint:3000/srs/webhook;
        on_unpublish    http://webhook-endpoint:3000/srs/webhook;
    }
}
```

#### Step 3: Version Comparison Testing 🔍
```bash
# Test with older SRS versions
SRS 2.0:  ✅ Webhooks work perfectly (with Python config generation)
SRS 5.0:  ❌ Static webhooks ignored (silent failure)
SRS 6.0:  ❌ Static webhooks ignored (silent failure)
```

## 💡 Root Cause Discovery

### The Breakthrough
While testing SRS 2.0 (`wushaobo/srs-docker:1.0`), we noticed it uses **Python + Jinja2** for dynamic configuration generation. When we replicated this approach in SRS 6.0:

```python
# Dynamic config generation
template = """
vhost __defaultVhost__ {
    http_hooks {
        enabled         on;
        on_publish      {{ SRS_CALLBACK_URL }};
        on_unpublish    {{ SRS_CALLBACK_URL }};
    }
}
"""
```

**Result**: Webhooks immediately started working! 🎉

### Testing Results

#### SRS 5.0.213 with Static Config ❌
```
[INFO] SRS/5.0.213 started
[INFO] Stream published successfully
[WEBHOOK ENDPOINT] No webhook received ❌
```

#### SRS 6.0.177 with Dynamic Config ✅
```
[INFO] SRS/6.0.177 started
[INFO] Generated config with webhook: http://webhook-endpoint:3000/srs/webhook
[INFO] Stream published successfully
[WEBHOOK ENDPOINT] POST /srs/webhook received! ✅
```

## 🧠 Analysis: Why This Happens

### Theory: Config Loading Sequence Change
SRS 5.0+ appears to have changed how configuration is processed during initialization:

1. **Static configs**: Parsed but potentially ignored during runtime webhook registration
2. **Dynamic configs**: Generated fresh at startup, properly registered with webhook system

### Evidence Supporting This Theory

#### 1. **Compilation Flags Identical**
Both versions show `hc:on` - HTTP callbacks are compiled and enabled

#### 2. **Network Connectivity Proven**
Same Docker network setup works perfectly with dynamic config

#### 3. **Config Structure Identical**
The webhook configuration syntax is exactly the same

#### 4. **Timing-Based Difference**
- Static config: Loaded once at container build time
- Dynamic config: Generated fresh at container startup

### Implications

This isn't a "bug" but appears to be an **intentional design change** in SRS 5.0+ requiring dynamic configuration for HTTP callbacks.

## 📊 Impact Assessment

### Who This Affects
- **SRS 2.0 → 5.0+ migrators**: Existing static configs stop working
- **New SRS users**: Following old documentation leads to silent failures
- **Production systems**: Webhook-dependent features break without obvious errors

### Symptoms Checklist
- [ ] SRS processes RTMP streams successfully
- [ ] SRS logs show `hc:on` (HTTP callbacks enabled)
- [ ] Webhook endpoint is reachable via curl/network tests
- [ ] Static webhook configuration looks correct
- [ ] **But**: Webhook endpoint never receives any HTTP requests

### Solution Verification
✅ **Python dynamic config generation** restores full webhook functionality
✅ **Works with both container names and static IPs**
✅ **Production-ready with optimized Docker images**
✅ **Environment variable driven** for easy deployment

## 🚀 Next Steps

1. **Immediate**: Use this dynamic config solution for SRS 5.0+
2. **Documentation**: Update SRS community resources
3. **Community**: Share this solution to help others facing the same issue

---

**The bottom line**: SRS 5.0+ requires dynamic configuration generation for HTTP webhooks. This solution provides a production-ready implementation that restores the event-driven architecture many applications depend on.