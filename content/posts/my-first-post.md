---
date: "2025-04-10T15:51:52+08:00"
draft: false
title: 'My First Post'
---

# 一级标题

## 二级标题

### 三级标题

#### 四级标题

##### 五级标题

###### 六级标题

# 段落

这是一个段落。

这是另一个段落。

这是一行末尾添加两个空格  
来实现的换行效果。

*斜体文本*

**粗体文本**

***粗斜体文本***

~~删除线文本~~

- 项目1
- 项目2
  - 子项目2.1
  - 子项目2.2
    - 子子项目2.2.1
- 项目3

1. 第一项
2. 第二项
   1. 子项2.1
   2. 子项2.2
3. 第三项

- [x] 已完成任务
- [ ] 未完成任务
- [ ] 待办事项

> 这是一个引用
>
> 这是引用的第二行
> 这是一级引用
>
> > 这是二级引用
> >
> > > 这是三级引用

# 水平分割线

---

# 链接和图片

## 链接

[带有标题的链接](https://markdown.com.cn "Markdown语法")

<https://markdown.com.cn>

## 图片

[![可点击的图片](https://markdown.com.cn/assets/img/philly-magic-garden.9c0b4415.jpg "点击跳转")](https://markdown.com.cn)

# 代码

## 行内代码

使用反引号包裹代码：`const example = "hello world";`

## 代码块

```
// 无语法高亮的代码块
function example() {
  console.log("Hello, world!");
}
```

```java
// Java 代码块
public class Example {
    public static void main(String[] args) {
        System.out.println("Hello, world!");
    }
}
```

```go
// Go 代码块
func main() {
    fmt.Println("Hello, world!")
}
```

```javascript
// JavaScript 代码块
function example() {
  console.log("Hello, world!");
}
```

```python
# Python 代码块
def example():
    print("Hello, world!")
```

```css
/* CSS 代码块 */
body {
  background-color: #f0f0f0;
  color: #333;
}
```

# 表格

| 表头1 | 表头2 | 表头3 |
| ----- | ----- | ----- |
| 单元格1 | 单元格2 | 单元格3 |
| 单元格4 | 单元格5 | 单元格6 |

## 对齐方式

| 左对齐 | 居中对齐 | 右对齐 |
| :----- | :-----: | -----: |
| 内容 | 内容 | 内容 |
| 内容 | 内容 | 内容 |

# 脚注

这里有一个脚注[^1]。

[^1]: 这是脚注的内容。

# 数学公式（需要支持LaTeX的环境）

行内公式：$E=mc^2$

独立公式：

$$
\frac{d}{dx}(x^n) = nx^{n-1}
$$
