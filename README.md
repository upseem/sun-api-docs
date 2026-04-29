# Sun API Docs

Sun API 网关的开发者文档站点，基于 [Mintlify](https://mintlify.com)。

## 本地预览

需要 Node.js 18+。

```bash
# 全局安装 Mintlify CLI（一次即可）
npm i -g mintlify

# 在项目根目录启动预览（默认 http://localhost:3000）
mintlify dev
```

## 内容结构

```
.
├── mint.json                  # 站点配置（导航、品牌色、域名等）
├── introduction.mdx           # 首页
├── quickstart.mdx             # 快速开始
├── authentication.mdx         # 鉴权说明
├── api-reference/             # API 参考
│   ├── relay.json             # OpenAPI 3.0 规范（中转接口）
│   ├── api.json               # OpenAPI 3.0 规范（管理接口）
│   ├── chat/                  # 对话接口（OpenAI / Claude / Gemini 三种格式）
│   ├── images/                # 图像生成
│   ├── videos/                # 视频生成
│   ├── audio/                 # 语音转写 / 合成
│   ├── embeddings/            # 向量
│   ├── rerank/                # 重排
│   └── models/                # 模型列表
└── images/                    # 站点品牌资源（logo / favicon / hero）
```

## 部署

1. 推送本仓库到 GitHub
2. 在 [mintlify.com](https://mintlify.com) 注册账号
3. 安装 Mintlify GitHub App，授权本仓库
4. 之后每次 push 到主分支会自动构建发布

## 更新 OpenAPI 规范

主项目 `new-api` 更新了 OpenAPI 后，同步两个 JSON 文件即可：

```bash
cp ../new-api/docs/openapi/relay.json ./api-reference/relay.json
cp ../new-api/docs/openapi/api.json   ./api-reference/api.json
```
