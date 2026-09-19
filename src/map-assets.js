/* Locally bundled Kenney models, CC0. See assets/CREDITS.md. */
(() => {
 const T=THREE;
 const texture=new T.TextureLoader().load('assets/models/industrial-colormap.png');texture.colorSpace=T.SRGBColorSpace;texture.magFilter=T.NearestFilter;
 function create(name,w,h,d){
  const data=window.KenneyModels?.[name];if(!data)return null;
  const group=new T.Group();group.userData.asset=name;
  for(const part of data){
   const geometry=new T.BufferGeometry();geometry.setAttribute('position',new T.Float32BufferAttribute(part.positions,3));geometry.setAttribute('normal',new T.Float32BufferAttribute(part.normals,3));geometry.setAttribute('uv',new T.Float32BufferAttribute(part.uvs,2));
   const color=new T.Color().setRGB(...part.color,T.SRGBColorSpace);
   if(name.startsWith('tree'))color.set(part.color[1]>part.color[0]?0x526b3b:0x635441);
   const colors=[];for(let i=0;i<part.positions.length/3;i++)colors.push(color.r,color.g,color.b);
   geometry.setAttribute('color',new T.Float32BufferAttribute(colors,3));
   // Vertex colors also keep the map's legacy mesh batching from discarding UVs.
   const material=new T.MeshStandardMaterial({color:0xffffff,vertexColors:true,map:part.texture?texture:null,roughness:.86,metalness:part.texture?.12:0});
   const mesh=new T.Mesh(geometry,material);mesh.castShadow=true;mesh.receiveShadow=true;group.add(mesh);
  }
  const bounds=new T.Box3().setFromObject(group),size=bounds.getSize(new T.Vector3()),center=bounds.getCenter(new T.Vector3());
  for(const child of group.children)child.geometry.translate(-center.x,-bounds.min.y,-center.z);
  group.scale.set(w/size.x,h/size.y,d/size.z);return group;
 }
 window.MapAssets={create};
})();
