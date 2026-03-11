# GitHub Pages 部署说明

这套静态页面已经放在 `docs/site`，可以直接部署到 GitHub Pages。

## 已准备好的内容

- 静态网站目录：`docs/site`
- 自动部署工作流：`.github/workflows/deploy-pages.yml`

只要仓库推到 GitHub，并开启 Pages，就可以自动发布。

## 第一步：把仓库推到 GitHub

如果你还没有远程仓库，大致流程如下：

```bash
git init
git add .
git commit -m "Prepare App Store docs site"
git branch -M main
git remote add origin <你的 GitHub 仓库地址>
git push -u origin main
```

如果你已经有仓库，直接正常提交并推送即可。

## 第二步：开启 GitHub Pages

1. 打开 GitHub 仓库页面
2. 进入 `Settings`
3. 打开左侧 `Pages`
4. 在 `Build and deployment` 里选择 `GitHub Actions`

选完之后，不需要手动选分支，工作流会自动部署 `docs/site`。

## 第三步：触发首次部署

满足以下任一条件，就会自动触发部署：

- 推送 `main` 分支
- 推送 `master` 分支
- 在 GitHub Actions 页面手动运行 `Deploy Docs Site`

部署成功后，GitHub 会给出一个 Pages 地址，通常类似：

```text
https://<你的 GitHub 用户名>.github.io/<仓库名>/
```

## 第四步：绑定正式域名

部署完成后，确认下面两项链接可正常访问：

- `https://pxllhub.com/privacy-policy.html`
- `https://pxllhub.com/technical-support.html`

当前项目已经补充了：

- 自定义域名文件：`docs/site/CNAME`
- 域名内容：`pxllhub.com`

建议全局替换以下文件中的链接：

- `docs/privacy-policy.md`
- `docs/technical-support.md`
- `docs/app-store-copy.md`
- `docs/app-store-connect-final.md`
- `docs/site/privacy-policy.html`
- `docs/site/technical-support.html`

## 你的最终链接

当前正式链接应为：

```text
隐私政策：https://pxllhub.com/privacy-policy.html
技术支持：https://pxllhub.com/technical-support.html
```

如果 GitHub Pages 后台还没显示自定义域名，去仓库 `Settings > Pages`
检查是否已经识别到 `pxllhub.com`。

## 日常更新方式

以后只要你修改这些文件并推送，Pages 会自动重新部署：

- `docs/site/index.html`
- `docs/site/privacy-policy.html`
- `docs/site/technical-support.html`
- `docs/site/styles.css`

## 注意事项

- 如果你的默认分支不是 `main` 或 `master`，需要修改 `.github/workflows/deploy-pages.yml`
- 如果仓库是私有仓库，GitHub Pages 是否可用取决于你的 GitHub 套餐
- 发布前建议先用手机浏览器打开页面，检查排版和链接
