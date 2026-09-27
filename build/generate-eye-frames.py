"""Emit the reviewed native 1.02 eye table. No game or release files are touched."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
data = json.loads((root / "build/fixtures/eye-frame-calibration.json").read_text("utf-8"))
compact = lambda value: json.dumps(value, ensure_ascii=True, separators=(",", ":"))
rows = ["         " + compact(key) + ":" + compact(value)
        for key, value in data["coordinates"].items()]
source = '''package
{
   /** Native 1.02 displayed-frame calibration; regenerate with build/generate-eye-frames.py. */
   public class MSWEyeFrames
   {
      private static const coordinates:Object={
ROWS
      };
      private static const offsets:Object=OFFSETS;
      public static function known(p:Object):Boolean {return p!=null && coordinates[p.sprite]!=null && coordinates[p.sprite][p.id]!=null && p.frame>=0 && p.frame*2<coordinates[p.sprite][p.id].length;}
      public static function point(p:Object):Array {if(!known(p))return null;var row:Array=coordinates[p.sprite][p.id],i:int=p.frame*2;return row[i]==null?null:[row[i],row[i+1]];}
      public static function available(p:Object):Boolean {return !known(p) || coordinates[p.sprite][p.id][p.frame*2]!=null;}
      public static function headOffset(sprite:String):Array {return offsets[sprite];}
   }
}
'''
source = source.replace("ROWS", ",\n".join(rows)).replace("OFFSETS", compact(data["headOffsets"]))
(root / "src/MSWEyeFrames.as").write_text(source, encoding="utf-8")
print(f"Generated {len(rows)} sprite tables and {len(data['headOffsets'])} head offsets")
