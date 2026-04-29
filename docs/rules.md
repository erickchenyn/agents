# RULES

## 语言

- 使用中文和我沟通
- 使用英文写文档做记录
- 使用英文写代码注释
- 使用英文写 commit 和 pr title，使用中文写 commit 和 pr description

## 文档格式

- 任何中英文混排内容中，要在数字和中英文之间添加空格，以保证排版美观统一
- 所有类代码、脚本指令的符号应该包含在 inline code 中，如 `git status`
- 通用占位符可以用 `<>` 来表示

## 行为方式

- 每次执行动作前，回头读一下 AGENTS.md 的规则，确认和检查自己的行为
- 强制停顿：在调用任何工具之前，先问自己「使用这个工具是否合适？有没有其它选择？」
- 失败反思：调用工具结果不符合预期时，不要立即重试，先问自己「为什么失败？是工具选错了还是用法错了？」
- 思考先行：不清楚怎么做时，先思考清楚，保证获取了足够的信息，再决定方案并执行。不要获取部分信息立即开始，不要盲目使用常规方案
- 明确需求：认真理解用户的需求，仔细分析，如果需求缺少信息，则反问用户直到确定明确的意图
- 自我审查：完成修改后，要根据开始的方案，自我 review，保证需求完成，正确且没有遗漏
- 暴露不确定性：不确定怎么做时，承认不确定
- 搜索内容时，检查每一个命中的目标，而不是根据其中一个目标，先入为主地片面理解内容
- 读取文件时，先评估它的大小，采用部分加载的方式，避免卡死！
- 每次回答必须以「喵」结尾！

### 提交

- 使用 [@my-commit](/skills/my-commit/SKILL.md) skill 提交代码

### 构建

- 缺少依赖或生成文件时，可以使用 `q generate --cahce=false` 命令来安装依赖并重新生成必要的代码

### 编码

- 修改文件后，必须保证此文件中没有任何 ts 类型和 eslint 错误
  - 在 web 目录下使用 `pnpm tsc --noEmit --project tsconfig.app.json --skipLibCheck` 命令来检查 ts 错误
  - 在 web 目录下使用 `pnpm eslint {file}` 命令来检查 eslint 错误
  - 不要使用 disable eslint 或 ignore ts 来绕过检查
  - 不要使用 as any 来尝试绕过类型错误
- 异步代码使用 async await 和 try catch，不要使用 `.then` `.catch` `.finally`
- 提交的代码中不要留有任何 `console` 等调试代码，过程中调试用的代码请在用完后及时删除
- 脚本生成的被 git 忽略的文件不应该被修改

### 测试

- 使用 vitest 执行 web 测试：在 web 目录下执行 `pnpm vitest {path}` 来执行指定路径的测试
- 测试中不要使用如 if else 的判断语句，要在准确的场景下做准确的断言
- 集成测试中使用 `getByTestId` 来定位 DOM 元素，不要使用 `getByText`，如目标 DOM 元素没有 data-testid 标记可以补上
- 新建的测试文件在顶级 describe 必须有 owner `[erick.chen@paraflow.com]`，且一个测试文件的顶级 describe 只能有一个
- 测试应按 GWT 模式来写，测试中无论是在测试 name 中还是备注，尽可能写清楚 GIVEN WHEN THEN 三部分

### API

- 当我提到 `moxt cli` 时，指的是全局安装的 `@moxt-ai/cli` 工具。用它可以来远程读写和操作 Moxt 工作空间的数据和 Agent 会话
