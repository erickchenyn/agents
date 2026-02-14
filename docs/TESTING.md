# 测

- 使用 vitest 执行 web 测试：在 web 目录下执行 `pnpm vitest {path}` 来执行指定路径的测试
- 测试中不要使用如 if else 的判断语句，要在准确的场景下做准确的断言
- 集成测试中使用 `getByTestId` 来定位 DOM 元素，不要使用 `getByText`，如目标 DOM 元素没有 data-testid 标记可以补上
- 新建的测试文件在顶级 describe 必须有 owner `[erick.chen@paraflow.com]`，且一个测试文件的顶级 describe 只能有一个
- 测试应按 GWT 模式来写，测试中无论是在测试 name 中还是备注，尽可能写清楚 GIVEN WHEN THEN 三部分
