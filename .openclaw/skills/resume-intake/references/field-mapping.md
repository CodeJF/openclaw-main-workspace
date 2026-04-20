# Resume Intake Field Mapping

## Approved safe fields

Only populate fields that are reliable enough for the production intake path:

- 应聘者姓名
- 年龄
- 应聘岗位
- 联系方式
- 学历
- 毕业院校
- 专业
- 是否为全日制
- 最近一家公司名称
- 目前薪资
- 期望薪资
- 附件

Anything else should remain empty unless the business rules are explicitly expanded.

## Extraction philosophy

- Do not hallucinate.
- Prefer empty over wrong.
- Preserve conservative normalization.
- Salary fields should remain empty if the text is ambiguous, non-numeric, or words like `面议` / `保密` / `详谈` appear.

## Current heuristics

### Name

Prefer explicit `姓名:` patterns. Fallback: one of the early standalone Chinese-name lines.

### Contact

Extract phone and email if present. Combine as `phone / email` when both exist.

### Age

Use explicit `年龄:` patterns only.

### Degree

Current keyword scan order:

- 博士
- 硕士
- 本科
- 大专
- 中专
- 高中

### School

Use a conservative pattern ending with `大学` or `学院`.

### Major

Prefer explicit `专业:` patterns.

### Full-time

Map:

- `全日制` => `是`
- `非全日制|成人教育|自考|函授` => `否`

### Latest company

Prefer explicit patterns like `最近一家公司` / `最近公司` / `现公司` / `就职于`.

### Intended position

Prefer explicit patterns like `应聘岗位` / `求职意向` / `意向岗位`.

When necessary, strip trailing unrelated labels from the same line, such as:

- 意向城市
- 期望薪资
- 电话
- 邮箱
- 性别
- 年龄
- 现所在地
- 最高学历

## Output shape

Return only populated keys. Do not emit empty-string fields.

Example:

```json
{
  "应聘者姓名": "王楠",
  "联系方式": "13800000000 / test@example.com",
  "学历": "本科"
}
```
