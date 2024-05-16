dnf -y install https://repo-l4t.apps.okd.jharmison.com/jharmison-l4t-repo-9.rpm
curl -sL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo >/etc/yum.repos.d/nvidia-container-toolkit.repo

dnf -y install nvidia-container-toolkit-base \
	nvidia-jetpack-all \
	nvidia-jetpack-kmod

cat <<'EOF' >/usr/lib/systemd/system/nvidia-container-toolkit-generate.service
[Unit]
Description=Regenerate the Nvidia Container Toolkit CDI specification
Wants=kmod-static-nodes.service
After=kmod-static-nodes.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia

[Install]
WantedBy=multi-user.target default.target
EOF

ln -s ../nvidia-container-toolkit-generate.service /usr/lib/systemd/system/default.target.wants
