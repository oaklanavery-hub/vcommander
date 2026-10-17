#!/usr/bin/env python3
"""Author original replaceable 32x48 pixel Commander portraits as native catalog data."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMON = {'o':'30291f','s':'e8bc8d','h':'bc805c','w':'f7eac6','e':'25352e','k':'66513b','g':'d9b765','b':'42382c'}
THEMES = {
    'fire': {'a':'a94836','c':'e88a45','l':'f6c66a','d':'673e35'},
    'water': {'a':'42748c','c':'77b8c1','l':'d3ece2','d':'324958'},
    'earth': {'a':'4f7142','c':'8ca565','l':'d2d18d','d':'344b35'}
}


def portrait(element):
    cells = [['.'] * 32 for _ in range(48)]
    def rect(x,y,w,h,color):
        for yy in range(max(0,y),min(48,y+h)):
            for xx in range(max(0,x),min(32,x+w)):
                cells[yy][xx]=color
    # Cloak, boots and little gloved hands.
    rect(9,24,16,17,'o');rect(8,28,18,10,'o');rect(10,25,14,14,'d')
    rect(10,28,5,12,'a');rect(19,28,5,12,'a');rect(14,27,6,12,'c')
    rect(13,39,4,5,'o');rect(19,39,4,5,'o');rect(12,43,5,3,'o');rect(19,43,6,3,'o')
    rect(13,40,3,3,'b');rect(20,40,2,3,'b');rect(11,44,6,2,'k');rect(19,44,6,2,'k')
    rect(8,28,3,7,'o');rect(8,29,2,4,'s');rect(24,28,3,6,'o');rect(25,29,2,3,'s')
    rect(13,36,9,2,'k');rect(16,36,3,2,'g');rect(17,36,1,1,'l')
    # Chibi head, hair, face and cloak clasp.
    rect(10,9,14,16,'o');rect(8,12,18,10,'o');rect(10,11,14,12,'k')
    rect(11,14,12,9,'s');rect(12,22,10,2,'h');rect(10,13,4,5,'k');rect(12,11,11,4,'k')
    rect(12,14,2,2,'b');rect(14,13,2,2,'b');rect(21,14,3,4,'k')
    rect(13,18,2,2,'e');rect(20,18,2,2,'e');rect(13,18,1,1,'w');rect(20,18,1,1,'w')
    rect(12,21,2,1,'h');rect(22,21,1,1,'h');rect(17,22,2,1,'h')
    rect(15,24,5,3,'w');rect(17,26,2,2,'g')
    # Themed headwear and an ornamental staff are presentation only.
    rect(9,9,17,3,'o');rect(10,9,15,2,'a');rect(11,8,13,1,'g')
    rect(26,15,2,29,'o');rect(26,16,1,27,'k');rect(25,28,4,1,'g')
    if element=='fire':
        rect(13,5,9,4,'o');rect(14,5,7,3,'a');rect(17,2,2,4,'g');rect(16,6,4,2,'l')
        rect(25,9,5,7,'o');rect(26,7,2,8,'c');rect(27,5,1,8,'l');rect(25,12,4,3,'g')
    elif element=='water':
        rect(12,6,11,3,'o');rect(13,6,9,2,'c');rect(16,3,3,4,'l');rect(15,5,5,2,'c')
        rect(25,7,5,8,'o');rect(26,6,3,9,'c');rect(27,5,1,8,'l');rect(26,10,1,3,'w')
    else:
        rect(11,6,13,3,'o');rect(12,6,11,2,'a');rect(15,3,6,3,'a');rect(17,2,2,4,'c')
        rect(24,8,6,7,'o');rect(25,9,5,5,'a');rect(26,7,3,6,'c');rect(27,9,1,5,'l')
        rect(11,30,2,6,'c');rect(22,31,2,5,'c')
    return [''.join(row) for row in cells]


if __name__ == '__main__':
    catalog={'schema_version':1,'width':32,'height':48,'colors':COMMON,'palettes':THEMES,
             'sprites':{element:{'pixels':portrait(element)} for element in THEMES}}
    (ROOT/'assets/pixel/commanders.json').write_text(json.dumps(catalog,indent=2)+'\n')
    print('Authored three original 32x48 Commander portraits.')
