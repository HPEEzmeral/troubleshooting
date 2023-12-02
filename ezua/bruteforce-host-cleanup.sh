#!/bin/bash

if [ $(id -u) -ne 0 ];
then
  echo "This script must be executed as root user."
  echo
  exit 1
fi

if [[ "$1" != "-f" && "$1" != "--force" ]];
then
  echo "###########################################################"
  echo "The script    unconditionally deletes   all traces of EzUA"
  echo "and its related software from this host."
  echo
  echo "Hit   Ctrl+C    to stop executing this script now."

  sleep 10
 fi

exec 2>>/tmp/bruteforce-cleanup.xtrace
export PS4='$(date +%Y-%m-%d:%H-%M-%S):$$: ${BASH_SOURCE##*/} ${LINENO}: '
set -x


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


function stop_disable_services() {
    echo "Stopping service: $1"
    systemctl stop $1 || true
    systemctl disable --now $1 || true
    pkill -9 $1 >/dev/null || true
}

#stop and disable services
for i in ${ETCD} ${KUBE_APISERVER} ${KUBE_CONTROLLER_MANAGER} ${KUBE_SCHEDULER} ${KUBELET} ${KUBEPROXY};
do
  stop_disable_services $i
done

pkill -9 kube-rbac-proxy >/dev/null || true

# delete any containers still runing on the host.
echo "Removing all containers"
nerdctl --namespace k8s.io ps -a -q | xargs -I {} -n1 timeout 20 nerdctl --namespace k8s.io rm -f {} >/dev/null
nerdctl ps -a -q | xargs -I {} -n1 timeout 20 nerdctl --namespace k8s.io rm -f {} >/dev/null

stop_disable_services ${CONTAINERD}

# Look for any pvc mounts still lingering on the host.
echo "Unmounting CSI related mountpoints, if any"
for m in $(mount | grep -E "csi/driver.longhorn.io|kubernetes.io~csi/pvc" | awk '{print $3}' | xargs);
do
    umount -f $m || true
done

# attempt to unmount any lingering container mounts.
echo "Unmounting pod/container mounts, if any"
for m in $(mount | grep -E "containerd|kubelet|cni" | awk '{print $3}' | xargs);
do
    umount -f $m || true
done

# Unmount and clean up bindmounts we created
umount -f /var/lib/docker/kubelet
umount -f /var/lib/containerd/etcd
umount -f /var/lib/docker
sed -i'' -e "/\/var\/lib\/docker\/kubelet/d" -e "/\/var\/lib\/containerd\/etcd/d" -e "/\/var\/lib\/docker/d" /etc/fstab
rm -rf /var/lib/containerd/etcd /var/lib/docker/kubelet

# delete all the rpms
eval ${PACKAGE_MANAGER} remove -y ${ETCD} ${KUBE_APISERVER} ${KUBE_CONTROLLER_MANAGER} ${KUBE_SCHEDULER} ${CONTAINERD} ${KUBELET} ${KUBEPROXY} ${KUBECTL} ${KUBERNETES_CNI} ${KUBEADM} ${RUNC} ${CRICTL}
# Clean local repo caches
[[ "${PACKAGE_MANAGER}" == 'yum' ]] && eval ${PACKAGE_MANAGER} clean all || eval ${PACKAGE_MANAGER} clean

# Reload systemd manager configuration
systemctl daemon-reload

#uninstall the agent
if [ -e /usr/local/bin/uninstall-ezkf-agent.sh ];
then
  bash /usr/local/bin/uninstall-ezkf-agent.sh || true
else
  bash /usr/bin/uninstall-ezkf-agent.sh || true
fi


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
 /root/.kube /home/*/.kube \
 /var/lib/kubelet \
 /etc/zypp/repos.d/ezkube-*.repo \
 /etc/yum.repos.d/ezkube-*.repo \
 /tmp/ezkube-*.x86_64 /tmp/ezfab-release-* \
 /opt/ezkf /opt/ezkube /opt/cni /opt/containerd \
 /var/lib/kubelet /var/lib/calico \
 /var/log/ezkf /var/log/ezkube /var/log/calico \
 /run/netns/cni-*

# Reset iptables rules.
iptables -F || true
iptables -t nat -F || true
iptables -t mangle -F || true
iptables -X || true

if systemctl is-enabled firewalld >/dev/null;
then
   systemctl restart firewalld
fi

echo
echo "************************************************"
echo "Bruteforce cleanup of the host complete."
echo "The host is immediately reusable."
echo
