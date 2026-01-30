# Workspace 管理脚本

## workspace-create.sh

快速创建 git worktree 的脚本版本，替代原有的 `workspace-create` skill。

### 性能提升

- **原 skill 执行时间**: ~30-60 秒
- **脚本执行时间**: ~5-15 秒
- **性能提升**: 4-10x

### 使用方法

#### 1. 完整命令
```bash
./workspace-create.sh [选项]
```

#### 2. 简化命令
```bash
./wc [选项]
```

### 可用选项

- `-h, --help`: 显示帮助信息
- `-d, --dry-run`: 预览模式，不实际执行操作
- `-b, --branch <name>`: 自定义分支名（默认使用时间戳）
- `-u, --user <name>`: 设置 git 用户名（默认: erick.chen）
- `-e, --email <email>`: 设置 git 邮箱（默认: erick.chen@paraflow.com）

### 使用示例

```bash
# 基本使用
./wc

# 预览操作
./wc -d

# 自定义分支名
./wc -b feature-auth

# 自定义 git 用户信息
./wc -u "john.doe" -e "john@example.com"

# 组合使用
./wc -d -b feature-login -u "jane" -e "jane@example.com"
```

### 功能对比

| 功能 | Skill | 脚本 | 说明 |
|------|-------|------|------|
| 环境检查 | ✅ | ✅ | 验证 git 仓库和主工作区 |
| 项目信息获取 | ✅ | ✅ | 从 origin URL 解析项目名 |
| Worktree 创建 | ✅ | ✅ | 基于 origin/main 创建新分支和工作区 |
| Git 用户设置 | ✅ | ✅ | 设置用户名和邮箱 |
| 代码生成 | ✅ | ✅ | 执行 `q generate` |
| Claude 设置拷贝 | ✅ | ✅ | 拷贝 `.claude/settings.local.json` |
| 错误处理 | ✅ | ✅ | 完整的错误检查和回滚 |
| 预览模式 | ❌ | ✅ | 可预览操作而不执行 |
| 自定义分支名 | ❌ | ✅ | 支持自定义分支名 |
| 参数化配置 | ❌ | ✅ | 支持自定义用户信息 |
| 执行速度 | 慢 | 快 | 脚本版本快 4-10 倍 |

### 环境要求

- Bash 4.0+
- Git 2.5+ （支持 worktree）
- `q` 命令（可选，用于代码生成）

### 错误处理

脚本包含完整的错误处理机制：

- 自动检测和验证环境
- 操作失败时自动回滚
- 清理已创建的 worktree 和分支
- 详细的错误信息提示

### 配置

可通过环境变量配置默认值：

```bash
export GIT_USER_NAME="your.name"
export GIT_USER_EMAIL="your.email@domain.com"
export BRANCH_PREFIX="yourname"
```

### 迁移建议

1. **测试阶段**: 使用 `-d` 选项预览操作
2. **并行使用**: 保留原 skill 作为备用
3. **逐步迁移**: 熟悉后完全切换到脚本版本