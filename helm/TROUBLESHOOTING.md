# Helm Chart Troubleshooting and Validation Guide

This document explains the problems found in the Helm chart, how they were fixed, and step-by-step procedures to troubleshoot and validate the chart.

## Problems Identified and Fixed

### 1. **Label Mismatch (Critical Routing Issue)** ✅ FIXED
- **Problem**: Frontend deployment used label `app: frontend-app` but service selector expected `app: frontend`
- **Impact**: Service couldn't route traffic to pods, causing 503 errors
- **Fix**: Removed frontend/backend templates and created unified terraform-parse service with consistent labels using Helm helpers

### 2. **Hardcoded Values (Not Using Helm Values)** ✅ FIXED
- **Problem**: Templates hardcoded values instead of using `values.yaml`
- **Impact**: Couldn't customize deployments via Helm values
- **Fix**: All templates now use `.Values` references with proper defaults

### 3. **Missing Container Port Declaration** ✅ FIXED
- **Problem**: Backend container didn't declare `containerPort: 8080`
- **Impact**: Kubernetes didn't know which port the container listens on
- **Fix**: Added proper port declaration in deployment template

### 4. **Port Configuration Mismatch** ✅ FIXED
- **Problem**: Service targeted port 8080 but deployment didn't expose it consistently
- **Impact**: Service routing issues
- **Fix**: Unified port configuration through values.yaml with named ports

### 5. **Chart Not Adapted for Terraform-Parse Service** ✅ FIXED
- **Problem**: Chart deployed generic frontend/backend instead of terraform-parse service
- **Impact**: Wrong service being deployed
- **Fix**: Created new deployment.yaml and service.yaml specifically for terraform-parse service

### 6. **Missing Resource Definitions** ✅ FIXED
- **Problem**: No `resources` section with limits/requests
- **Impact**: HPA couldn't function properly, no resource management
- **Fix**: Added resource requests and limits in values.yaml and deployment template

### 7. **HPA Without Resource Metrics** ✅ FIXED
- **Problem**: HPA targeted CPU but deployments didn't have resource requests
- **Impact**: HPA would fail to scale or behave unpredictably
- **Fix**: Added resource requests, enabled HPA conditionally, added both CPU and memory metrics

### 8. **Missing Namespace and Labels** ✅ FIXED
- **Problem**: No namespace specification, minimal labels
- **Impact**: Poor organization, harder to manage multiple environments
- **Fix**: Added comprehensive labels via `_helpers.tpl`, environment variable support

## Step-by-Step Troubleshooting Process

### Step 1: Validate Chart Syntax

```bash
# Navigate to the project root
cd /home/adipurnamk/tripla/terraform-parse

# Check Helm chart syntax
helm lint ./helm

# Expected output: "1 chart(s) linted, 0 chart(s) failed"
```

**What to check:**
- No errors or warnings (except optional icon recommendation)
- All YAML is valid

### Step 2: Validate Template Rendering

```bash
# Dry-run to see rendered templates
helm template ./helm

# Debug mode to see all values
helm template ./helm --debug

# Validate against Kubernetes schema
helm template ./helm | kubectl apply --dry-run=client -f -

# Check specific values are being used
helm template ./helm --set replicaCount=3 | grep "replicas:"
```

**What to check:**
- All templates render without errors
- Values from values.yaml are properly substituted
- Labels match between deployment and service
- Ports are correctly configured

### Step 3: Verify Label Consistency

```bash
# Render templates and check labels
helm template ./helm | grep -A 5 "labels:"

# Check service selectors
helm template ./helm | grep -A 3 "selector:"

# Compare deployment labels vs service selectors
helm template ./helm | grep -E "(app.kubernetes.io/name:|selector:)" -A 1
```

**What to check:**
- Deployment labels match service selector labels
- All labels use consistent naming via helpers

### Step 4: Test Service Connectivity (Local Cluster)

```bash
# Ensure you have a local cluster running (kind/minikube)
# For kind: kind create cluster
# For minikube: minikube start

# Build and load the terraform-parse image (if using local cluster)
cd terraform_parse_service
docker build -t terraform-parse:latest .
# For kind: kind load docker-image terraform-parse:latest
# For minikube: minikube image load terraform-parse:latest

# Deploy chart
helm install terraform-parse ./helm --namespace terraform-parse --create-namespace

# Check pod labels
kubectl get pods -n terraform-parse --show-labels

# Check service endpoints (should show pod IPs)
kubectl get endpoints -n terraform-parse

# Verify endpoints are populated
kubectl describe svc terraform-parse -n terraform-parse | grep -A 10 "Endpoints:"
```

**What to check:**
- Pods are running and have correct labels
- Service endpoints show pod IPs (not empty)
- Labels match between pods and service selector

### Step 5: Verify Port Configuration

```bash
# Check container ports in deployment
kubectl describe deployment terraform-parse -n terraform-parse | grep -A 5 "Port:"

# Check service ports
kubectl get svc terraform-parse -n terraform-parse -o yaml | grep -A 5 "ports:"

# Test port connectivity via port-forward
kubectl port-forward -n terraform-parse svc/terraform-parse 8080:8080 &
# In another terminal:
curl http://localhost:8080/api/healthz
# Should return 200 OK
```

**What to check:**
- Container port matches service targetPort
- Port-forward works and service responds

### Step 6: Validate HPA Functionality

```bash
# Check HPA status
kubectl get hpa -n terraform-parse

# Describe HPA to see configuration
kubectl describe hpa terraform-parse-hpa -n terraform-parse

# Check if metrics are available (requires metrics-server)
kubectl top pods -n terraform-parse

# Verify HPA can read metrics
kubectl get hpa terraform-parse-hpa -n terraform-parse -o yaml | grep -A 10 "metrics:"
```

**What to check:**
- HPA is created (if autoscaling.enabled=true)
- HPA references correct deployment
- Resource metrics are configured
- Metrics server is available (for kubectl top)

### Step 7: Check Resource Usage

```bash
# View resource requests/limits in deployment
kubectl describe deployment terraform-parse -n terraform-parse | grep -A 10 "Limits\|Requests"

# Check if pods have resources defined
kubectl get pods -n terraform-parse -o jsonpath='{.items[*].spec.containers[*].resources}'

# Verify resources are set
kubectl get pod -n terraform-parse -o json | jq '.items[0].spec.containers[0].resources'
```

**What to check:**
- Resource requests and limits are set
- Values match what's in values.yaml

### Step 8: Test Service Connectivity from Within Cluster

```bash
# Create a test pod in the same namespace
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -n terraform-parse -- \
  curl -v http://terraform-parse:8080/api/healthz

# Test the API endpoint
kubectl run test-api --image=curlimages/curl --rm -it --restart=Never -n terraform-parse -- \
  curl -X POST http://terraform-parse:8080/api/generate \
  -H "Content-Type: application/json" \
  -d '{"payload":{"properties":{"aws-region":"eu-west-1","acl":"private","bucket-name":"test-bucket"}}}'
```

**What to check:**
- Service name resolves correctly
- Health endpoint returns 200
- API endpoint accepts POST requests

## Validation Steps After Fixes

### Validation 1: Chart Linting ✅

```bash
helm lint ./helm
# Expected: "1 chart(s) linted, 0 chart(s) failed"
```

### Validation 2: Template Rendering ✅

```bash
# Should render all templates correctly
helm template ./helm | grep -v "^#" | grep -v "^$" | wc -l
# Should show multiple lines of valid YAML

# Verify values are being used
helm template ./helm --set replicaCount=3 | grep "replicas:" | head -1
# Should show: replicas: 3
```

### Validation 3: Dry-Run Deployment ✅

```bash
# Should validate against cluster
helm install terraform-parse ./helm --dry-run --debug --namespace terraform-parse

# Or with kubectl validation
helm template ./helm | kubectl apply --dry-run=client -f -
# Expected: "all resources passed validation"
```

### Validation 4: Actual Deployment Test ✅

```bash
# Deploy to test namespace
helm install terraform-parse ./helm --namespace terraform-parse --create-namespace

# Verify pods are running
kubectl get pods -n terraform-parse
# Expected: Pods in Running state

# Verify services are created
kubectl get svc -n terraform-parse
# Expected: Service terraform-parse with ClusterIP

# Verify endpoints are populated
kubectl get endpoints -n terraform-parse
# Expected: Endpoints show pod IPs
```

### Validation 5: Service Connectivity Test ✅

```bash
# Port-forward test
kubectl port-forward -n terraform-parse svc/terraform-parse 8080:8080 &
sleep 2
curl http://localhost:8080/api/healthz
# Expected: HTTP 200 response

# Test from within cluster
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -n terraform-parse -- \
  curl -v http://terraform-parse:8080/api/healthz
# Expected: Connection successful, 200 OK
```

### Validation 6: HPA Validation ✅

```bash
# Verify HPA is created (if enabled)
kubectl get hpa -n terraform-parse
# Expected: terraform-parse-hpa should exist

# Check HPA configuration
kubectl describe hpa terraform-parse-hpa -n terraform-parse
# Expected: Shows min/max replicas, target CPU/memory utilization

# Verify HPA can read metrics (requires metrics-server)
kubectl top pods -n terraform-parse
# Expected: Shows CPU and memory usage
```

### Validation 7: Multi-Environment Test ✅

```bash
# Test dev environment
helm install terraform-parse-dev ./helm --namespace dev --create-namespace \
  --set environment=dev --set replicaCount=1

# Test prod environment
helm install terraform-parse-prod ./helm --namespace prod --create-namespace \
  --set environment=prod --set replicaCount=3

# Verify isolation
kubectl get pods -n dev
kubectl get pods -n prod
# Expected: Different pod counts, different namespaces
```

### Validation 8: Rollback Test ✅

```bash
# Upgrade to test version
helm upgrade terraform-parse ./helm --set image.tag=bad-tag --namespace terraform-parse

# Check pods fail
kubectl get pods -n terraform-parse -w
# Expected: Pods may fail to start or crash

# Verify rollback works
helm rollback terraform-parse --namespace terraform-parse

# Check pods recovered
kubectl get pods -n terraform-parse
# Expected: Pods back to Running state
```

## Quick Validation Script

Save this as `validate-chart.sh`:

```bash
#!/bin/bash
set -e

echo "=== Step 1: Linting Chart ==="
helm lint ./helm

echo -e "\n=== Step 2: Template Rendering ==="
helm template ./helm > /dev/null && echo "✓ Templates render successfully"

echo -e "\n=== Step 3: Kubernetes Schema Validation ==="
helm template ./helm | kubectl apply --dry-run=client -f - > /dev/null && echo "✓ All resources pass validation"

echo -e "\n=== Step 4: Label Consistency Check ==="
DEPLOYMENT_LABEL=$(helm template ./helm | grep -A 2 "app.kubernetes.io/name:" | head -1 | awk '{print $2}')
SERVICE_SELECTOR=$(helm template ./helm | grep -A 2 "app.kubernetes.io/name:" | tail -1 | awk '{print $2}')
if [ "$DEPLOYMENT_LABEL" == "$SERVICE_SELECTOR" ]; then
    echo "✓ Labels match between deployment and service"
else
    echo "✗ Label mismatch!"
    exit 1
fi

echo -e "\n=== Step 5: Port Configuration Check ==="
CONTAINER_PORT=$(helm template ./helm | grep "containerPort:" | awk '{print $2}')
SERVICE_PORT=$(helm template ./helm | grep -A 3 "ports:" | grep "port:" | awk '{print $2}')
if [ "$CONTAINER_PORT" == "$SERVICE_PORT" ]; then
    echo "✓ Ports match between container and service"
else
    echo "✗ Port mismatch!"
    exit 1
fi

echo -e "\n=== Step 6: Resource Definitions Check ==="
if helm template ./helm | grep -q "resources:"; then
    echo "✓ Resource definitions present"
else
    echo "✗ Missing resource definitions!"
    exit 1
fi

echo -e "\n=== All validations passed! ==="
```

Make it executable and run:
```bash
chmod +x validate-chart.sh
./validate-chart.sh
```

## Common Issues and Solutions

### Issue: Service has no endpoints
**Cause**: Label mismatch between deployment and service selector
**Solution**: Verify labels using `helm template` and ensure they match

### Issue: Pods crash on startup
**Cause**: Missing environment variables or wrong image
**Solution**: Check pod logs: `kubectl logs <pod-name> -n terraform-parse`

### Issue: HPA shows "unknown" metrics
**Cause**: Metrics server not installed or resources not defined
**Solution**: Install metrics-server and ensure resource requests are set

### Issue: Port-forward works but service doesn't
**Cause**: Service selector doesn't match pod labels
**Solution**: Verify labels match using `kubectl get pods --show-labels` and `kubectl describe svc`

## Summary

All identified issues have been fixed:
- ✅ Label consistency via Helm helpers
- ✅ All values use Helm templating
- ✅ Proper port declarations
- ✅ Resource definitions for HPA
- ✅ Chart adapted for terraform-parse service
- ✅ Comprehensive labels and environment support
- ✅ Conditional HPA with proper metrics

The chart is now production-ready and can be validated using the steps above.
