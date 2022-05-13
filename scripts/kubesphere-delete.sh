#!/usr/bin/env bash

function delete_sure(){
  cat << eof
$(echo -e "\033[1;36mNote:\033[0m")

Delete the KylinCloud cluster, including the module kylincloud-system kylincloud-devops-system kylincloud-monitoring-system kylincloud-logging-system openpitrix-system.
eof

read -p "Please reconfirm that you want to delete the KylinCloud cluster.  (yes/no) " ans
while [[ "x"$ans != "xyes" && "x"$ans != "xno" ]]; do
    read -p "Please reconfirm that you want to delete the KylinCloud cluster.  (yes/no) " ans
done

if [[ "x"$ans == "xno" ]]; then
    exit
fi
}


delete_sure

# delete ky-install
kubectl delete deploy ky-installer -n kylincloud-system 2>/dev/null

# delete helm
for namespaces in kylincloud-system kylincloud-devops-system kylincloud-monitoring-system kylincloud-logging-system openpitrix-system kylincloud-monitoring-federated
do
  helm list -n $namespaces | grep -v NAME | awk '{print $1}' | sort -u | xargs -r -L1 helm uninstall -n $namespaces 2>/dev/null
done

# delete kubefed
kubectl get cc -n kylincloud-system ky-installer -o jsonpath="{.status.multicluster}" | grep enable
if [[ $? -eq 0 ]]; then
  helm uninstall -n kube-federation-system kubefed 2>/dev/null
  #kubectl delete ns kube-federation-system 2>/dev/null
fi


helm uninstall -n kube-system snapshot-controller 2>/dev/null

# delete kylincloud deployment
kubectl delete deployment -n kylincloud-system `kubectl get deployment -n kylincloud-system -o jsonpath="{.items[*].metadata.name}"` 2>/dev/null

# delete monitor statefulset
kubectl delete prometheus -n kylincloud-monitoring-system k8s 2>/dev/null
kubectl delete statefulset -n kylincloud-monitoring-system `kubectl get statefulset -n kylincloud-monitoring-system -o jsonpath="{.items[*].metadata.name}"` 2>/dev/null
# delete grafana
kubectl delete deployment -n kylincloud-monitoring-system grafana 2>/dev/null
kubectl --no-headers=true get pvc -n kylincloud-monitoring-system -o custom-columns=:metadata.namespace,:metadata.name | grep -E kylincloud-monitoring-system | xargs -n2 kubectl delete pvc -n 2>/dev/null

# delete pvc
pvcs="kylincloud-system|openpitrix-system|kylincloud-devops-system|kylincloud-logging-system"
kubectl --no-headers=true get pvc --all-namespaces -o custom-columns=:metadata.namespace,:metadata.name | grep -E $pvcs | xargs -n2 kubectl delete pvc -n 2>/dev/null


# delete rolebindings
delete_role_bindings() {
  for rolebinding in `kubectl -n $1 get rolebindings -l iam.kylincloud.io/user-ref -o jsonpath="{.items[*].metadata.name}"`
  do
    kubectl -n $1 delete rolebinding $rolebinding 2>/dev/null
  done
}

# delete roles
delete_roles() {
  kubectl -n $1 delete role admin 2>/dev/null
  kubectl -n $1 delete role operator 2>/dev/null
  kubectl -n $1 delete role viewer 2>/dev/null
  for role in `kubectl -n $1 get roles -l iam.kylincloud.io/role-template -o jsonpath="{.items[*].metadata.name}"`
  do
    kubectl -n $1 delete role $role 2>/dev/null
  done
}

# remove useless labels and finalizers
for ns in `kubectl get ns -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl label ns $ns kylincloud.io/workspace-
  kubectl label ns $ns kylincloud.io/namespace-
  kubectl patch ns $ns -p '{"metadata":{"finalizers":null,"ownerReferences":null}}'
  delete_role_bindings $ns
  delete_roles $ns
done

# delete clusters
for cluster in `kubectl get clusters -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch cluster $cluster -p '{"metadata":{"finalizers":null}}' --type=merge
done
kubectl delete clusters --all 2>/dev/null

# delete workspaces
for ws in `kubectl get workspaces -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch workspace $ws -p '{"metadata":{"finalizers":null}}' --type=merge
done
kubectl delete workspaces --all 2>/dev/null

# delete devopsprojects
for devopsproject in `kubectl get devopsprojects -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch devopsprojects $devopsproject -p '{"metadata":{"finalizers":null}}' --type=merge
done

for pip in `kubectl get pipeline -A -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch pipeline $pip -n `kubectl get pipeline -A | grep $pip | awk '{print $1}'` -p '{"metadata":{"finalizers":null}}' --type=merge
done

for s2ibinaries in `kubectl get s2ibinaries -A -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch s2ibinaries $s2ibinaries -n `kubectl get s2ibinaries -A | grep $s2ibinaries | awk '{print $1}'` -p '{"metadata":{"finalizers":null}}' --type=merge
done

for s2ibuilders in `kubectl get s2ibuilders -A -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch s2ibuilders $s2ibuilders -n `kubectl get s2ibuilders -A | grep $s2ibuilders | awk '{print $1}'` -p '{"metadata":{"finalizers":null}}' --type=merge
done

for s2ibuildertemplates in `kubectl get s2ibuildertemplates -A -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch s2ibuildertemplates $s2ibuildertemplates -n `kubectl get s2ibuildertemplates -A | grep $s2ibuildertemplates | awk '{print $1}'` -p '{"metadata":{"finalizers":null}}' --type=merge
done

for s2iruns in `kubectl get s2iruns -A -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch s2iruns $s2iruns -n `kubectl get s2iruns -A | grep $s2iruns | awk '{print $1}'` -p '{"metadata":{"finalizers":null}}' --type=merge
done

kubectl delete devopsprojects --all 2>/dev/null


# delete validatingwebhookconfigurations
for webhook in ky-events-admission-validate users.iam.kylincloud.io network.kylincloud.io validating-webhook-configuration
do
  kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io $webhook 2>/dev/null
done

# delete mutatingwebhookconfigurations
for webhook in ky-events-admission-mutate logsidecar-injector-admission-mutate mutating-webhook-configuration
do
  kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io $webhook 2>/dev/null
done

# delete users
for user in `kubectl get users -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch user $user -p '{"metadata":{"finalizers":null}}' --type=merge
done
kubectl delete users --all 2>/dev/null


# delete helm resources
for resource_type in `echo helmcategories helmapplications helmapplicationversions helmrepos helmreleases`; do
  for resource_name in `kubectl get ${resource_type}.application.kylincloud.io -o jsonpath="{.items[*].metadata.name}"`; do
    kubectl patch ${resource_type}.application.kylincloud.io ${resource_name} -p '{"metadata":{"finalizers":null}}' --type=merge
  done
  kubectl delete ${resource_type}.application.kylincloud.io --all 2>/dev/null
done

# delete workspacetemplates
for workspacetemplate in `kubectl get workspacetemplates.tenant.kylincloud.io -o jsonpath="{.items[*].metadata.name}"`
do
  kubectl patch workspacetemplates.tenant.kylincloud.io $workspacetemplate -p '{"metadata":{"finalizers":null}}' --type=merge
done
kubectl delete workspacetemplates.tenant.kylincloud.io --all 2>/dev/null

# delete federatednamespaces in namespace kylincloud-monitoring-federated
for resource in $(kubectl get federatednamespaces.types.kubefed.io -n kylincloud-monitoring-federated -oname); do
  kubectl patch "${resource}" -p '{"metadata":{"finalizers":null}}' --type=merge -n kylincloud-monitoring-federated
done

# delete crds
for crd in `kubectl get crds -o jsonpath="{.items[*].metadata.name}"`
do
  if [[ $crd == *kylincloud.io ]]; then kubectl delete crd $crd 2>/dev/null; fi
done

# delete relevance ns
for ns in kylincloud-alerting-system kylincloud-controls-system kylincloud-devops-system kylincloud-logging-system kylincloud-monitoring-system kylincloud-monitoring-federated openpitrix-system kylincloud-system
do
  kubectl delete ns $ns 2>/dev/null
done

