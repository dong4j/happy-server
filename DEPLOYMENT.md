# Happy Server 部署说明

## 环境配置

### 创建 .env 文件

docker-compose 文件使用 `.env` 来管理环境变量。首次部署前需要创建此文件：

```bash
# 复制模板文件
cp .env.example .env

# 编辑配置文件
nano .env  # 或使用你喜欢的编辑器
```

**重要**：必须修改以下配置：
- `HANDY_MASTER_SECRET`: 使用 `openssl rand -hex 32` 生成安全的随机字符串
- `SEED`: 同上
- `POSTGRES_PASSWORD`: 设置强密码
- `MINIO_ROOT_PASSWORD`: 设置强密码
- `S3_PUBLIC_URL`: 根据实际部署环境调整

### 使用外部服务（docker-compose.simple.yml）

如果使用 `docker-compose.simple.yml` 连接外部服务，需要在 `.env.dev` 中配置：
- `DATABASE_URL_EXTERNAL`: 外部 PostgreSQL 连接字符串
- `REDIS_URL_EXTERNAL`: 外部 Redis 连接字符串
- `S3_HOST_EXTERNAL`: 外部 MinIO 主机地址
- `HAPPY_SERVER_PORT`: 外部访问端口（默认 3456）

## 已解决的问题

### 1. ✅ Prisma 迁移自动执行
服务器启动时会自动运行 `prisma migrate deploy`，无需手动执行迁移。

### 2. ✅ MinIO/S3 配置
所有 docker-compose 文件已包含完整的 MinIO/S3 配置。

### 3. ✅ 从源代码构建
Dockerfile 使用 `build` 方式从源代码构建，不依赖预构建镜像。

## 关于 HAPPY_SERVER_URL

**重要说明**：`HAPPY_SERVER_URL` 是**客户端（CLI）**的环境变量，不是服务器端的。

### 问题
设置 `HAPPY_SERVER_URL` 后，运行 `happy` 命令仍然返回 `https://app.happy.engineering`。

### 原因
这是客户端代码的问题，可能的原因：
1. 客户端代码中硬编码了默认 URL
2. 客户端没有正确读取环境变量
3. 客户端需要重启或重新安装才能生效

### 解决方案
这个问题需要在客户端代码中修复。作为服务器端，我们无法控制客户端的行为。

**建议**：
- 检查客户端（CLI）代码是否正确读取 `HAPPY_SERVER_URL` 环境变量
- 确认客户端代码中是否有硬编码的 URL
- 查看客户端仓库的 issue 或提交 PR 修复

## 部署步骤

### 1. 使用全量 docker-compose.yml（包含所有服务）

```bash
# 启动所有服务
docker-compose -f docker-compose-all.yml up -d

# 初始化 MinIO 存储桶（首次运行）
docker-compose --profile init up minio-init

# 查看日志
docker-compose logs -f happy-server
```

### 2. 使用简化的 docker-compose.yml（连接外部服务）

```bash
# 确保外部服务已启动：
# - PostgreSQL (host.docker.internal:5432)
# - Redis (host.docker.internal:6379)
# - MinIO (host.docker.internal:9000)

# 修改 docker-compose.yml 中的环境变量
# 然后启动
docker-compose up -d
```

### 3. 独立部署 MinIO

```bash
# 启动 MinIO
docker-compose up -d

# 初始化存储桶（首次运行）
docker-compose --profile init up minio-init
```

## 环境变量说明

### 必需的环境变量

- `DATABASE_URL`: PostgreSQL 连接字符串
- `REDIS_URL`: Redis 连接字符串
- `HANDY_MASTER_SECRET`: 用于加密和 token 生成的种子（必须修改为安全的随机字符串）
- `S3_HOST`: MinIO/S3 主机地址
- `S3_PORT`: MinIO/S3 端口（默认 9000）
- `S3_USE_SSL`: 是否使用 SSL（默认 false）
- `S3_ACCESS_KEY`: MinIO/S3 访问密钥
- `S3_SECRET_KEY`: MinIO/S3 密钥
- `S3_BUCKET`: S3 存储桶名称
- `S3_PUBLIC_URL`: S3 公共访问 URL

### 可选的环境变量

- `PORT`: 服务器端口（默认 3005）
- `NODE_ENV`: 环境模式（production/development）
- `METRICS_ENABLED`: 是否启用监控（默认 true）
- `METRICS_PORT`: 监控端口（默认 9090）

## 验证部署

### 1. 检查健康状态

```bash
curl http://localhost:3005/health
```

应该返回：
```json
{"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

### 2. 检查数据库连接

查看日志确认没有数据库连接错误：
```bash
docker-compose logs happy-server | grep -i "database\|prisma\|migrate"
```

### 3. 检查 MinIO 连接

查看日志确认 MinIO 连接正常：
```bash
docker-compose logs happy-server | grep -i "s3\|minio\|bucket"
```

## 常见问题

### Q: 迁移失败怎么办？
A: 检查 `DATABASE_URL` 是否正确，确保数据库可访问。可以手动运行：
```bash
docker-compose exec happy-server npx prisma migrate deploy
```

### Q: MinIO 连接失败？
A: 检查：
1. MinIO 服务是否运行
2. `S3_HOST` 和 `S3_PORT` 是否正确
3. `S3_ACCESS_KEY` 和 `S3_SECRET_KEY` 是否与 MinIO 配置一致
4. 存储桶是否已创建（运行初始化脚本）

### Q: 如何生成安全的 HANDY_MASTER_SECRET？
A: 使用以下命令生成：
```bash
openssl rand -hex 32
```

## 下一步

1. 修改所有 docker-compose 文件中的 `HANDY_MASTER_SECRET` 为安全的随机字符串
2. 根据实际部署环境调整 `S3_PUBLIC_URL`
3. 如果使用 HTTPS，修改 `S3_USE_SSL=true` 并配置 SSL 证书
4. 配置防火墙和反向代理（如 Nginx/Caddy）

