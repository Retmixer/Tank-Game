/* Authored scenery built at metre scale, using bundled photographed PBR surfaces. */
(() => {
 'use strict';
 const T=THREE;
 function populate({world,arena,height,obstacles,obstacle,building}){
  const desert=arena===GameData.maps.desert,winter=arena===GameData.maps.winter,size=arena.size;
  const metal=Remaster.material(0x555b55,'steel'),wood=Remaster.material(0x77705a,'wood'),rubber=Remaster.material(0x262927,'rubber');
  const canvas=Remaster.material(desert?0x8f8156:0x746b46,'fabric'),sandbag=Remaster.material(desert?0xa99a6d:0x7c785d,'fabric');
  const glass=new T.MeshStandardMaterial({color:0x29424b,roughness:.27,metalness:.35});
  const cube=new T.BoxGeometry(1,1,1);
  function part(g,geometry,material,x,y,z){const mesh=new T.Mesh(geometry,material);mesh.position.set(x,y,z);mesh.castShadow=mesh.receiveShadow=true;g.add(mesh);return mesh;}
  function box(g,w,h,d,x,y,z,m=metal){const mesh=part(g,cube,m,x,y,z);mesh.scale.set(w,h,d);return mesh;}
  function cylinder(g,r,h,x,y,z,m=metal){return part(g,new T.CylinderGeometry(r,r,h,16),m,x,y,z);}
  function beam(g,a,b,r=.035,m=metal){const av=new T.Vector3(...a),bv=new T.Vector3(...b),delta=bv.clone().sub(av);const mesh=part(g,new T.CylinderGeometry(r,r,delta.length(),8),m,...av.clone().add(bv).multiplyScalar(.5).toArray());mesh.quaternion.setFromUnitVectors(new T.Vector3(0,1,0),delta.normalize());return mesh;}
  function site(x,z,w,d){
   // Keep spawn aprons, capture area and all three long driving lanes clear.
   if(Math.abs(x)<24||Math.abs(z)<23||Math.abs(Math.abs(x)-size*.31)<22||Math.hypot(x,z)<40)return null;
   for(const sign of [-1,1])if(Math.hypot(x-sign*size*.4,z-sign*size*.4)<54)return null;
   if(obstacles.some(o=>o.bounds?x+w/2+5>o.bounds.min.x&&x-w/2-5<o.bounds.max.x&&z+d/2+5>o.bounds.min.z&&z-d/2-5<o.bounds.max.z:Math.hypot(o.x-x,o.z-z)<o.r+Math.max(w,d)))return null;
   const levels=[];for(const sx of [-.5,0,.5])for(const sz of [-.5,0,.5])levels.push(height(x+sx*w,z+sz*d));
   const low=Math.min(...levels),high=Math.max(...levels);if(high-low>2)return null;
   const g=new T.Group();g.position.set(x,high,z);world.add(g);
   if(high-low>.25)box(g,w+.3,high-low+.2,d+.3,0,-(high-low+.2)/2,0,Remaster.material(0x716c5f,'rock'));
   return g;
  }
  function finish(g,w,d){Remaster.batch(g,[],true);obstacle(g,g.position.x,g.position.z,Math.hypot(w,d)/2,[w,d]);}
  function tent(x,z){const g=site(x,z,9,11);if(!g)return false;
   // Sloping fabric roof, separate entrance flaps, poles, seams and guy ropes.
   box(g,8,.15,10,0,.06,0,wood);box(g,.08,2,10,-4,1,0,canvas);box(g,.08,2,10,4,1,0,canvas);
   for(const sign of [-1,1]){const roof=box(g,4.48,.065,10,sign*2,3,0,canvas);roof.rotation.z=-sign*Math.atan2(2,4);box(g,2.9,2,.07,sign*2.55,1,5,canvas);beam(g,[sign*4,2,-4],[sign*4.45,0,-5],.025,wood);beam(g,[sign*4,2,4],[sign*4.45,0,5],.025,wood);}
   box(g,8,2,.08,0,1,-5,canvas);box(g,.09,4,.09,0,2,-5,wood);box(g,.09,4,.09,0,2,5,wood);beam(g,[0,4,-5],[0,4,5],.055,wood);
   for(const z0 of [-4.9,0,4.9])for(const sign of [-1,1])beam(g,[0,4.05,z0],[sign*4,2.05,z0],.023,wood);
   finish(g,9,11);return true;
  }
  function truck(x,z){const g=site(x,z,3.2,7.8);if(!g)return false;
   const paint=Remaster.material(desert?0x8d7658:0x566449,'paint');
   box(g,2.25,.28,6.8,0,.75,0);box(g,2.3,.24,4.1,0,1.45,-1.1,wood);
   box(g,2.05,1.7,1.65,0,1.9,1.7,paint);box(g,1.95,.7,1.3,0,1.4,3,paint);box(g,2.2,.12,1.85,0,2.83,1.7,paint);
   box(g,1.8,.64,.04,0,2.35,2.55,glass);box(g,.06,.64,1.05,-1.04,2.35,1.68,glass);box(g,.06,.64,1.05,1.04,2.35,1.68,glass);
   for(const side of [-1,1]){
    for(let row=0;row<4;row++)box(g,.12,.2,4.1,side*1.14,1.7+row*.27,-1.1,wood);
    for(const zz of [-3,-1.2,.7])box(g,.15,1.45,.13,side*1.2,2.06,zz,metal);
    for(const zz of [-2.5,-1.1,2.5]){const tyre=cylinder(g,.56,.34,side*1.2,.58,zz,rubber);tyre.rotation.z=Math.PI/2;const hub=cylinder(g,.3,.37,side*1.2,.58,zz,paint);hub.rotation.z=Math.PI/2;}
    const lamp=cylinder(g,.14,.1,side*.74,1.48,3.7,glass);lamp.rotation.x=Math.PI/2;
   }
   for(let row=0;row<4;row++)box(g,2.25,.2,.12,0,1.7+row*.27,-3.18,wood);
   box(g,2.55,.16,.2,0,.98,3.8);for(let i=-4;i<=4;i++)box(g,.075,.48,.06,i*.15,1.38,3.66);
   for(let j=0;j<3;j++)box(g,.85,.7,.8,(j%2)*1.05-.5,1.9,-2.2+j*.8,wood);
   finish(g,3.2,7.8);return true;
  }
  function barricade(x,z){const g=site(x,z,8,2.3);if(!g)return false;
   const sack=new T.SphereGeometry(1,10,6);
   for(let row=0;row<3;row++)for(let j=0;j<6-row;j++){const o=part(g,sack,sandbag,-3.15+j*1.25+row*.55,.24+row*.4,0);o.scale.set(.75,.28,.52);o.rotation.y=.1*(j%3-1);}
   for(const side of [-1,1])for(let j=0;j<2;j++){const b=cylinder(g,.36,.95,side*3.15,.48,.85+j*.2,metal);for(const y of [.14,.8]){const band=new T.Mesh(new T.TorusGeometry(.365,.018,6,16),metal);band.rotation.x=Math.PI/2;band.position.set(b.position.x,y,b.position.z);g.add(band);}}
   finish(g,8,2.3);return true;
  }
  function container(x,z){const g=site(x,z,3,9);if(!g)return false;const paint=Remaster.material((Math.round(x+z)%2)?0x704b3d:0x4d6770,'paint');
   box(g,2.7,2.7,8.3,0,1.4,0,paint);for(const side of [-1,1]){for(let j=0;j<23;j++)box(g,.07,2.5,.07,side*1.38,1.4,-3.9+j*.35,metal);box(g,.12,.12,8.5,side*1.38,2.8,0);box(g,.12,.12,8.5,side*1.38,.12,0);box(g,.06,2.3,.06,side*.68,1.4,4.2);}
   if(winter)box(g,2.9,.14,8.5,0,2.87,0,Remaster.material(0xe0e6e9,'winter'));
   finish(g,3,9);return true;
  }
  function gantry(x,z){const g=site(x,z,19,5);if(!g)return false;const steel=Remaster.material(0x887143,'steel');
   for(const s of [-1,1]){box(g,1.2,16,1.2,s*8,8,0,steel);box(g,3,.7,4,s*8,.3,0);beam(g,[s*8,11,0],[s*4,15.5,0],.18,steel);}
   box(g,18,1.4,1.3,0,16,0,steel);box(g,2.4,1,2.2,-2,14.8,0);beam(g,[-2,14.5,0],[-2,9,0],.045);const hook=part(g,new T.TorusGeometry(.44,.1,8,18,Math.PI*1.5),metal,-2,8.7,0);
   // Only the supports collide: vehicles can drive under the gantry.
   Remaster.batch(g,[],true);for(const s of [-1,1]){const collider=new T.Group();collider.position.set(x+s*8,g.position.y,z);world.add(collider);obstacle(collider,x+s*8,z,2,[3,4]);}
   return true;
  }
  let count=0;
  for(const side of [-1,1])for(const flank of [-1,1]){
   const x=flank*size*.23,z=side*size*.30;
   const placements=winter?[[container,x,z],[truck,x+flank*13,z],[gantry,x,z-side*32],[container,x+flank*16,z-side*24]]:[[tent,x,z],[truck,x+flank*14,z],[barricade,x,z-side*15],[tent,x,z-side*34],[truck,x+flank*14,z-side*34]];
   for(const [fn,px,pz] of placements)if(fn(px,pz))count++;
  }
  // Secondary supply stops fill the flanks without placing props on roads.
  for(const side of [-1,1])for(const z of [-.22,-.12,.12,.22]){if((winter?container:truck)(side*size*.37,z*size))count++;}
  if(!desert&&!winter)for(const side of [-1,1])for(const flank of [-1,1]){const x=flank*size*.17,z=side*size*.22,g=site(x,z,14,18);if(g){building(x,z,14,18,6,false);count++;}}
  if(desert)for(const side of [-1,1])for(let j=0;j<6;j++){
   const x=side*size*(.24+j*.022),z=(j-2.5)*size*.1,g=site(x,z,4,4);if(!g)continue;
   const h=8+(j%3);cylinder(g,.28,h,0,h/2,0,wood);
   const leaf=Remaster.material(0x768043,'leaf');leaf.side=T.DoubleSide;
   for(let a=0;a<9;a++){
    const positions=[],uv=[],angle=a*Math.PI*2/9;
    for(let k=0;k<7;k++){const t=k/6,r=t*4.5,y=h+Math.sin(t*Math.PI)*1.2-t*1.7,width=Math.sin(t*Math.PI)*.48;for(const s of [-1,1]){positions.push(Math.sin(angle)*r+Math.cos(angle)*s*width,y,Math.cos(angle)*r-Math.sin(angle)*s*width);uv.push(t,s===1?1:0);}}
    const geo=new T.BufferGeometry();geo.setAttribute('position',new T.Float32BufferAttribute(positions,3));geo.setAttribute('uv',new T.Float32BufferAttribute(uv,2));const indices=[];for(let k=0;k<6;k++){const i=k*2;indices.push(i,i+1,i+2,i+1,i+3,i+2);}geo.setIndex(indices);geo.computeVertexNormals();part(g,geo,leaf,0,0,0);
   }
   finish(g,.7,.7);count++;
  }
  if(winter)for(const side of [-1,1])for(const z of [-size*.26,-size*.13,size*.13,size*.26]){
   const x=side*24,g=site(x,z,1,1);if(!g)continue;cylinder(g,.11,7,0,3.5,0);box(g,2,.12,.12,side*.9,7,0);
   const glow=new T.MeshStandardMaterial({color:0xffdd92,emissive:0xffba59,emissiveIntensity:2});box(g,.8,.12,.5,side*1.6,6.9,0,glow);finish(g,.4,.4);
  }
  world.userData.dressingSites=count;
 }
 window.MapDressing={populate};
})();
