"""Draws Indian road signs (IRC:67 style) as SVG files in assets/signs/.

Every sign is original artwork built from simple shapes. Each entry in SIGNS
has the sign's meaning, which the question builder uses as the right answer.
"""
import math
import os

RED = "#D0021B"
BLUE = "#1457A8"
BLACK = "#111111"
WHITE = "#FFFFFF"

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "signs")


def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">'
            + body + "</svg>")


def head(x, y, angle_deg, size=22, color=BLACK):
    """Arrowhead whose tip is at (x, y), pointing along angle_deg (0 = right, 90 = down)."""
    a = math.radians(angle_deg)
    bx, by = x - size * math.cos(a), y - size * math.sin(a)
    px, py = -math.sin(a) * size * 0.6, math.cos(a) * size * 0.6
    return (f'<polygon points="{x:.1f},{y:.1f} {bx + px:.1f},{by + py:.1f} {bx - px:.1f},{by - py:.1f}" '
            f'fill="{color}"/>')


def line(d, color=BLACK, w=12):
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linejoin="round"/>'


# --- sign frames -----------------------------------------------------------

def prohibitory(symbol, slash=False):
    s = f'<circle cx="100" cy="100" r="88" fill="{WHITE}" stroke="{RED}" stroke-width="18"/>' + symbol
    if slash:
        s += f'<line x1="40" y1="40" x2="160" y2="160" stroke="{RED}" stroke-width="16"/>'
    return svg(s)


def compulsory(symbol):
    return svg(f'<circle cx="100" cy="100" r="92" fill="{BLUE}"/>' + symbol)


def warning(symbol):
    return svg('<polygon points="100,14 192,178 8,178" fill="#FFFFFF" stroke="%s" stroke-width="14" '
               'stroke-linejoin="round"/>' % RED + symbol)


def info(symbol):
    return svg(f'<rect x="14" y="14" width="172" height="172" rx="14" fill="{BLUE}"/>' + symbol)


def text(t, size, y=100, color=BLACK, x=100):
    return (f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-weight="bold" '
            f'font-size="{size}" fill="{color}" text-anchor="middle" dominant-baseline="central">{t}</text>')


def car(x, y, color=BLACK):
    return (f'<rect x="{x}" y="{y + 18}" width="58" height="24" rx="6" fill="{color}"/>'
            f'<rect x="{x + 12}" y="{y}" width="34" height="22" rx="7" fill="{color}"/>'
            f'<circle cx="{x + 13}" cy="{y + 44}" r="8" fill="{color}"/>'
            f'<circle cx="{x + 45}" cy="{y + 44}" r="8" fill="{color}"/>')


HORN = (f'<rect x="52" y="88" width="22" height="24" fill="{BLACK}"/>'
        f'<polygon points="74,92 140,62 140,138 74,108" fill="{BLACK}"/>')

# White arrow in a blue disc, pointing in a direction.
def white_arrow(d, x, y, angle):
    return line(d, WHITE, 16) + head(x, y, angle, 34, WHITE)


SIGNS = {
    # Mandatory / regulatory
    "stop": ("Stop", "mandatory", svg(
        '<polygon points="59,10 141,10 190,59 190,141 141,190 59,190 10,141 10,59" fill="%s" '
        'stroke="#fff" stroke-width="6"/>' % RED + text("STOP", 50, color=WHITE))),
    "give_way": ("Give way", "mandatory", svg(
        '<polygon points="10,22 190,22 100,186" fill="#fff" stroke="%s" stroke-width="16" '
        'stroke-linejoin="round"/>' % RED)),
    "no_entry": ("No entry", "mandatory", svg(
        f'<circle cx="100" cy="100" r="92" fill="{RED}"/><rect x="38" y="86" width="124" height="28" fill="#fff"/>')),
    "no_left_turn": ("Left turn prohibited", "mandatory", prohibitory(
        line("M120 150 V95 H75") + head(58, 95, 180, 30), slash=True)),
    "no_right_turn": ("Right turn prohibited", "mandatory", prohibitory(
        line("M80 150 V95 H125") + head(142, 95, 0, 30), slash=True)),
    "no_u_turn": ("U-turn prohibited", "mandatory", prohibitory(
        line("M120 150 V88 A20 20 0 0 0 80 88 V112") + head(80, 135, 90, 30), slash=True)),
    "no_overtaking": ("Overtaking prohibited", "mandatory", prohibitory(car(36, 74) + car(106, 74, RED))),
    "no_parking": ("No parking", "mandatory", prohibitory(text("P", 96, 104), slash=True)),
    "no_stopping": ("No stopping or standing", "mandatory", svg(
        f'<circle cx="100" cy="100" r="88" fill="{BLUE}" stroke="{RED}" stroke-width="18"/>'
        f'<line x1="40" y1="40" x2="160" y2="160" stroke="{RED}" stroke-width="16"/>'
        f'<line x1="160" y1="40" x2="40" y2="160" stroke="{RED}" stroke-width="16"/>')),
    "horn_prohibited": ("Horn prohibited", "mandatory", prohibitory(HORN, slash=True)),
    "speed_limit": ("Maximum speed limit 50 km/h", "mandatory", prohibitory(text("50", 80, 104))),
    "height_limit": ("Height limit 3.5 metres", "mandatory", prohibitory(
        text("3.5 m", 40, 102) + head(100, 70, 90, 22) + head(100, 134, -90, 22))),
    "width_limit": ("Width limit 2 metres", "mandatory", prohibitory(
        text("2 m", 38, 102) + head(62, 100, 0, 20) + head(138, 100, 180, 20))),
    "load_limit": ("Load limit 5 tonnes", "mandatory", prohibitory(text("5 T", 64, 104))),
    "restriction_ends": ("Restriction ends", "mandatory", svg(
        f'<circle cx="100" cy="100" r="88" fill="#fff" stroke="{BLACK}" stroke-width="6"/>'
        f'<line x1="44" y1="156" x2="156" y2="44" stroke="{BLACK}" stroke-width="22"/>')),
    "compulsory_ahead": ("Compulsory ahead only", "mandatory", compulsory(
        white_arrow("M100 160 V70", 100, 40, -90))),
    "compulsory_left": ("Compulsory turn left", "mandatory", compulsory(
        white_arrow("M120 160 V95 H80", 50, 95, 180))),
    "compulsory_right": ("Compulsory turn right", "mandatory", compulsory(
        white_arrow("M80 160 V95 H120", 150, 95, 0))),
    "keep_left": ("Compulsory keep left", "mandatory", compulsory(
        white_arrow("M140 60 L78 122", 56, 144, 135))),

    # Cautionary / warning
    "right_curve": ("Right hand curve ahead", "cautionary", warning(
        line("M90 165 V125 Q90 95 120 88") + head(140, 84, -15, 24))),
    "left_curve": ("Left hand curve ahead", "cautionary", warning(
        line("M110 165 V125 Q110 95 80 88") + head(60, 84, 195, 24))),
    "right_hairpin": ("Right hairpin bend ahead", "cautionary", warning(
        line("M84 165 V100 A18 18 0 0 1 120 100 V128") + head(120, 152, 90, 24))),
    "cross_road": ("Cross road ahead", "cautionary", warning(line("M100 72 V166 M58 124 H142"))),
    "side_road_right": ("Side road right", "cautionary", warning(line("M100 72 V166 M100 120 H142"))),
    "side_road_left": ("Side road left", "cautionary", warning(line("M100 72 V166 M100 120 H58"))),
    "t_intersection": ("T-intersection ahead", "cautionary", warning(line("M100 166 V100 M58 100 H142"))),
    "y_intersection": ("Y-intersection ahead", "cautionary", warning(line("M100 166 V128 L70 82 M100 128 L130 82"))),
    "roundabout": ("Roundabout ahead", "cautionary", warning(
        '<circle cx="100" cy="122" r="28" fill="none" stroke="%s" stroke-width="10"/>' % BLACK
        + "".join(head(100 + 28 * math.cos(math.radians(t)), 122 + 28 * math.sin(math.radians(t)), t + 90, 20)
                  for t in (-90, 30, 150)))),
    "narrow_road": ("Narrow road ahead", "cautionary", warning(
        line("M70 166 V140 L86 112 V74 M130 166 V140 L114 112 V74", w=10))),
    "road_widens": ("Road widens ahead", "cautionary", warning(
        line("M86 166 V128 L70 100 V74 M114 166 V128 L130 100 V74", w=10))),

    # Informatory
    "parking": ("Parking area", "informatory", info(text("P", 130, 104, WHITE))),
    "first_aid": ("First aid post", "informatory", info(
        f'<rect x="44" y="44" width="112" height="112" fill="#fff"/>'
        f'<rect x="88" y="58" width="24" height="84" fill="{RED}"/><rect x="58" y="88" width="84" height="24" fill="{RED}"/>')),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for key, (_, _, art) in SIGNS.items():
        with open(os.path.join(OUT, f"{key}.svg"), "w") as f:
            f.write(art)
    print(f"wrote {len(SIGNS)} signs")


if __name__ == "__main__":
    main()
