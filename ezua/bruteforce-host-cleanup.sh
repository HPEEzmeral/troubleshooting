#!/bin/bash


echo "###########################################################"
echo "The script    unconditionally deletes   all traces of EzUA"
echo "and its related software from this host."
echo
echo "Hit   Ctrl+C    to stop executing this script now."

sleep 10


ETCD=etcd
KUBE_APISERVER=kube-apiserver
KUBE_CONTROLLER_MANAGER=kube-controller-manager
KUBE_SCHEDULER=kube-scheduler
KUBELET=kubelet
KUBEPROXY=kube-proxy
KUBERNETES_CNI=kubernetes-cni
KUBEADM=kubeadm
CONTAINERD=containerd
KUBECTL=kubectl
RUNC=runc
CRICTL=crictl

PACKAGE_MANAGER=$([ -e '/usr/bin/yum' ] && echo "yum" || echo "zypper")

# Delete all kubernetes resources
${KUBECTL} delete all --all --force

# Delete all in kube-system namespace
${KUBECTL} delete all --all --namespace kube-system --force

# # Get all kubernetes resources
# ${KUBECTL} get all -A

# delete all containers on the host.
nerdctl --namespace k8s.io ps -a -q | xargs -I {} -n1 timeout 20 nerdctl --namespace k8s.io rm -f {}
nerdctl ps -a -q | xargs -I {} -n1 timeout 20 nerdctl --namespace k8s.io rm -f {}

#stop and disable services
for i in ${ETCD} ${KUBE_APISERVER} ${KUBE_CONTROLLER_MANAGER} ${KUBE_SCHEDULER} ${CONTAINERD} ${KUBELET} ${KUBEPROXY} ${KUBECTL} ${KUBERNETES_CNI} ${KUBEADM} ${RUNC} ${CRICTL}
do
    systemctl disable --now $i || true
    pkill -9 $1 >/dev/null || true 
done

# Look for any pvc mounts still lingering on the host.
for m in $(mount | grep -E "csi/driver.longhorn.io|kubernetes.io~csi/pvc" | awk '{print $3}' | xargs);
do
    umount -f $m || true
done

# Unmount and clean up bindmounts we created
umount -f /var/lib/docker/kubelet
umount -f /var/lib/containerd/etcd
umount -f umount -f /var/lib/docker
sed -i'' -e "/\/var\/lib\/docker\/kubelet/d" -e "/\/var\/lib\/containerd\/etcd/d" -e "/\/var\/lib\/docker/d" /etc/fstab
rm -rf /var/lib/containerd/etcd /var/lib/docker/kubelet

# delete all the rpms
eval ${PACKAGE_MANAGER} remove -y ${ETCD} ${KUBE_APISERVER} ${KUBE_CONTROLLER_MANAGER} ${KUBE_SCHEDULER} ${CONTAINERD} ${KUBELET} ${KUBEPROXY} ${KUBECTL} ${KUBERNETES_CNI} ${KUBEADM} ${RUNC} ${CRICTL}

# Reload systemd manager configuration
systemctl daemon-reload

# clean up following directories
rm -rf \
 /var/run/kubernetes \
 /etc/kubernetes/* \
 /etc/cni/net.d \
 /var/log/containers \
 /var/log/pods \
 /var/lib/etcd \
 /var/lib/cni \
 /var/lib/kube-proxy \
 /opt/ezkube/bundle/* \
 /etc/zypp/repos.d/ezkube-v* \
 /etc/yum.repos.d/ezkube-v*- \
 /root/.kube \
 /var/lib/kubelet

# Clean local repo caches
[[ "${PACKAGE_MANAGER}" == 'yum' ]] && eval ${PACKAGE_MANAGER} clean all || eval ${PACKAGE_MANAGER} clean

# Delete ezkube repo file from /etc/zypp/repo.d directory
rm -f /etc/zypp/repos.d/ezkube-*.repo
rm -f /etc/yum.repos.d/ezkube-*.repo

rm -rf /root/.kube /home/*/.kube

# remove files from /tmp
rm -rf /tmp/ezkube-*.x86_64 /tmp/ezfab-release-*

#uninstall the agent
bash /usr/local/bin/uninstall-ezkf-agent.sh || true

rm -rf /opt/ezkf /opt/ezkube /opt/cni /opt/containerd
rm -rf /var/lib/kubelet /var/lib/calico
rm -rf /var/log/ezkf /var/log/ezkube /var/log/calico

echo
echo "************************************************"
echo "Bruteforce cleanup of the host complete."
echo
echo "Reboot the host to restore it to reusable state."
