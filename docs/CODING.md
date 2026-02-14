# 编码

- 修改文件后，必须保证此文件中没有任何 ts 类型和 eslint 错误
  - 在 web 目录下使用 `pnpm tsc --noEmit --project tsconfig.app.json --skipLibCheck` 命令来检查 ts 错误
  - 在 web 目录下使用 `pnpm eslint {file}` 命令来检查 eslint 错误
  - 不要使用 disable eslint 或 ignore ts 来绕过检查
  - 不要使用 as any 来尝试绕过类型错误
- 异步代码使用 async await 和 try catch，不要使用 `.then` `.catch` `.finally`
- 提交的代码中不要留有任何 `console` 等调试代码，过程中调试用的代码请在用完后及时删除
- 脚本生成的被 git 忽略的文件不应该被修改
