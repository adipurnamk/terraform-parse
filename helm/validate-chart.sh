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
