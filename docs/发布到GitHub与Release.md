# 发布到GitHub与Release

本文档描述如何把`ScreenMarker Pro`代码托管到GitHub，并生成可下载的Release安装包。

## 一次性准备

### 1. 完善Xcode发布信息

发布前请先在Xcode里修改：

- `Bundle Identifier`
- `Team`
- `Version`
- `Build`

当前工程里还是占位值：

- `PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.ScreenMarkerPro`
- `DEVELOPMENT_TEAM = ""`

如果不改，签名和公证流程无法真正落地。

### 2. 配置本地发布环境

复制一份示例配置：

```bash
cp scripts/release.env.example scripts/release.env
```

然后把里面的占位值替换成你自己的：

- `PRODUCT_BUNDLE_IDENTIFIER_OVERRIDE`
- `DEVELOPMENT_TEAM_OVERRIDE`
- `DEVELOPER_ID_APPLICATION`
- `DEVELOPER_ID_INSTALLER`
- `NOTARY_PROFILE`

使用时：

```bash
set -a
source scripts/release.env
set +a
```

### 3. 初始化并推送GitHub仓库

本地仓库已经初始化并切到`main`分支。后续你只需要补远程仓库：

```bash
git remote add origin git@github.com:<你的GitHub用户名>/<仓库名>.git
git add .
git commit -m "Initial release setup"
git push -u origin main
```

## 本地生成Release产物

### 无签名版本

适合本地测试、内测或先打包验证流程：

```bash
chmod +x scripts/*.sh
bash scripts/package-release.sh --unsigned
```

默认会生成：

- `zip`
- `dmg`
- `SHA256SUMS.txt`

产物目录：

```bash
build/release/artifacts
```

### 签名版本

先加载环境变量：

```bash
set -a
source scripts/release.env
set +a
```

然后打包：

```bash
bash scripts/package-release.sh --signed --with-pkg
```

默认会生成：

- `zip`
- `dmg`
- `pkg`
- `SHA256SUMS.txt`

### 公证版本

签名包生成后，执行：

```bash
set -a
source scripts/release.env
set +a

bash scripts/notarize-release.sh
```

脚本会做这些事：

1. 提交`.app`进行公证
2. `staple`应用票据
3. 重建`zip`和`dmg`
4. 公证并装订`dmg`
5. 如果存在`pkg`，继续公证并装订`pkg`

## GitHub Actions自动发布

仓库里已经加了工作流：

- [.github/workflows/release.yml](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/.github/workflows/release.yml)

触发方式：

- 手动`workflow_dispatch`
- 推送标签：`v1.1.0`

### GitHub仓库变量(Repository Variables)

需要配置：

- `APP_BUNDLE_ID`
- `APPLE_TEAM_ID`
- `DEVELOPER_ID_APPLICATION`
- `DEVELOPER_ID_INSTALLER`

### GitHub仓库密钥(Repository Secrets)

签名需要：

- `DEVELOPER_ID_APPLICATION_P12_BASE64`
- `DEVELOPER_ID_APPLICATION_P12_PASSWORD`
- `DEVELOPER_ID_INSTALLER_P12_BASE64`
- `DEVELOPER_ID_INSTALLER_P12_PASSWORD`

公证需要：

- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

### 工作流行为

- 如果没有签名证书密钥：自动生成**unsigned zip/dmg**
- 如果有签名变量和证书：自动生成**signed zip/dmg**
- 如果再加上Installer证书：额外生成**pkg**
- 如果再加上Apple ID公证密钥：自动执行**notarization**

## 建议的发布节奏

### 内测

- 用`--unsigned`先走通流程
- 上传`zip`和`dmg`到GitHub Release

### 正式发布

- 走`--signed --with-pkg`
- 再执行`notarize-release.sh`
- GitHub Release里上传：
  - `zip`
  - `dmg`
  - `pkg`可选
  - `SHA256SUMS.txt`

## 当前已落地的发布文件

- [.gitignore](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/.gitignore)
- [scripts/common.sh](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/scripts/common.sh)
- [scripts/package-release.sh](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/scripts/package-release.sh)
- [scripts/notarize-release.sh](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/scripts/notarize-release.sh)
- [scripts/release.env.example](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/scripts/release.env.example)
- [.github/workflows/release.yml](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/.github/workflows/release.yml)

## 还需要你自己完成的事

- 把工程里的正式`Bundle Identifier`和`Team`改掉
- 创建GitHub远程仓库并绑定`origin`
- 准备Developer ID证书
- 准备Apple公证凭据
