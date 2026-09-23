"""Draw measured native trajectories and radius histories; no resimulation."""
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(sys.argv[1])
data = json.loads((root / "adaptive-traces.json").read_text())
recovery = json.loads((root / "adaptive-recovery.json").read_text())
im = Image.new("RGB", (1200, 650), "#101a29")
d = ImageDraw.Draw(im)
font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 21)
small = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 16)
d.text((30, 18), "自适应转弯半径 · 游戏原生弹道实测", fill="white", font=font)
d.text((30, 58), "灰：固定 200%     蓝：自适应（平时 200%，最低 10%）", fill="#b9c7db", font=small)

rect = (30, 120, 700, 530)
d.text((30, 90), "相同目标：固定倍率错过，自适应提前收紧后命中", fill="white", font=small)
d.rectangle(rect, outline="#40506a")
scale = min(670 / 480, 410 / 290)
def pt(x, y):
    return (30 + (x - 190) * scale, 120 + (y - 210) * scale)

# The window ends after the relevant pass, before the missed shot travels away.
for key, color in (("miss", "#a4afbf"), ("rescue", "#42b9ff")):
    points = data[key]["points"]
    visible = []
    for p in points:
        if p["x"] > 660 or p["y"] > 495 or p["y"] < 211:
            break
        visible.append(pt(p["x"], p["y"]))
    if len(visible) > 1:
        d.line(visible, fill=color, width=3)
d.rectangle((*pt(408, 320), *pt(432, 360)), outline="#f5b451", width=2)
d.text(pt(440, 350), "目标受击区", fill="#f5b451", font=small)

def chart(rect, values, title, lo, hi):
    x0, y0, x1, y1 = rect
    d.text((x0, y0-31), title, fill="white", font=small)
    d.rectangle(rect, outline="#40506a")
    points = [(x0+i*(x1-x0)/max(1, len(values)-1),
               y1-(v-lo)*(y1-y0)/(hi-lo)) for i, v in enumerate(values)]
    d.line(points, fill="#42b9ff", width=3)
    d.text((x0+8, y0+8), f"{hi:g}%", fill="#a4afbf", font=small)
    d.text((x0+8, y1-26), f"{lo:g}%", fill="#a4afbf", font=small)

chart((760, 120, 1165, 295), data["rescue"]["radii"], "补救时实际倍率（按物理步记录）", 10, 200)
chart((760, 355, 1165, 530), recovery, "局面稳定后，逐级恢复到 200%", 140, 200)
d.text((30, 567), "开放场景：全程保持 200% 并命中。补救场景：实际使用约 81%–111%，没有降到最低值。", fill="white", font=small)
d.text((30, 601), "来自隔离场景中的真实子弹坐标、倍率与目标损血；是条件对照，不代表所有战斗必中。", fill="#a4afbf", font=small)
im.save(root / "adaptive-comparison.png")
