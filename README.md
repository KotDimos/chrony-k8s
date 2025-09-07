# Chrony-k8s

A special application for time synchronization in Kubernetes

# Configuration

Change list ntp servers (`NTP_SERVERS`) in DaemonSet. The separator between the servers is `,`
```bash
vim manifests/chrony.yaml
```

Example:
```yaml
env:
  - name: NTP_SERVERS
    value: time.nist.gov,us.pool.ntp.org,pool.ntp.org,time.google.com
```

# Deploy

Apply configuration:
```bash
kubectl apply -f manifests/chrony.yaml
```
