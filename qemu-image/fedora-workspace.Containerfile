FROM quay.io/fedora/fedora:39

ARG NODE_VERSION=v18.17.1
ARG USER_HOME_DIR="/home/user"
ARG WORK_DIR="/projects"
ENV HOME=${USER_HOME_DIR}
ENV BUILDAH_ISOLATION=chroot
ENV PATH=${PATH}:/projects/bin:/usr/local/node/bin
ENV VSCODE_NODEJS_RUNTIME_DIR="/usr/local/node/bin/"
COPY --chown=0:0 entrypoint.sh /
RUN dnf install -y openssh-clients libbrotli procps-ng git tar gzip zip xz unzip which shadow-utils bash zsh vi wget jq qemu-system-aarch64 guestfs-tools libbrotli podman buildah skopeo podman-docker ; \
  dnf update -y ; \
  dnf clean all ; \
  mkdir -p /usr/local ; \
  mkdir -p /tmp/node-install ; \
  curl -fsSL -o /tmp/node-install/node.tz https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz ; \
  tar -x --no-auto-compress -f /tmp/node-install/node.tz -C /tmp/node-install ; \
  mv /tmp/node-install/node-${NODE_VERSION}-linux-x64 /usr/local/node ; \
  rm -rf /tmp/node-install ; \
  mkdir -p ${USER_HOME_DIR} ; \
  mkdir -p ${WORK_DIR} ; \
  setcap cap_setuid+ep /usr/bin/newuidmap ; \
  setcap cap_setgid+ep /usr/bin/newgidmap ; \
  mkdir -p ${HOME}/.config/containers ; \
  (echo '[storage]';echo 'driver = "vfs"') > "${HOME}"/.config/containers/storage.conf ; \
  touch /etc/subgid /etc/subuid ; \
  chmod -R g=u /etc/passwd /etc/group /etc/subuid /etc/subgid ; \
  chgrp -R 0 /home ; \
  chmod +x /entrypoint.sh ; \
  chmod -R g=u /home ${WORK_DIR}
USER 10001
WORKDIR ${WORK_DIR}
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "tail", "-f", "/dev/null" ]