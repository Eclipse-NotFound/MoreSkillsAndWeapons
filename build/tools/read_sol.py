# -*- coding: utf-8 -*-
"""读取 Remains 模组 SharedObject (.sol) 诊断/配置 —— AMF3 方言解析器。

2026-08-28 用 MSWConfig.sol 实测破解的本机 Flash 写出格式（与标准 AMF3 的差异）：
- 顶层属性名：1 字节值；若该字节为 0x00 则再读 1 字节组成大端 2 字节值。
  值 v 为 U29S 语义：奇数 → 字面长度 v>>1；偶数 → 字符串回引用表 v>>1。
- 回引用表：从空表开始，所有非空字符串（顶层属性名、diag 键名）按出现顺序编号；
  空字符串（匿名类名、对象结束键）不入表（实测两个不同键序的文件均吻合）。
- 顶层值不带填充；`XX 00` 序列中的 00 恒属于下一个属性名的高字节，
  仅文件末尾最后一个值后有一个 0x00 收尾字节。
- 容器成员键名一律 1 字节 U29S。
- AMF3 标记：01 null / 02 false / 03 true / 04 int(u29) / 05 double / 06 string /
  0a 动态匿名对象（traits u29 + 匿名名 + 键值对至空键）。
用法：python read_sol.py <path.sol>
"""
import sys, struct


class Reader:
    def __init__(self, data):
        self.d = data
        self.i = 0

    def u8(self):
        v = self.d[self.i]
        self.i += 1
        return v

    def be16(self):
        v = struct.unpack_from('>H', self.d, self.i)[0]
        self.i += 2
        return v

    def be32(self):
        v = struct.unpack_from('>I', self.d, self.i)[0]
        self.i += 4
        return v

    def raw(self, n):
        v = self.d[self.i:self.i + n]
        self.i += n
        return v

    def u29(self):
        v = 0
        for k in range(3):
            b = self.u8()
            if b < 0x80:
                return (v << 7) | b if k else b
            v = (v << 7) | (b & 0x7f)
        return (v << 8) | self.u8()


class SolParser:
    def __init__(self, path):
        self.r = Reader(open(path, 'rb').read())
        self.refs = []  # 非空字符串按出现顺序编号；空串不入表

    def string_token(self):
        """U29S：奇数=字面长度，偶数=回引用。"""
        v = self.r.u29()
        if v & 1:
            s = self.r.raw(v >> 1).decode('utf-8', 'replace')
            if s != '':
                self.refs.append(s)
            return s
        idx = v >> 1
        return self.refs[idx] if idx < len(self.refs) else '<ref#%d>' % idx

    def value(self):
        m = self.r.u8()
        if m == 0x01:
            return None
        if m == 0x02:
            return False
        if m == 0x03:
            return True
        if m == 0x04:
            return self.r.u29()
        if m == 0x05:
            return struct.unpack_from('>d', self.r.raw(8), 0)[0]
        if m == 0x06:
            return self.string_token()
        if m == 0x0a:
            return self.object()
        if m == 0x09:
            return self.array()
        return '<marker 0x%02x @%d>' % (m, self.r.i)

    def object(self):
        traits = self.r.u29()
        if not traits & 1:
            return '<objref %d>' % (traits >> 1)
        cls = self.string_token()  # 匿名对象为空串
        out = {} if cls == '' else {'__class__': cls}
        while True:
            k = self.string_token()
            if k == '':
                break
            out[k] = self.value()
        return out

    def array(self):
        v = self.r.u29()
        if not v & 1:
            return '<arrref>'
        out = []
        for _ in range(v >> 1):
            out.append(self.value())
        while True:
            k = self.string_token()
            if k == '':
                break
            out.append((k, self.value()))
        return out

    def parse(self):
        r = self.r
        assert r.raw(2) == b'\x00\xbf', '不是 .sol 文件'
        r.be32()  # 文件长度（4 字节大端）
        assert r.raw(4) == b'TCSO'
        r.raw(6)
        objname = r.raw(r.be16()).decode('utf-8', 'replace')
        r.raw(4)  # 00 00 00 03
        out = {'__object__': objname}
        while r.i < len(r.d):
            if r.i == len(r.d) - 1 and r.d[r.i] == 0:
                break  # 文件末尾固定有一个 0x00 收尾字节
            b = r.d[r.i]
            n = r.be16() if b == 0x00 else r.u8()
            if n & 1:
                key = r.raw(n >> 1).decode('utf-8', 'replace')
                if key != '':
                    self.refs.append(key)
            else:
                idx = n >> 1
                key = self.refs[idx] if idx < len(self.refs) else '<ref#%d>' % idx
            out[key] = self.value()
        return out


def fmt(v, indent=0):
    if isinstance(v, dict):
        pad = '  ' * (indent + 1)
        lines = []
        for k, vv in v.items():
            if isinstance(vv, dict):
                lines.append('%s%s:' % (pad, k))
                lines.append(fmt(vv, indent + 1))
            else:
                lines.append('%s%-22s = %r' % (pad, k, vv))
        return '\n'.join(lines)
    return repr(v)


def main(path):
    data = SolParser(path).parse()
    print('object:', data.pop('__object__'))
    for k, v in data.items():
        if isinstance(v, dict):
            print('%s:' % k)
            print(fmt(v, 0))
        else:
            print('%-22s = %r' % (k, v))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1])
