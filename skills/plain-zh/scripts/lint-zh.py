#!/usr/bin/env python3
"""lint-zh: plain-zh 直译腔/对仗压缩 机械检测。
检测四类：累积黑名单（历史犯错词）、对仗否定式（含对称检测）、scale 直译族、标题内四字格对仗。
输出：文件、行号、列、模式、片段。宁缺勿滥：四字格只在标题行与加粗标签内查；命中后仍需人工裁决。"""
import re, sys, pathlib

# P1 累积黑名单：本项目/本用户历史上被点名过的直译词。每犯一次，追加一条。
BLACKLIST = [
    '发牌防收敛', '发牌式方向', '材料诚实', '房风', '臂距', '出身与定位',
    '降压工具箱', '总貌退化', '秒级可扫', '闪烁免疫', '自建范式', '分层供应',
    '注入一个人格', '色彩时刻', '预算化验证', '新鲜上下文', '镜子测试',
    '禁亚秒', '投影：', '投影（', '雄心随模式缩放', '按表面分类，不按产品分类',
]

# P2 对仗否定式与翻案腔
P2 = [
    (re.compile(r'按[^。，；]{1,6}分类，不按[^。，；]{1,6}分类'), '对仗否定(按X分类不按Y分类)'),
    (re.compile(r'随[^。，；]{1,8}[^。，；]{0,4}，不随[^。，；]{1,8}'), '对仗否定(随X不随Y)'),
]

# P3 scale/渐变直译族
P3 = [
    (re.compile(r'随[^。，；]{1,8}(缩放|递减|递增|递降|递变)'), 'scale直译(随X缩放/递变)'),
    (re.compile(r'(雄心|野心|表达欲|响度|力度|强度)[^。，；]{0,4}(缩放|伸缩)'), 'scale直译(雄心缩放类)'),
]

# P4 四字格对仗：只查标题行与 **加粗标签** 片段内部
P4 = re.compile(r'[\u4e00-\u9fff]{4}[，、][\u4e00-\u9fff]{4}(?![，、])')
BOLD = re.compile(r'\*\*([^*]+)\*\*')

def scan_line(line: str, in_heading: bool):
    hits = []
    for w in BLACKLIST:
        if w in line:
            hits.append((line.find(w), f'黑名单<{w}>'))
    for pat, name in P2:
        for m in pat.finditer(line):
            hits.append((m.start(), name))
    for pat, name in P3:
        for m in pat.finditer(line):
            hits.append((m.start(), name))
    # P4 只在标题行或加粗片段里找
    zones = []
    if in_heading:
        zones.append((0, line))
    for m in BOLD.finditer(line):
        zones.append((m.start(), m.group(1)))
    for off, text in zones:
        for m in P4.finditer(text):
            hits.append((off + m.start(), '四字格对仗(标题/加粗内)'))
    return hits

def main(paths):
    total = 0
    for p in paths:
        p = pathlib.Path(p)
        if not p.exists():
            continue
        for i, line in enumerate(p.read_text(encoding='utf-8').splitlines(), 1):
            in_heading = bool(re.match(r'^#{1,6}\s', line))
            for col, name in scan_line(line, in_heading):
                frag = line.strip()
                frag = frag[max(0, col-12):col+24]
                print(f'{p.name}:{i}:{col+1} [{name}] …{frag}…')
                total += 1
    print(f'-- {total} hit(s), P4 命中仍需人工裁决')
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
