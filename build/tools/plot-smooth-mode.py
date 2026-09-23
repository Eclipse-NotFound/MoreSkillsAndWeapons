"""Plot recorded native bullet positions; no simulated or hand-drawn trajectories."""
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(sys.argv[1])
image = Image.new("RGB", (1200, 560), "#101a29")
draw = ImageDraw.Draw(image)
font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 20)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 16)
colors = {"off": "#a4afbf", "medium": "#42b9ff", "high": "#f5b451"}
draw.text((30, 20), "Native bullet trajectory comparison", fill="white", font=font)
for i, (key, label) in enumerate(zip(colors, ["Off", "Smooth 50%", "Smooth 100%"])):
    draw.line((35+i*205, 63, 66+i*205, 63), fill=colors[key], width=3)
    draw.text((76+i*205, 51), label, fill=colors[key], font=small)

def panel(rect, bounds, title):
    x0, y0, x1, y1 = rect
    xmin, ymin, xmax, ymax = bounds
    draw.text((x0, y0-32), title, fill="white", font=small)
    draw.rectangle(rect, outline="#40506a")
    def point(p):
        return (x0+(p["x"]-xmin)/(xmax-xmin)*(x1-x0),
                y0+(p["y"]-ymin)/(ymax-ymin)*(y1-y0))
    return point

moving = json.loads((root/"smooth-traces.json").read_text())
convert = panel((30, 140, 725, 485), (190, 180, 930, 590), "Target reverses at steps 6 and 12")
for key in colors:
    draw.line([convert(p) for p in moving[key]["points"]], fill=colors[key], width=2)
for y in [260, 560]:
    x, yy = convert({"x":860, "y":y})
    draw.ellipse((x-6, yy-6, x+6, yy+6), outline="white", width=2)

convert = panel((780, 140, 1170, 485), (190, 80, 560, 335), "Solid 80 x 80 obstacle")
draw.rectangle((*convert({"x":320,"y":200}), *convert({"x":400,"y":280})), fill="#46536a")
for amount, key in [(0,"off"),(50,"medium"),(100,"high")]:
    path = json.loads((root/f"smooth-box-{amount}.json").read_text())
    draw.line([convert(p) for p in path], fill=colors[key], width=2)
draw.text((30, 520), "Recorded game physics; each path retains original speed, collision and damage.", fill="#adbdd2", font=small)
image.save(root/"trajectory-comparison.png")
