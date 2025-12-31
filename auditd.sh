#!/bin/bash
set -e

RULE_FILE="/etc/audit/rules.d/execve-auid.rules"

echo "==> 1) 安装 auditd"
yum install -y audit

echo "==> 2) 启动并设置开机自启 auditd"
systemctl enable --now auditd

echo "==> 3) 写入审计规则到 ${RULE_FILE}"
cat > "${RULE_FILE}" <<'EOF'
-a always,exit -F arch=b64 -S execve -S execveat -F auid>=0 -F auid!=4294967295 -k cmdlog
-a always,exit -F arch=b32 -S execve -S execveat -F auid>=0 -F auid!=4294967295 -k cmdlog
EOF

echo "==> 4) 加载规则并重启 auditd"
augenrules --load
systemctl restart auditd

echo "==> 5) 检查 auditd 状态"
systemctl --no-pager status auditd

echo "==> 6) 检查规则是否生效"
auditctl -l | grep -E "execve|execveat" || {
  echo "未找到 execve 审计规则，请检查规则文件或 auditd 是否正常"
  exit 1
}

echo "✅ 完成：execve 命令审计规则已启用"
