#!/usr/bin/env bash

# Install kubectl

curl -LO https://storage.googleapis.com/kubernetes-release/release/v"${KUBERNETES_VERSION}"/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

# Login to Kubernetes Cluster.
if [ -n "$CLUSTER_ROLE_ARN" ]; then
    aws eks \
        --region "${AWS_REGION}" \
        update-kubeconfig --name "${CLUSTER_NAME}" \
        --role-arn="${CLUSTER_ROLE_ARN}"
else
    aws eks \
        --region "${AWS_REGION}" \
        update-kubeconfig --name "${CLUSTER_NAME}" 
fi

# Helm Uninstall
UNINSTALL_COMMAND="helm uninstall ${DEPLOY_NAME} --timeout ${TIMEOUT}"
DELETE_NAMESPACE_COMMAND="kubectl delete ns ${DEPLOY_NAMESPACE}"
if [ -n "$DEPLOY_NAMESPACE" ]; then
    UNINSTALL_COMMAND="${UNINSTALL_COMMAND} -n ${DEPLOY_NAMESPACE}"
fi
if [ "$UNINSTALL" = "true" ] ; then
    echo "Executing: ${UNINSTALL_COMMAND}"
    ${UNINSTALL_COMMAND}
    if [ "$DELETE_NAMESPACE" = "true" ] ; then
        echo "Executing: ${DELETE_NAMESPACE_COMMAND}"
        ${DELETE_NAMESPACE_COMMAND}
    fi
    exit 0
fi

# Helm Deployment
DEPS_UPDATE_COMMAND="helm dependency update ${DEPLOY_CHART_PATH}"
UPGRADE_COMMAND="helm upgrade --timeout ${TIMEOUT}"
if [ -n "$FLAGS" ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} ${FLAGS}"
fi
for config_file in ${DEPLOY_CONFIG_FILES//,/ }
do
    UPGRADE_COMMAND="${UPGRADE_COMMAND} -f ${config_file}"
done
if [ -n "$DEPLOY_NAMESPACE" ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} -n ${DEPLOY_NAMESPACE}"
fi
if [ -n "$DEPLOY_VALUES" ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} --set ${DEPLOY_VALUES}"
fi
UPGRADE_COMMAND="${UPGRADE_COMMAND} ${DEPLOY_NAME} ${DEPLOY_CHART_PATH}"
echo "Executing: ${DEPS_UPDATE_COMMAND}"
${DEPS_UPDATE_COMMAND}
echo "Executing: ${UPGRADE_COMMAND}"
${UPGRADE_COMMAND}