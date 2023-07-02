<img align="left" width="180" height="180" src="https://github.com/Hanaasagi/dango/assets/9482395/7c604042-28cb-4ae5-923d-242244e41232">

# dango

> Functional programming library for Zig.

[![CI](https://github.com/Hanaasagi/dango/actions/workflows/ci.yaml/badge.svg)](https://github.com/Hanaasagi/dango/actions/workflows/ci.yaml)
![](https://img.shields.io/badge/language-zig-%23ec915c)

<br />

# Documentation

## utils

### merge

```Zig
const Point = struct {
    x: u32,
    y: u32,
    label: []const u8,
};

const p = Point{ .x = 0, .y = 1, .label = "A" };
// merge to new struct
const new_p = merge(p, .{ .x = 2, .label = "B" });
// pass multi struct is ok
const new_p_2 = merge(p, .{ .{ .x = 2 }, .{ .label = "B" } });
```

### update

```Zig
const Point = struct {
    x: u32,
    y: u32,
    label: []const u8,
};

var p = Point{ .x = 0, .y = 1, .label = "A" };
// update struct in-place
update(&p, .{ .x = 2, .label = "B" });
// pass multi struct is ok
update(&p, .{ .{ .x = 2 }, .{ .label = "B" } });
```
