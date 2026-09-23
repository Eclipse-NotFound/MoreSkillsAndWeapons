package
{
   import flash.utils.Dictionary;

   /** Independent lock clocks, stable acquisition order, and per-projectile rotation. */
   public class MSWSmartMultiLock
   {
      private var entries:Array=[];
      private var byUnit:Dictionary=new Dictionary(true);
      private var cursor:int=0;
      public function MSWSmartMultiLock() {}

      public function clear():void
      { entries=[];byUnit=new Dictionary(true);cursor=0; }

      public function stateFor(unit:*):MSWSmartLock
      { return byUnit[unit] as MSWSmartLock; }

      public function get locks():Array
      {
         var result:Array=[];
         for each(var entry:Object in entries) result.push(entry.lock);
         return result;
      }

      public function advance(allowedUnits:Array,visibleUnits:Array,dt:Number,c:*):void
      {
         var allowed:Dictionary=new Dictionary(true),seen:Dictionary=new Dictionary(true);
         for each(var unit:* in allowedUnits) allowed[unit]=true;
         for each(unit in visibleUnits)
         {
            if(!allowed[unit]) continue;
            seen[unit]=true;
            if(byUnit[unit]==null)
            {
               var state:MSWSmartLock=new MSWSmartLock();
               byUnit[unit]=state;entries.push({unit:unit,lock:state});
            }
         }
         for(var i:int=entries.length-1;i>=0;i--)
         {
            var entry:Object=entries[i];unit=entry.unit;state=entry.lock;
            if(allowed[unit]) state.advance(seen[unit]?unit:null,Boolean(seen[unit]),dt,c);
            if(!allowed[unit] || state.target==null && state.candidate==null)
            {
               delete byUnit[unit];entries.splice(i,1);
               // Removing earlier entries must not skip the next waiting target.
               if(i<cursor) cursor--;
            }
         }
         if(cursor>=entries.length) cursor=0;
      }

      public function pick(valid:Function=null):MSWSmartLock
      {
         for(var offset:int=0;offset<entries.length;offset++)
         {
            var index:int=(cursor+offset)%entries.length;
            var state:MSWSmartLock=entries[index].lock;
            if(state.target!=null && state.strength>0 && (valid==null || valid(state.target)))
            {
               cursor=(index+1)%entries.length;
               return state;
            }
         }
         return null;
      }
   }
}
