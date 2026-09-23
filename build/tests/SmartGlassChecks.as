package
{
   public class SmartGlassChecks
   {
      public static function run(ok:Function):void
      {
         var t:Object={phis:1,phX1:90,phX2:130,phY1:40,phY2:120,indestruct:false,thre:0,hp:10,mat:5,
            door:{id:"window1",dead:false,inter:null}};
         var air:Object={phis:0};
         var loc:Object={destroyOn:true,getAbsTile:function(x:Number,y:Number):*{return x>=90 && x<=130 && y>=40 && y<=120?t:air;}};
         var b:Object={X:80,Y:80,dx:20,dy:0,vel:20,destroy:10,tipDecal:0,explRadius:0,loc:loc};
         ok(MSWSmartGlass.visible(loc,0,80,210,80),"normal window is optically transparent");
         ok(!MSWSmartRoute.clear(loc,0,80,210,80),"physical query without a shot still blocks normal glass");
         ok(MSWSmartRoute.find(loc,0,80,210,80,b).length==1,"breakable normal window takes the shorter direct route");
         MSWSmartRoute.steer(b,210,80,0.5,loc);
         ok(b.dx==20 && b.dy==0,"near-window steering does not evade chosen glass");
         var s:Object={smoothing:100,remaining:2};
         MSWSmartSmooth.steer(b,s,[{x:210,y:80}],0.1,0.2,0.5);
         ok(b.dy==0 && s.smoothUrgent==null,"smooth forecast does not evade chosen glass");
         b.destroy=0;
         ok(MSWSmartRoute.find(loc,0,80,210,80,b).length>1,"zero terrain damage must take the open detour");
         b.destroy=0.9;ok(!MSWSmartGlass.breakable(loc,t,b),"native integer damage cannot round fractional damage up");
         b.destroy=5;ok(MSWSmartGlass.breakable(loc,t,b),"multiple shots may damage a normal window");
         var key:String=MSWSmartGlass.routeKey(b);b.destroy=10;
         ok(MSWSmartGlass.routeKey(b)!=key,"different ammunition capabilities partition shared routes");
         t.thre=11;ok(!MSWSmartGlass.breakable(loc,t,b),"native destruction threshold blocks a weak round");
         t.thre=10;ok(MSWSmartGlass.breakable(loc,t,b),"threshold equality can damage glass");
         b.tipDecal=100;ok(!MSWSmartGlass.breakable(loc,t,b),"native special terrain decal restriction retained");
         b.tipDecal=0;t.thre=0;t.indestruct=true;
         ok(!MSWSmartGlass.breakable(loc,t,b) && MSWSmartGlass.visible(loc,0,80,210,80),"indestructible glass still allows sight but not a break route");
         t.indestruct=false;t.hp=10000;t.thre=10000;
         ok(!MSWSmartGlass.breakable(loc,t,b),"native instance indestructibility threshold retained");
         t.thre=0;t.hp=600;loc.destroyOn=false;
         ok(!MSWSmartGlass.breakable(loc,t,b),"map destruction protection retained");
         t.hp=500;ok(MSWSmartGlass.breakable(loc,t,b),"map hp boundary matches native rule");
         loc.destroyOn=true;t.hp=10;t.door.inter={prize:true};
         ok(!MSWSmartGlass.breakable(loc,t,b),"protected prize door cannot become an opening");t.door.inter=null;
         b.explRadius=80;ok(MSWSmartGlass.breakable(loc,t,b),"native wide explosive shot may plan normal glass");
         b.explRadius=40;ok(MSWSmartGlass.breakable(loc,t,b),"one-tile blast covers every impact-to-centre distance");
         b.explRadius=10;ok(!MSWSmartGlass.breakable(loc,t,b),"tiny explosion cannot promise tile-centre damage");b.explRadius=0;
         t.door.id="window2";b.destroy=10000;
         ok(MSWSmartGlass.visible(loc,0,80,210,80),"armored glass allows optical lock");
         ok(!MSWSmartGlass.breakable(loc,t,b) && MSWSmartRoute.find(loc,0,80,210,80,b).length>1,"intact armored glass stays blocked even for a powerful round");
         t.phis=0;t.door.dead=true;
         ok(MSWSmartRoute.find(loc,0,80,210,80,b).length==1,"broken armor opens despite retained door identity");
         t.phis=1;t.door.id="door1";t.door.dead=false;
         ok(!MSWSmartGlass.visible(loc,0,80,210,80) && !MSWSmartGlass.breakable(loc,t,b),"wooden doors and glass material alone are not windows");
         t.door=null;t.mat=3;
         ok(!MSWSmartGlass.visible(loc,0,80,210,80),"F material debris still blocks sight");
         t.door={id:"window1",dead:false,inter:null};
         var wall:Object={phis:1,phX1:160,phX2:180,phY1:0,phY2:160};
         loc.getAbsTile=function(x:Number,y:Number):*{return x>=160 && x<=180 && y>=0 && y<=160?wall:x>=90 && x<=130 && y>=40 && y<=120?t:air;};
         ok(!MSWSmartGlass.visible(loc,0,80,210,80),"real wall behind transparent glass still blocks sight");
         ok(!MSWSmartRoute.clear(loc,0,80,210,80,2,b),"real wall behind breakable glass still blocks the route");
      }
   }
}
